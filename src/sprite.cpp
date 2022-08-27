#include <cstdio>

#include <array>
#include <exception>
#include <fstream>
#include <sstream>
#include <unordered_map>
#include <utility>

#include "MeiMei/MeiMei.h"
#include "argparser.h"
#include "asar/asardll.h"
#include "cfg.h"
#include "config.h"
#include "file_io.h"
#include "iohandler.h"
#include "json.h"
#include "libconsole/libconsole.h"
#include "lmdata.h"
#include "map16.h"
#include "paths.h"

#ifdef ON_WINDOWS
#include <windows.h>
#endif

#define STRIMPL(x) #x
#define STR(x) STRIMPL(x)

// change these values from the CMakeLists, not here, changes will propagate.
constexpr unsigned char VERSION_EDITION = PIXI_VERSION_EDITION;
constexpr unsigned char VERSION_MAJOR = PIXI_VERSION_MAJOR;
constexpr unsigned char VERSION_MINOR = PIXI_VERSION_MINOR;
constexpr const char VERSION_DEBUG[] = STR(PIXI_VERSION_DEBUG);
constexpr unsigned char VERSION_PARTIAL = VERSION_MAJOR * 10 + VERSION_MINOR;
constexpr unsigned char VERSION_FULL = VERSION_EDITION * 100 + VERSION_MAJOR * 10 + VERSION_MINOR;
static_assert(VERSION_FULL <= std::numeric_limits<unsigned char>::max());

constexpr auto INIT_PTR = 0x01817D; // snes address of default init pointers
constexpr auto MAIN_PTR = 0x0185CC; // guess what?

constexpr auto TEMP_SPR_FILE = "spr_temp.asm";
constexpr size_t SPRITE_COUNT = 0x80; // count for other sprites like cluster, ow, extended
constexpr size_t LESS_SPRITE_COUNT = 0x3F;
constexpr size_t MINOR_SPRITE_COUNT = 0x1F;

constexpr std::array<std::pair<ListType, size_t>, FromEnum(ListType::__SIZE__) - 1ull> sprite_sizes = {
    {{ListType::Extended, SPRITE_COUNT},
     {ListType::Cluster, SPRITE_COUNT},
     {ListType::MinorExtended, LESS_SPRITE_COUNT},
     {ListType::Bounce, LESS_SPRITE_COUNT},
     {ListType::Smoke, LESS_SPRITE_COUNT},
     {ListType::SpinningCoin, MINOR_SPRITE_COUNT},
     {ListType::Score, MINOR_SPRITE_COUNT}}};

unsigned char PLS_LEVEL_PTRS[0x400];
unsigned char PLS_SPRITE_PTRS[0x4000];
int PLS_SPRITE_PTRS_ADDR = 0;
unsigned char PLS_DATA[0x8000];
unsigned char PLS_POINTERS[0x8000];
// index into both PLS_DATA and PLS_POINTERS
int PLS_DATA_ADDR = 0;

std::vector<std::string> warnings{};
PixiConfig cfg{};
iohandler& io = iohandler::get_global();
std::vector<memoryfile> g_memory_files{};
patchfile g_shared_patch{"shared.asm"};
std::vector<definedata> g_config_defines{};

struct addtempfile {
    addtempfile(const patchfile& file) {
        g_memory_files.push_back(file.vfile());
    }
    ~addtempfile() {
        g_memory_files.pop_back();
    }
};

void double_click_exit() {
    io.getc(); // Pause before exit
}

template <typename T, size_t N> constexpr size_t array_size(T (&)[N]) {
    return N;
}

void clean_sprite_generic(patchfile& clean_patch, int table_address, int original_value, size_t count,
                          const char* preface, ROM& rom) {
    clean_patch.fprintf("%s", preface);
    int table = rom.pointer_snes(table_address).addr();
    if (table != original_value) // check with default/uninserted address
        for (size_t i = 0; i < count; i++) {
            pointer pointer = rom.pointer_snes(table + 3 * static_cast<int>(i));
            if (!pointer.is_empty())
                clean_patch.fprintf("autoclean $%06X\n", pointer.addr());
        }
}

template <size_t COUNT> [[nodiscard]] patchfile write_sprite_generic(sprite (&list)[COUNT], const char* filename) {
    unsigned char file[COUNT * 3]{};
    for (size_t i = 0; i < COUNT; i++)
        memcpy(file + (i * 3), &list[i].table.main, 3);
    return write_all(file, cfg[PathType::Asm], filename, COUNT * 3);
}

template <typename T> T* from_table(T* table, int level, int number) {
    if (!cfg.PerLevel)
        return table + number;

    if (level > 0x200 || number > 0xFF)
        return nullptr;
    if (level == 0x200)
        return table + (0x2000 + number);
    else if (number >= 0xB0 && number < 0xC0)
        return table + ((level * 0x10) + (number - 0xB0));
    return nullptr;
}

[[nodiscard]] bool patch(const patchfile& file, ROM& rom) {
    // clang-format off
    constexpr struct warnsetting disabled_warnings[] {
        {.warnid = "W1001", .enabled = false},
        {.warnid = "W1005", .enabled = false}
    };
    addtempfile tmp{file};
    const int memfiles_size = static_cast<int>(g_memory_files.size());
    struct patchparams params {
        .structsize = sizeof(struct patchparams), 
        .patchloc = file.path().c_str(),
        .romdata = reinterpret_cast<char*>(rom.real_data),
        .buflen = MAX_ROM_SIZE,
        .romlen = &rom.size, 
        .includepaths = nullptr,
        .numincludepaths = 0,
        .should_reset = true,
        .additional_defines = g_config_defines.data(), 
        .additional_define_count = static_cast<int>(g_config_defines.size()),
        .stdincludesfile = nullptr,
        .stddefinesfile = nullptr,
        .warning_settings = disabled_warnings,
        .warning_setting_count = static_cast<int>(array_size(disabled_warnings)),
        .memory_files = g_memory_files.data(),
        .memory_file_count = memfiles_size,
        .override_checksum_gen = false,
        .generate_checksum = true
    };
    // clang-format on
    if (!asar_patch_ex(&params)) {
        int error_count;
        const errordata* errors = asar_geterrors(&error_count);
        io.error("An error has been detected while applying patch %s:\n", file.path().c_str());
        for (int i = 0; i < error_count; i++)
            io.error("%s\n", errors[i].fullerrdata);
        return false;
    }
    int warn_count = 0;
    const errordata* loc_warnings = asar_getwarnings(&warn_count);
    for (int i = 0; i < warn_count; i++)
        warnings.emplace_back(loc_warnings[i].fullerrdata);
    return true;
}

[[nodiscard]] bool patch(const char* patch_name_rel, ROM& rom) {
    std::string patch_path{patch_name_rel}; //  = std::filesystem::absolute(patch_name_rel).generic_string();
    // clang-format off
    constexpr warnsetting disabled_warnings[] {
        {.warnid = "W1001", .enabled = false},
        {.warnid = "W1005", .enabled = false}
    };
    patchparams params {
        .structsize = sizeof(patchparams), 
        .patchloc = patch_path.c_str(),
        .romdata = reinterpret_cast<char*>(rom.real_data),
        .buflen = MAX_ROM_SIZE,
        .romlen = &rom.size, 
        .includepaths = nullptr,
        .numincludepaths = 0,
        .should_reset = true,
        .additional_defines = g_config_defines.data(), 
        .additional_define_count = static_cast<int>(g_config_defines.size()),
        .stdincludesfile = nullptr,
        .stddefinesfile = nullptr,
        .warning_settings = disabled_warnings,
        .warning_setting_count = static_cast<int>(array_size(disabled_warnings)),
        .memory_files = g_memory_files.data(),
        .memory_file_count = static_cast<int>(g_memory_files.size()),
        .override_checksum_gen = false,
        .generate_checksum = true
    };
    // clang-format on
    if (!asar_patch_ex(&params)) {
        int error_count;
        const errordata* errors = asar_geterrors(&error_count);
        io.error("An error has been detected while applying patch %s:\n", patch_path.c_str());
        for (int i = 0; i < error_count; i++)
            io.error("%s\n", errors[i].fullerrdata);
        return false;
    }
    int warn_count = 0;
    const errordata* loc_warnings = asar_getwarnings(&warn_count);
    for (int i = 0; i < warn_count; i++)
        warnings.emplace_back(loc_warnings[i].fullerrdata);
    return true;
}

[[nodiscard]] bool patch(std::string_view dir, const char* patch_name, ROM& rom) {
    char* path = new char[dir.length() + strlen(patch_name) + 1];
    path[0] = 0;
    strcat(path, dir.data());
    strcat(path, patch_name);
    bool ret = patch(path, rom);
    delete[] path;
    return ret;
}

void addIncScrToFile(patchfile& file, const std::vector<std::string>& toInclude) {
    for (std::string const& incPath : toInclude) {
        file.fprintf("incsrc \"%s\"\n", incPath.c_str());
    }
}

constexpr bool ends_with(const char* str, const char* suffix) {
    if (str == nullptr || suffix == nullptr)
        return false;
    std::string_view strv{str};
    std::string_view suffixv{str};
    return strv.ends_with(suffixv);
}

[[nodiscard]] bool create_lm_restore(const char* rom) {
    char to_write[50];
    sprintf(to_write, "Pixi v%d.%d\t", VERSION_EDITION, VERSION_PARTIAL);
    std::string romname(rom);
    std::string restorename = romname.substr(0, romname.find_last_of('.')) + ".extmod";

    FILE* res = open(restorename.c_str(), "a+");
    if (res) {
        size_t size = file_size(res);
        char* contents = new char[size + 1];
        size_t read_size = fread(contents, 1, size, res);
        if (size != read_size) {
            io.error("Couldn't fully read file %s, please check file permissions", restorename.c_str());
            return false;
        }
        contents[size] = '\0';
        if (!ends_with(contents, to_write)) {
            fseek(res, 0, SEEK_END);
            fprintf(res, "%s", to_write);
        }
        fclose(res);
        delete[] contents;
        return true;
    } else {
        io.error("Couldn't open restore file for writing (%s)\n", restorename.c_str());
        return false;
    }
}

std::string escapeDefines(std::string_view path, const char* repl = "\\!") {
    std::stringstream ss("");
    for (char c : path) {
        if (c == '!') {
            ss << repl;
        } else {
            ss << c;
        }
    }
    return ss.str();
}

static bool strccmp(std::string_view first, std::string_view second) {
    if (first.size() != second.size())
        return false;
    for (size_t i = 0; i < first.size(); i++) {
        if (std::tolower(first[i]) != std::tolower(second[i]))
            return false;
    }
    return true;
}

[[nodiscard]] bool patch_sprite(const std::vector<std::string>& extraDefines, sprite* spr, ROM& rom) {
    std::string escapedDir = escapeDefines(spr->directory);
    std::string escapedAsmfile = escapeDefines(spr->asm_file);
    std::string escapedAsmdir = escapeDefines(cfg.AsmDir);
    patchfile sprite_patch{TEMP_SPR_FILE};
    sprite_patch.fprintf("namespace nested on\n");
    sprite_patch.fprintf("warnings push\n");
    sprite_patch.fprintf("warnings disable w1005\n");
    sprite_patch.fprintf("warnings disable w1001\n");
    sprite_patch.fprintf("incsrc \"%ssa1def.asm\"\n", escapedAsmdir.c_str());
    addIncScrToFile(sprite_patch, extraDefines);
    sprite_patch.fprintf("incsrc \"shared.asm\"\n");
    sprite_patch.fprintf("incsrc \"%s_header.asm\"\n", escapedDir.c_str());
    sprite_patch.fprintf("freecode cleaned\n");
    sprite_patch.fprintf("SPRITE_ENTRY_%d:\n", spr->number);
    sprite_patch.fprintf("\tincsrc \"%s\"\n", escapedAsmfile.c_str());
    sprite_patch.fprintf("warnings pull\n");
    sprite_patch.fprintf("namespace nested off\n");
    sprite_patch.close();

    if (!patch(sprite_patch, rom))
        return false;
    using ptr_map_t = std::unordered_map<std::string_view, pointer>;
    using ptr_map_v_t = ptr_map_t::value_type;
    ptr_map_t ptr_map = {
        ptr_map_v_t{"INIT", 0x018021},    ptr_map_v_t{"MAIN", 0x018021},   ptr_map_v_t{"CAPE", 0x000000},
        ptr_map_v_t{"MOUTH", 0x000000},   ptr_map_v_t{"KICKED", 0x000000}, ptr_map_v_t{"CARRIABLE", 0x000000},
        ptr_map_v_t{"CARRIED", 0x000000}, ptr_map_v_t{"GOAL", 0x000000},   ptr_map_v_t{"VERG", 0x000000}};
    int print_count = 0;
    int label_count = 0;
    const char* const* asar_prints = asar_getprints(&print_count);
    const labeldata* asar_labels = asar_getalllabels(&label_count);
    std::vector<std::string> prints{};
    std::vector<labeldata> labels{};
    prints.reserve(print_count);
    labels.reserve(label_count);

    for (int i = 0; i < print_count; i++) { // trim prints since now we can't deal with starting spaces
        trim(prints.emplace_back(asar_prints[i]));
    }
    for (int i = 0; i < label_count; i++) {
        labels.push_back(asar_labels[i]);
    }

    io.debug("%s\n", spr->asm_file);
    if (print_count > 2)
        io.debug("Prints:\n");

    using namespace std::string_view_literals;

    struct PointerChecker {
        const std::string_view name;
        bool (*check)(ListType);
        bool operator()(ListType tp, std::string_view str) const noexcept {
            return check(tp) && strccmp(name, str.substr(0, name.size()));
        }
    };

    auto always_true = [](ListType) { return true; };
    auto normal_only = [](ListType tp) { return tp == ListType::Sprite; };
    auto extended_only = [](ListType tp) { return tp == ListType::Extended; };

    // clang-format off
    std::array valid_pointer_names{
        PointerChecker{"INIT"sv, always_true},
        PointerChecker{"MAIN"sv, always_true},
        PointerChecker{"CAPE"sv, extended_only},  
        PointerChecker{"CARRIABLE"sv, normal_only},
        PointerChecker{"CARRIED"sv, normal_only}, 
        PointerChecker{"KICKED"sv, normal_only},
        PointerChecker{"MOUTH"sv, normal_only},   
        PointerChecker{"GOAL"sv, normal_only},
        PointerChecker{"VERG"sv, always_true},
    };
    // clang-format on

    for (int i = 0; i < print_count; i++) {
        auto it = std::find_if(valid_pointer_names.begin(), valid_pointer_names.end(),
                               [&](const PointerChecker& chk) { return chk(spr->sprite_type, prints[i]); });
        if (it != valid_pointer_names.end()) {
            const auto& ch = *it;
            if (ch.name == "VERG"sv) {
                // if the user has put $ to indicate the hex number we skip it
                // we always parse the version as a decimal
                auto required_version = std::atoi(prints[i].c_str() + (prints[i][4] == '$' ? 5 : 4));
                if (VERSION_PARTIAL < required_version) {
                    io.error("The sprite %s requires to be inserted at least with Pixi 1.%d, this is Pixi 1.%d\n",
                             spr->asm_file, required_version, VERSION_PARTIAL);
                    return false;
                }
            } else {
                ptr_map[ch.name] = strtol(prints[i].c_str() + ch.name.size(), nullptr, 16);
            }

        } else {
            io.debug("\t%s\n", prints[i].c_str());
        }
    }

    for (const auto& chk : valid_pointer_names) {
        const auto it = ptr_map.find(chk.name);
        assert(it != ptr_map.end());
        const auto& [_, ptr] = *it;
        if (ptr.is_empty() || ptr.addr() == 0x018021) {
            auto found = std::find_if(labels.begin(), labels.end(),
                                      [&](const labeldata& data) { return chk(spr->sprite_type, data.name); });
            if (found != labels.end()) {
                io.debug("\tDidn't find print for pointer %s, but found label %s (at addr $%06X), using it\n",
                         chk.name.data(), found->name, found->location);
                ptr_map[chk.name] = found->location;
            }
        }
    }

    spr->table.init = ptr_map["INIT"];
    spr->table.main = ptr_map["MAIN"];
    if (spr->table.init.is_empty() && spr->table.main.is_empty()) {
        io.error("Sprite %s had neither INIT nor MAIN defined in its file, insertion has been aborted.", spr->asm_file);
        return false;
    }
    if (spr->sprite_type == ListType::Extended) {
        spr->extended_cape_ptr = ptr_map["CAPE"];
    } else if (spr->sprite_type == ListType::Sprite) {
        spr->ptrs.carried = ptr_map["CARRIED"];
        spr->ptrs.carriable = ptr_map["CARRIABLE"];
        spr->ptrs.kicked = ptr_map["KICKED"];
        spr->ptrs.mouth = ptr_map["MOUTH"];
        spr->ptrs.goal = ptr_map["GOAL"];
    }
    if (spr->sprite_type == ListType::Sprite)
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n"
                 "\tCARRIABLE: $%06X\n\tCARRIED: $%06X\n\tKICKED: $%06X\n"
                 "\tMOUTH: $%06X\n\tGOAL: $%06X"
                 "\n__________________________________\n",
                 spr->table.init.addr(), spr->table.main.addr(), spr->ptrs.carriable.addr(), spr->ptrs.carried.addr(),
                 spr->ptrs.kicked.addr(), spr->ptrs.mouth.addr(), spr->ptrs.goal.addr());
    else if (spr->sprite_type == ListType::Extended)
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n\tCAPE: $%06X"
                 "\n__________________________________\n",
                 spr->table.init.addr(), spr->table.main.addr(), spr->extended_cape_ptr.addr());
    else
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n"
                 "\n__________________________________\n",
                 spr->table.init.addr(), spr->table.main.addr());
    return true;
}

[[nodiscard]] bool patch_sprites(std::vector<std::string>& extraDefines, sprite* sprite_list, int size, ROM& rom) {
    for (int i = 0; i < size; i++) {
        sprite* spr = sprite_list + i;
        if (!spr->asm_file)
            continue;

        bool duplicate = false;
        for (int j = i - 1; j >= 0; j--) {
            if (sprite_list[j].asm_file) {
                if (!strcmp(spr->asm_file, sprite_list[j].asm_file)) {
                    spr->table.init = sprite_list[j].table.init;
                    spr->table.main = sprite_list[j].table.main;
                    spr->extended_cape_ptr = sprite_list[j].extended_cape_ptr;
                    spr->ptrs = sprite_list[j].ptrs;
                    duplicate = true;
                    break;
                }
            }
        }

        if (!duplicate) {
            if (!patch_sprite(extraDefines, spr, rom))
                return false;
        }

        if (spr->level < 0x200 && spr->number >= 0xB0 && spr->number < 0xC0) {
            int pls_lv_addr = PLS_LEVEL_PTRS[spr->level * 2] + (PLS_LEVEL_PTRS[spr->level * 2 + 1] << 8);
            if (pls_lv_addr == 0x0000) {
                pls_lv_addr = PLS_SPRITE_PTRS_ADDR + 1;
                PLS_LEVEL_PTRS[spr->level * 2] = (unsigned char)pls_lv_addr;
                PLS_LEVEL_PTRS[spr->level * 2 + 1] = (unsigned char)(pls_lv_addr >> 8);
                PLS_SPRITE_PTRS_ADDR += 0x20;
            }
            pls_lv_addr--;
            pls_lv_addr += (spr->number - 0xB0) * 2;

            if (PLS_DATA_ADDR >= 0x8000) {
                io.error("Too many Per-Level sprites.  Please remove some.\n", "");
                return false;
            }

            PLS_SPRITE_PTRS[pls_lv_addr] = (unsigned char)(PLS_DATA_ADDR + 1);
            PLS_SPRITE_PTRS[pls_lv_addr + 1] = (unsigned char)((PLS_DATA_ADDR + 1) >> 8);

            memcpy(PLS_DATA + PLS_DATA_ADDR, &spr->table, 0x10);
            memcpy(PLS_POINTERS + PLS_DATA_ADDR, &spr->ptrs, 15);
            int index = PLS_DATA_ADDR + 0x0F;
            if (index < 0x8000) {
                PLS_POINTERS[index] = 0xFF;
            } else {
                io.error("Per-level sprites data address out of bounds of array, value is %d", PLS_DATA_ADDR);
                return false;
            }
            PLS_DATA_ADDR += 0x10;
        }
    }
    return true;
}

[[nodiscard]] bool clean_hack(ROM& rom, std::string_view pathname) {
    if (!strncmp((char*)rom.data + rom.snes_to_pc(0x02FFE2), "STSD", 4)) { // already installed load old tables

        std::string path = cfg.AsmDir + "_cleanup.asm";
        patchfile clean_patch{path};

        int version = rom.data[rom.snes_to_pc(0x02FFE6)];
        int flags = rom.data[rom.snes_to_pc(0x02FFE7)];

        bool per_level_sprites_inserted = ((flags & 0x01) == 1) || (version < 2);

        // bit 0 = per level sprites inserted
        if (per_level_sprites_inserted) {
            // remove per level sprites
            // version 1.30+
            if (version >= 30) {
                clean_patch.fprintf(";Per-Level sprites\n");
                int level_table_address = rom.pointer_snes(0x02FFF1).addr();
                if (level_table_address != 0xFFFFFF && level_table_address != 0x000000) {
                    int pls_addr = rom.snes_to_pc(level_table_address);
                    for (int level = 0; level < 0x0400; level += 2) {
                        int pls_lv_addr = (rom.data[pls_addr + level] + (rom.data[pls_addr + level + 1] << 8));
                        if (pls_lv_addr == 0)
                            continue;
                        pls_lv_addr = rom.snes_to_pc(pls_lv_addr + level_table_address);
                        for (int i = 0; i < 0x20; i += 2) {
                            int pls_data_addr = (rom.data[pls_lv_addr + i] + (rom.data[pls_lv_addr + i + 1] << 8));
                            if (pls_data_addr == 0)
                                continue;
                            pointer main_pointer = rom.pointer_snes(pls_data_addr + level_table_address + 0x0B);
                            if (main_pointer.addr() == 0xFFFFFF) {
                                // clean_patch.fprintf( ";Encountered pointer to 0xFFFFFF, assuming there to be no
                                // sprites to clean!\n");
                                continue;
                            }
                            if (!main_pointer.is_empty()) {
                                clean_patch.fprintf("autoclean $%06X\t;%03X:%02X\n", main_pointer.addr(), level >> 1,
                                                    0xB0 + (i >> 1));
                            }
                        }
                    }
                }
                // version 1.2x
            } else {
                for (int bank = 0; bank < 4; bank++) {
                    int level_table_address = (rom.data[rom.snes_to_pc(0x02FFEA + bank)] << 16) + 0x8000;
                    if (level_table_address == 0xFF8000)
                        continue;
                    clean_patch.fprintf(";Per Level sprites for levels %03X - %03X\n", (bank * 0x80),
                                        ((bank + 1) * 0x80) - 1);
                    for (int table_offset = 0x0B; table_offset < 0x8000; table_offset += 0x10) {
                        pointer main_pointer = rom.pointer_snes(level_table_address + table_offset);
                        if (main_pointer.addr() == 0xFFFFFF) {
                            clean_patch.fprintf(
                                ";Encountered pointer to 0xFFFFFF, assuming there to be no sprites to clean!\n");
                            break;
                        }
                        if (!main_pointer.is_empty()) {
                            clean_patch.fprintf("autoclean $%06X\n", main_pointer.addr());
                        }
                    }
                    clean_patch.fprintf("\n");
                }
            }
        }

        // if per level sprites are inserted, we only have 0xF00 bytes of normal sprites
        // due to 10 bytes per sprite and B0-BF not being in the table.
        // but if version is 1.30 or higher, we have 0x1000 bytes.
        const int limit = version >= 30 ? 0x1000 : (per_level_sprites_inserted ? 0xF00 : 0x1000);

        // remove global sprites
        clean_patch.fprintf(";Global sprites: \n");
        int global_table_address = rom.pointer_snes(0x02FFEE).addr();
        if (rom.pointer_snes(global_table_address).addr() != 0xFFFFFF) {
            for (int table_offset = 0x08; table_offset < limit; table_offset += 0x10) {
                pointer init_pointer = rom.pointer_snes(global_table_address + table_offset);
                if (!init_pointer.is_empty()) {
                    clean_patch.fprintf("autoclean $%06X\n", init_pointer.addr());
                }
                pointer main_pointer = rom.pointer_snes(global_table_address + table_offset + 3);
                if (!main_pointer.is_empty()) {
                    clean_patch.fprintf("autoclean $%06X\n", main_pointer.addr());
                }
            }
        }

        // remove global sprites' custom pointers
        clean_patch.fprintf(";Global sprite custom pointers: \n");
        int pointer_table_address = rom.pointer_snes(0x02FFFD).addr();
        if (pointer_table_address != 0xFFFFFF && rom.pointer_snes(pointer_table_address).addr() != 0xFFFFFF) {
            for (int table_offset = 0; table_offset < 0x100 * 15; table_offset += 3) {
                pointer ptr = rom.pointer_snes(pointer_table_address + table_offset);
                if (!ptr.is_empty() && ptr.addr() != 0) {
                    clean_patch.fprintf("autoclean $%06X\n", ptr.addr());
                }
            }
        }

        // shared routines
        clean_patch.fprintf("\n\n;Routines:\n");
        for (int i = 0; i < 100; i++) {
            int routine_pointer = rom.pointer_snes(0x03E05C + i * 3).addr();
            if (routine_pointer != 0xFFFFFF) {
                clean_patch.fprintf("autoclean $%06X\n", routine_pointer);
                clean_patch.fprintf("\torg $%06X\n", 0x03E05C + i * 3);
                clean_patch.fprintf("\tdl $FFFFFF\n");
            }
        }

        // Version 1.01 stuff:
        if (version >= 1) {
            clean_sprite_generic(clean_patch, 0x00A68A, 0x9C1498, SPRITE_COUNT, "\n\n;Cluster:\n", rom);
            clean_sprite_generic(clean_patch, 0x029B1F, 0x176FBC, SPRITE_COUNT, "\n\n;Extended:\n", rom);
            clean_sprite_generic(clean_patch, 0x028B70, 0x942016, LESS_SPRITE_COUNT, "\n\n;MinorExtended:\n", rom);
            clean_sprite_generic(clean_patch, 0x029058, 0x03F016, LESS_SPRITE_COUNT, "\n\n;Bounce:\n", rom);
            clean_sprite_generic(clean_patch, 0x0296C4, 0x7F2912, LESS_SPRITE_COUNT, "\n\n;Smoke:\n", rom);
            clean_sprite_generic(clean_patch, 0x0299D8, 0x2003F0, MINOR_SPRITE_COUNT, "\n\n;SpinningCoin:\n", rom);
            clean_sprite_generic(clean_patch, 0x02ADBE, 0xF016E1, MINOR_SPRITE_COUNT, "\n\n;Score:\n", rom);
        }

        // everything else is being cleaned by the main patch itself.
        clean_patch.close();
        if (!patch(clean_patch, rom))
            return false;
    } else if (!strncmp((char*)rom.data + rom.snes_to_pc(rom.pointer_snes(0x02A963 + 1).addr() - 3), "MDK",
                        3)) { // check for old sprite_tool code. (this is annoying)
        std::string spritetool_clean = std::string{pathname} + "spritetool_clean.asm";
        if (!patch(spritetool_clean.c_str(), rom))
            return false;
        // removes all STAR####MDK tags
        const char* mdk = "MDK"; // sprite tool added "MDK" after the rats tag to find it's insertions...
        int number_of_banks = rom.size / 0x8000;
        for (int i = 0x10; i < number_of_banks; ++i) {
            char* bank = (char*)(rom.real_data + i * 0x8000);

            int bank_offset = 8;
            while (true) {
                // look for data inserted on previous uses

                int offset = bank_offset;
                unsigned int j = 0;
                for (; offset < 0x8000; offset++) {
                    if (bank[offset] != mdk[j++])
                        j = 0;
                    if (j == strlen(mdk)) {
                        offset -= static_cast<int>(strlen(mdk)) - 1; // set pointer to start of mdk string
                        break;
                    }
                }

                if (offset >= 0x8000)
                    break;
                bank_offset = offset + static_cast<int>(strlen(mdk));
                if (strncmp((bank + offset - 8), "STAR", 4)) // check for "STAR"
                    continue;

                // delete the amount that the RATS tag is protecting
                int size = ((unsigned char)bank[offset - 3] << 8) + (unsigned char)bank[offset - 4] + 8;
                int inverted = ((unsigned char)bank[offset - 1] << 8) + (unsigned char)bank[offset - 2];

                if ((size - 8 + inverted) == 0x0FFFF) // new tag
                    size++;

                else if ((size - 8 + inverted) != 0x10000) { // (not old tag either =>) bad tag
                    char answer;
                    int pc = i * 0x8000 + offset - 8 + rom.header_size;
                    io.print("size: %04X, inverted: %04X\n", size - 8, inverted);
                    io.print("Bad sprite_tool RATS tag detected at $%06X / 0x%05X. Remove anyway (y/n) ",
                             rom.pc_to_snes(pc), pc);
                    int read_values = io.scanf("%c", &answer);
                    if ((answer != 'Y' && answer != 'y') || read_values != 1)
                        continue;
                }

                memset(bank + offset - 8, 0, size);
                bank_offset = offset - 8 + size;
            }
        }
    }
    return true;
}

bool areConfigFlagsToggled() {
    return cfg.PerLevel || cfg.Disable255Sprites || true; // for now config is recreated on all runs
}

std::vector<definedata> create_config_defines() {
    std::vector<definedata> defines{};
    if (areConfigFlagsToggled()) {
        defines.push_back({.name = "PerLevel", .contents = (cfg.PerLevel ? "1" : "0")});
        defines.push_back({.name = "Disable255SpritesPerLevel", .contents = (cfg.Disable255Sprites ? "1" : "0")});
    }
    return defines;
}

std::vector<std::string> listExtraAsm(const std::string& path, bool& has_error) {
    has_error = false;
    std::vector<std::string> extraDefines;
    if (!std::filesystem::exists(cleanPathTrail(path))) {
        return extraDefines;
    }
    try {
        for (auto& file : std::filesystem::directory_iterator(path)) {
            std::string spath = file.path().generic_string();
            if (nameEndWithAsmExtension(spath)) {
                extraDefines.push_back(spath);
            }
        }
    } catch (const std::filesystem::filesystem_error& err) {
        io.error("Trying to read folder \"%s\" returned \"%s\", aborting insertion\n", path.c_str(), err.what());
        has_error = true;
    }
    if (!extraDefines.empty())
        std::sort(extraDefines.begin(), extraDefines.end());
    return extraDefines;
}

[[nodiscard]] bool create_shared_patch(const std::string& routine_path, const PixiConfig& config) {
    std::string escapedRoutinepath = escapeDefines(routine_path, R"(\\\!)");
    g_shared_patch.fprintf("macro include_once(target, base, offset)\n"
                           "	if !<base> != 1\n"
                           "		!<base> = 1\n"
                           "		pushpc\n"
                           "		if read3(<offset>+$03E05C) != $FFFFFF\n"
                           "			<base> = read3(<offset>+$03E05C)\n"
                           "		else\n"
                           "			freecode cleaned\n"
                           "				global #<base>:\n"
                           "				print \"    Routine: <base> inserted at $\",pc\n"
                           "				namespace <base>\n"
                           "				incsrc \"<target>\"\n"
                           "               namespace off\n"
                           "			ORG <offset>+$03E05C\n"
                           "				dl <base>\n"
                           "		endif\n"
                           "		pullpc\n"
                           "	endif\n"
                           "endmacro\n");
    int routine_count = 0;
    if (!std::filesystem::exists(cleanPathTrail(routine_path))) {
        io.error("Couldn't open folder \"%s\" for reading.", routine_path.c_str());
        return false;
    }
    try {
        for (const auto& routine_file : std::filesystem::directory_iterator(routine_path)) {
            std::string name(routine_file.path().filename().generic_string());
            if (routine_count > config.Routines) {
                io.error(
                    "More than %d routines located. Please remove some or change the max number of routines with the "
                    "-nr option. \n",
                    config.Routines);
                return false;
            }
            if (nameEndWithAsmExtension(name)) {
                name = name.substr(0, name.length() - 4);
                const char* charName = name.c_str();
                g_shared_patch.fprintf("!%s = 0\n"
                                       "macro %s()\n"
                                       "\t%%include_once(\"%s%s.asm\", %s, $%02X)\n"
                                       "\tJSL %s\n"
                                       "endmacro\n",
                                       charName, charName, escapedRoutinepath.c_str(), charName, charName,
                                       routine_count * 3, charName);
                routine_count++;
            }
        }
    } catch (const std::filesystem::filesystem_error& err) {
        io.error("Trying to read folder \"%s\" returned \"%s\", aborting insertion\n", routine_path.c_str(),
                 err.what());
        return false;
    }
    io.print("%d Shared routines registered in \"%s\"\n", routine_count, routine_path.data());
    g_shared_patch.close();
    g_memory_files.push_back(g_shared_patch.vfile());
    return true;
}

[[nodiscard]] bool populate_sprite_list(const Paths& paths,
                                        const std::array<sprite*, FromEnum(ListType::__SIZE__)>& sprite_lists,
                                        std::string_view listPath) {
    using namespace std::string_view_literals;
    std::ifstream listStream{listPath.data()};
    if (!listStream) {
        io.error("Could not open list file \"%s\" for reading", listPath.data());
        return false;
    }
    unsigned int sprite_id, level;
    int lineno = 0;
    int read_res;
    std::string line;
    ListType type = ListType::Sprite;
    sprite* spr = nullptr;
    char cfgname[FILENAME_MAX] = {0};
    const char* dir = nullptr;
    while (std::getline(listStream, line)) {
        int read_until = -1;
        sprite* sprite_list = sprite_lists[FromEnum(type)];
        // possible line formats: xxx:yy filename.<cfg/json/asm> [; ...]
        //						  yy filename.<cfg/json/asm> [; ...]
        // 						  TYPE: [; ...]
        lineno++;
        if (line.find(';') != std::string::npos)
            line.erase(line.begin() + line.find_first_of(';'), line.end());
        trim(line);
        if (line.empty())
            continue;
        if (line.find(':') == std::string::npos) { // if there's no : in the string, it's a non per-level sprite
            level = 0x200;
            read_res = sscanf(line.c_str(), "%x %n", &sprite_id, &read_until);
            if (read_res != 1 || read_res == EOF || read_until == -1) {
                io.error("List line %d was malformed: \"%s\"\n", lineno, line.c_str());
                return false;
            }
            strcpy(cfgname, line.c_str() + read_until);
        } else if (line.find(':') == line.length() - 1) { // if it's the last char in the string, it's a type change
            using svt = std::pair<std::string_view, ListType>;
            constexpr std::array typeArray{svt{"SPRITE:"sv, ListType::Sprite},
                                           svt{"CLUSTER:"sv, ListType::Cluster},
                                           svt{"EXTENDED:"sv, ListType::Extended},
                                           svt{"MINOREXTENDED:"sv, ListType::MinorExtended},
                                           svt{"BOUNCE:"sv, ListType::Bounce},
                                           svt{"SMOKE:"sv, ListType::Smoke},
                                           svt{"SPINNINGCOIN:"sv, ListType::SpinningCoin},
                                           svt{"SCORE:"sv, ListType::Score}};
            auto it = std::find_if(typeArray.begin(), typeArray.end(),
                                   [&line](const svt& svtl) { return svtl.first == line; });
            if (it != typeArray.end()) {
                type = it->second;
            }
            continue;
        } else { // if there's a ':' but it's not at the end, it may be a per level sprite
            read_res = sscanf(line.c_str(), "%x:%x %n", &level, &sprite_id, &read_until);
            if (read_res != 2 || read_res == EOF || read_until == -1) {
                io.error("List line %d was malformed: \"%s\"\n", lineno, line.c_str());
                return false;
            }
            if (!cfg.PerLevel) {
                io.error("Trying to insert per level sprites without using the -pl flag, at list line %d: \"%s\"\n",
                         lineno, line.c_str());
                return false;
            }
            strcpy(cfgname, line.c_str() + read_until);
        }

        char* dot = strrchr(cfgname, '.');
        if (dot == nullptr) {
            io.error("Error on list line %d: missing extension on filename %s\n", lineno, cfgname);
            return false;
        }
        dot++;

        if (type == ListType::Sprite) {
            spr = from_table<sprite>(sprite_list, level, sprite_id);
            // verify sprite pointer and determine cause if invalid
            if (!spr) {
                if (sprite_id >= 0x100) {
                    io.error("Error on list line %d: Sprite number must be less than 0x100\n", lineno);
                    return false;
                }
                if (level > 0x200) {
                    io.error("Error on list line %d: Level must range from 000-1FF\n", lineno);
                    return false;
                }
                if (cfg.PerLevel && level != 0x200 && (sprite_id < 0xB0 || sprite_id >= 0xC0)) {
                    io.error("Error on list line %d: Per-level sprite valid range is B0-BF, was given %X instead\n",
                             lineno, sprite_id);
                    return false;
                }
                io.error("Error on list line %d: Sprite was invalid, couldn't determine the specific reason, please "
                         "report this at " GITHUB_ISSUE_LINK,
                         lineno);
                return false;
            }
        } else {
            size_t max_size = sprite_sizes[static_cast<size_t>(FromEnum(type)) - 1].second;
            if (sprite_id > max_size) {
                io.error("Error on list line %d: Sprite number must be less than %x\n", lineno, max_size);
                return false;
            }
            spr = sprite_list + sprite_id;
        }

        if (spr->line) {
            io.error("Error on list line %d: Sprite number %x already used.\n", lineno, sprite_id);
            return false;
        }
        // initialize some.
        spr->line = lineno;
        spr->level = level;
        spr->number = sprite_id;
        spr->sprite_type = type;

        auto map_list_type_to_path = [](ListType lt) {
            return ToEnum<PathType>(FromEnum(PathType::Extended) - 1 + FromEnum(lt));
        };

        // set the directory for the desired type
        if (type != ListType::Sprite)
            dir = paths[map_list_type_to_path(type)].c_str();
        else {
            if (sprite_id < 0xC0)
                dir = paths[PathType::Sprites].c_str();
            else if (sprite_id < 0xD0)
                dir = paths[PathType::Shooters].c_str();
            else
                dir = paths[PathType::Generators].c_str();
        }
        spr->directory = dir;

        char* fullFileName = new char[strlen(dir) + strlen(cfgname) + 1];
        strcpy(fullFileName, dir);
        strcat(fullFileName, cfgname);

        if (type != ListType::Sprite) {
            if (strcmp(dot, "asm") && strcmp(dot, "ASM")) {
                io.error("Error on list line %d: not an asm file\n", lineno, fullFileName);
                return false;
            }
            spr->asm_file = fullFileName;
        } else {
            spr->cfg_file = fullFileName;
            if (!strcmp(dot, "cfg") || !strcmp(dot, "CFG")) {
                if (!read_cfg_file(spr)) {
                    io.error("Error on list line %d: Cannot parse CFG file %s.\n", lineno, spr->cfg_file);
                    return false;
                }

            } else if (!strcmp(dot, "json") || !strcmp(dot, "JSON")) {
                if (!read_json_file(spr)) {
                    io.error("Error on list line %d: Cannot parse JSON file %s.\n", lineno, spr->cfg_file);
                    return false;
                }
            } else {
                io.error("Error on list line %d: Unknown filetype %s\n", lineno, dot);
                return false;
            }
        }

        io.debug("Read from list line %d\n", spr->line);
        if (spr->level != 0x200)
            io.debug("Number %02X for level %03X\n", spr->number, spr->level);
        else
            io.debug("Number %02X\n", spr->number);
        spr->print();
        io.debug("\n--------------------------------------\n");

        // if sprite is tweak, set init and main pointer to contents of ROM pointer table.
        if (!spr->table.type) {
            spr->table.init = (INIT_PTR + 2 * spr->number);
            spr->table.main = (MAIN_PTR + 2 * spr->number);
        }
    }
    return true;
}

// spr      = sprite array
// filename = duh
// size     = number of sprites to loop over
[[nodiscard]] patchfile write_long_table(sprite* spr, std::string_view dir, std::string_view filename,
                                         unsigned int size = 0x800) {
    unsigned char dummy[0x10] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
    std::vector<unsigned char> file{};
    file.resize(static_cast<size_t>(size) * 0x10);
    if (is_empty_table({spr, size})) {
        return write_all(dummy, dir, filename, 0x10);
    } else {
        for (unsigned int i = 0; i < size; i++) {
            memcpy(file.data() + (i * 0x10), &spr[i].table, 0x10);
        }
        return write_all(file.data(), dir, filename, size * 0x10);
    }
}

FILE* open_subfile(ROM& rom, const char* ext, const char* mode) {
    char* name = new char[rom.name.size() + 1];
    strcpy(name, rom.name.data());
    char* dot = strrchr(name, '.');
    strcpy(dot + 1, ext);
#ifdef DEBUGMSG
    debug_print("\ttry opening %s mode %s\n", name, mode);
#endif
    FILE* r = open(name, mode);
    delete[] name;
    return r;
}

void remove(std::string_view dir, const char* file) {
    std::string path{dir};
    path += file;
    remove(path.c_str());
}

#ifdef PIXI_DLL_BUILD
#ifdef _WIN32
#define PIXI_EXPORT extern "C" __declspec(dllexport)
#else
#define PIXI_EXPORT extern "C" __attribute__((visibility("default")))
#endif
#else
#define PIXI_EXPORT extern "C"
#endif

void pixi_reset() {
    memset(PLS_LEVEL_PTRS, 0, sizeof(PLS_LEVEL_PTRS));
    memset(PLS_SPRITE_PTRS, 0, sizeof(PLS_SPRITE_PTRS));
    PLS_SPRITE_PTRS_ADDR = 0;
    memset(PLS_DATA, 0, sizeof(PLS_DATA));
    memset(PLS_POINTERS, 0, sizeof(PLS_POINTERS));
    PLS_DATA_ADDR = 0;
    warnings.clear();
    io.init();
    g_memory_files.clear();
    g_shared_patch.clear();
    g_config_defines.clear();
    patchfile::set_keep(false, false);
    cfg.reset();
}

PIXI_EXPORT int pixi_api_version() {
    return VERSION_FULL;
}

PIXI_EXPORT int pixi_check_api_version(int version_edition, int version_major, int version_minor) {
    return version_edition == VERSION_EDITION && version_major == VERSION_MAJOR && version_minor == VERSION_MINOR;
}

PIXI_EXPORT int pixi_run(int argc, const char** argv, bool skip_first) {
#ifndef PIXI_EXE_BUILD
    pixi_reset();
#endif
    ROM rom;
    // individual lists containing the sprites for the specific sections
    static sprite sprite_list[MAX_SPRITE_COUNT];
    static sprite cluster_list[SPRITE_COUNT];
    static sprite extended_list[SPRITE_COUNT];
    static sprite minor_extended_list[LESS_SPRITE_COUNT];
    static sprite bounce_list[LESS_SPRITE_COUNT];
    static sprite smoke_list[LESS_SPRITE_COUNT];
    static sprite spinningcoin_list[MINOR_SPRITE_COUNT];
    static sprite score_list[MINOR_SPRITE_COUNT];

#ifndef PIXI_EXE_BUILD
    for (auto& spr : sprite_list) {
        spr.clear();
    }
    for (auto& spr : cluster_list) {
        spr.clear();
    }
    for (auto& spr : extended_list) {
        spr.clear();
    }
    for (auto& spr : minor_extended_list) {
        spr.clear();
    }
    for (auto& spr : bounce_list) {
        spr.clear();
    }
    for (auto& spr : smoke_list) {
        spr.clear();
    }
    for (auto& spr : spinningcoin_list) {
        spr.clear();
    }
    for (auto& spr : score_list) {
        spr.clear();
    }
#endif

    // the list containing the lists...
    std::array<sprite*, FromEnum(ListType::__SIZE__)> sprites_list_list{
        sprite_list, extended_list, cluster_list,      minor_extended_list,
        bounce_list, smoke_list,    spinningcoin_list, score_list};

#ifdef ON_WINDOWS
    std::string lm_handle;
    uint16_t verification_code = 0;
    HWND window_handle = nullptr;
#endif
    // first is version x.xx, others are preserved
    unsigned char versionflag[4] = {VERSION_FULL, 0x00, 0x00, 0x00};
    bool version_requested = false;
    // map16 for sprite displays
    static map16 map[MAP16_SIZE];
    argparser optparser{};
    if (std::filesystem::exists("pixi_settings.json")) {
        std::ifstream settings_file{"pixi_settings.json"};
        nlohmann::json j;
        settings_file >> j;
        if (!optparser.init(j)) {
            io.error("JSON format of Pixi settings is wrong.");
        }
    } else {
        optparser.init(skip_first ? argc - 1 : argc, skip_first ? argv + 1 : argv);
    }
    optparser.add_version(VERSION_PARTIAL, VERSION_EDITION);
    optparser.allow_unmatched(1);
    optparser.add_usage_string("pixi <options> [ROM]");
    optparser.add_option("-v", "Print version information", version_requested)
        .add_option("--version", "Print version information", version_requested)
        .add_option("--rom", "ROMFILE",
                    "ROM file, when the --rom is not given, it is assumed to be the first unmatched argument", rom.name)
        .add_option("-d", "Enable debug output, the option flag -out only works when this is set", cfg.DebugEnabled)
        .add_option("--debug", "Enable debug output, the option flag -out only works when this is set",
                    cfg.DebugEnabled)
        .add_option("-k", "Keep debug files", cfg.KeepFiles)
        .add_option("-l", "list path", "Specify a custom list file", cfg[PathType::List])
        .add_option("-pl", "Per level sprites - will insert perlevel sprite code", cfg.PerLevel)
        .add_option("-npl", "Disable per level sprites (default), kept for compatibility reasons", argparser::no_value)
        .add_option("-d255spl", "Disable 255 sprites per level support (won't do the 1938 remap)",
                    cfg.Disable255Sprites)
        .add_option("-w", "Enable asar warnings check, recommended to use when developing sprites.", cfg.Warnings)
        .add_option("-a", "asm", "Specify a custom asm directory", cfg[PathType::Asm])
        .add_option("-sp", "sprites", "Specify a custom sprites directory", cfg[PathType::Sprites])
        .add_option("-sh", "shooters", "Specify a custom shooters sprites directory", cfg[PathType::Shooters])
        .add_option("-g", "generators", "Specify a custom generators sprites directory", cfg[PathType::Generators])
        .add_option("-e", "extended", "Specify a custom extended sprites directory", cfg[PathType::Extended])
        .add_option("-c", "cluster", "Specify a custom cluster sprites directory", cfg[PathType::Cluster])
        .add_option("-me", "minorextended", "Specify a custom minor extended sprites directory",
                    cfg[PathType::MinorExtended])
        .add_option("-b", "bounce", "Specify a custom bounce sprites directory", cfg[PathType::Bounce])
        .add_option("-sm", "smoke", "Specify a custom smoke sprites directory", cfg[PathType::Smoke])
        .add_option("-sn", "spinningcoin", "Specify a custom spinningcoin sprites directory",
                    cfg[PathType::SpinningCoin])
        .add_option("-sc", "score", "Specify a custom score sprites directory", cfg[PathType::Score])
        .add_option("-r", "routines", "Specify a shared routine directory", cfg[PathType::Routines])
        .add_option("-nr", "number", "Specify limit to shared routines, the maximum number is " STR(MAX_ROUTINES),
                    cfg.Routines)
        .add_option("-extmod-off", "Disables extmod file logging (check LM's readme for more info on what extmod is)",
                    cfg.ExtModDisabled)
        .add_option("-ssc", "append ssc", "Specify ssc file to be copied into <romname>.ssc", cfg[ExtType::Ssc])
        .add_option("-mwt", "append mwt", "Specify mwt file to be copied into <romname>.mwt", cfg[ExtType::Mwt])
        .add_option("-mw2", "append mw2", "Specify mw2 file to be copied into <romname>.mw2", cfg[ExtType::Mw2])
        .add_option("-s16", "base s16", "Specify s16 file to be used as a base for <romname>.s16", cfg[ExtType::S16])
        .add_option("-no-lm-aux", "Disables all of the Lunar Magic auxiliary files creation (ssc, mwt, mw2, s16)",
                    cfg.DisableAllExtensionFiles)
        .add_option("-meimei-off", "Shuts down MeiMei completely", cfg.DisableMeiMei)
        .add_option("-meimei-a", "Enables always remap sprite data", MeiMei::AlwaysRemap())
        .add_option("-meimei-k", "Enables keep temp patches files", MeiMei::KeepTemp())
        .add_option("-meimei-d", "Enables debug for MeiMei patches", MeiMei::Debug())
#ifdef ON_WINDOWS
        .add_option("-lm-handle", "lm_handle_code",
                    "To be used only within LM's custom user toolbar file, it receives LM's handle to reload the rom",
                    lm_handle)
#endif
        ;

    //------------------------------------------------------------------------------------------
    // handle arguments passed to tool
    //------------------------------------------------------------------------------------------
    bool parsed_correctly = optparser.parse();
    if (optparser.help_requested()) {
        optparser.print_help();
        return EXIT_SUCCESS;
    }
    if (!parsed_correctly)
        return EXIT_FAILURE;
    if (argc < 2) {
        atexit(double_click_exit);
    }
    if (cfg.DebugEnabled) {
        io.enable_debug();
    }
    if (cfg.Routines > MAX_ROUTINES) {
        io.error("The number of possible routines (%d) is higher than the maximum number possible, please lower it. "
                 "(Current max is " STR(MAX_ROUTINES) ")",
                 cfg.Routines);
        return EXIT_FAILURE;
    }

    // DEV_BUILD means either debug build or CI build.
    if constexpr (PIXI_DEV_BUILD) {
        io.print("Pixi development version %d.%d - %s\n", VERSION_EDITION, VERSION_PARTIAL, VERSION_DEBUG);
    } else if (version_requested) {
        io.print("Pixi version %d.%d\n", VERSION_EDITION, VERSION_PARTIAL);
    }

    if (!asar_init()) {
        io.error(
            "Error: Asar library is missing or couldn't be initialized, please redownload the tool or add the dll.\n");
        return EXIT_FAILURE;
    }

#ifdef ON_WINDOWS
    if (!lm_handle.empty()) {
        window_handle = (HWND)std::stoull(lm_handle, nullptr, 16);
        verification_code = (uint16_t)(std::stoi(lm_handle.substr(lm_handle.find_first_of(':') + 1), 0, 16));
    }
#endif

    patchfile::set_keep(cfg.KeepFiles, MeiMei::KeepTemp());
    versionflag[1] = (cfg.PerLevel ? 1 : 0);

    //------------------------------------------------------------------------------------------
    // Get ROM name if none has been passed yet.
    //------------------------------------------------------------------------------------------

    if (optparser.unmatched().empty() && rom.name.empty()) {
        io.print("Enter a ROM file name, or drag and drop the ROM here: ");
        char ROM_name[FILENAME_MAX];
        if (libconsole::read(ROM_name, FILENAME_MAX, libconsole::handle::in)) {
            size_t length = libconsole::bytelen(ROM_name);
            if (length == 0) {
                io.error("Rom name can't be empty");
                return EXIT_FAILURE;
            }
            // remove ending whitespace (\r\n)
            while (length > 0 && libconsole::isspace(ROM_name[length - 1])) {
                ROM_name[--length] = '\0';
            }
            if (length == 0) {
                io.error("Rom name can't be empty");
                return EXIT_FAILURE;
            }
            if ((ROM_name[0] == '"' && ROM_name[length - 1] == '"') ||
                (ROM_name[0] == '\'' && ROM_name[length - 1] == '\'')) {
                ROM_name[length - 1] = '\0';
                for (int i = 0; ROM_name[i]; i++) {
                    ROM_name[i] = ROM_name[i + 1]; // no buffer overflow there are two null chars.
                }
            }
        }
        if (!rom.open(ROM_name))
            return EXIT_FAILURE;
    } else if (rom.name.empty()) {
        if (!rom.open(optparser.unmatched().front().c_str()))
            return EXIT_FAILURE;
    } else {
        if (!rom.open())
            return EXIT_FAILURE;
    }

    //------------------------------------------------------------------------------------------
    // Check if a newer version has been used before.
    //------------------------------------------------------------------------------------------

    unsigned char version = rom.data[rom.snes_to_pc(0x02FFE2 + 4)];
    if (version > VERSION_FULL && version != 0xFF) {
        int edition = version / 100;
        int partial = version % (edition * 100);
        io.error("The ROM has been patched with a newer version of PIXI (%d.%d) already.\n", edition, partial);
        io.error("This is version %d.%d\n", VERSION_EDITION, VERSION_PARTIAL);
        io.error("Please get a newer version.");
        rom.close();
        asar_close();
        return EXIT_FAILURE;
    }

    auto lm_edit_ptr = rom.pointer_snes(0x06F624); // thanks p4plus2
    if (lm_edit_ptr.addr() == 0xFFFFFF) {
        io.print(
            "You're inserting Pixi without having modified a level in Lunar Magic, this will cause bugs\nDo you "
            "want to abort insertion now [y/n]?\nIf you choose 'n', to fix the bugs just reapply Pixi after having "
            "modified a level\n");
        char c = io.getc();
        if (tolower(c) == 'y') {
            rom.close();
            asar_close();
            io.error("Insertion was stopped, press any button to exit...\n");
            io.getc();
            return EXIT_FAILURE;
        }
        fflush(stdin); // uff
    }

    unsigned char vram_jump = rom.data[rom.snes_to_pc(0x00F6E4)];
    if (vram_jump != 0x5C) {
        io.error("You haven't installed the VRAM optimization patch in Lunar Magic, this will cause many features of "
                 "Pixi to work incorrectly, insertion was aborted...\n");
        io.getc();
        return EXIT_FAILURE;
    }

    // Initialize MeiMei
    if (!cfg.DisableMeiMei) {
        if (!MeiMei::initialize(rom.name.data()))
            return EXIT_FAILURE;
    }

    //------------------------------------------------------------------------------------------
    // set path for directories relative to pixi or rom, not working dir.
    //------------------------------------------------------------------------------------------

    for (size_t i = 0; i < FromEnum(PathType::__SIZE__); i++) {
        if (i == FromEnum(PathType::List))
            set_paths_relative_to(cfg[ToEnum<PathType>(i)], rom.name.data());
        else
            set_paths_relative_to(cfg[ToEnum<PathType>(i)], argv[0]);
#ifdef DEBUGMSG
        debug_print("paths[%d] = %s\n", i, cfg.m_Paths[i].c_str());
#endif
    }
    cfg.AsmDir = cfg[PathType::Asm];
    cfg.AsmDirPath = cleanPathTrail(cfg.AsmDir);

    for (size_t i = 0; i < FromEnum(ExtType::__SIZE__); i++) {
        set_paths_relative_to(cfg[ToEnum<ExtType>(i)], rom.name.data());
#ifdef DEBUGMSG
        debug_print("extensions[%d] = %s\n", i, cfg.m_Extensions[i].c_str());
#endif
    }

    //------------------------------------------------------------------------------------------
    // regular stuff
    //------------------------------------------------------------------------------------------
    g_config_defines = create_config_defines();
    bool failed = true;
    std::vector<std::string> extraDefines = listExtraAsm(cfg.AsmDirPath + "/ExtraDefines", failed);
    if (failed)
        return EXIT_FAILURE;
    if (!populate_sprite_list(cfg.GetPaths(), sprites_list_list, cfg[PathType::List]))
        return EXIT_FAILURE;

    if (!clean_hack(rom, cfg[PathType::Asm]))
        return EXIT_FAILURE;

    if (!create_shared_patch(cfg[PathType::Routines], cfg))
        return EXIT_FAILURE;

    int normal_sprites_size = cfg.PerLevel ? MAX_SPRITE_COUNT : 0x100;
    if (!patch_sprites(extraDefines, sprite_list, normal_sprites_size, rom))
        return EXIT_FAILURE;
    for (const auto& [type, size] : sprite_sizes) {
        if (!patch_sprites(extraDefines, sprites_list_list[FromEnum(type)], static_cast<int>(size), rom))
            return EXIT_FAILURE;
    }

    if (!warnings.empty() && cfg.Warnings) {
        io.print("One or more warnings have been detected:\n");
        for (const std::string& warning : warnings) {
            io.print("%s\n", warning.c_str());
        }
        io.print("Do you want to continue insertion anyway? [Y/n] (Default is yes):\n");
        char c = io.getc();
        if (tolower(c) == 'n') {
            asar_close();
            io.print("Insertion was stopped, press any button to exit...\n");
            io.getc();
            return EXIT_FAILURE;
        }
    }
#ifdef DEBUGMSG
    debug_print("Sprites successfully patched.\n");
#endif
//------------------------------------------------------------------------------------------
// create binary files
//------------------------------------------------------------------------------------------

// sprites
#ifdef DEBUGMSG
    debug_print("Try create binary tables.\n");
#endif
    const auto& asm_path = cfg[PathType::Asm];
    std::vector<patchfile> binfiles{};
    binfiles.push_back(write_all(versionflag, asm_path, "_versionflag.bin", 4));
    if (cfg.PerLevel) {
        binfiles.push_back(write_all(PLS_LEVEL_PTRS, asm_path, "_perlevellvlptrs.bin", 0x400));
        if (PLS_DATA_ADDR == 0) {
            unsigned char dummy[1] = {0xFF};
            binfiles.push_back(write_all(dummy, asm_path, "_perlevelsprptrs.bin", 1));
            binfiles.push_back(write_all(dummy, asm_path, "_perlevelt.bin", 1));
            binfiles.push_back(write_all(dummy, asm_path, "_perlevelcustomptrtable.bin", 1));
        } else {
            binfiles.push_back(write_all(PLS_SPRITE_PTRS, asm_path, "_perlevelsprptrs.bin", PLS_SPRITE_PTRS_ADDR));
            binfiles.push_back(write_all(PLS_DATA, asm_path, "_perlevelt.bin", PLS_DATA_ADDR));
            binfiles.push_back(write_all(PLS_POINTERS, asm_path, "_perlevelcustomptrtable.bin", PLS_DATA_ADDR));
#ifdef DEBUGMSG
            debug_print("Per-level sprites data size : 0x400+0x%04X+2*0x%04X = %04X\n", PLS_SPRITE_PTRS_ADDR,
                        PLS_DATA_ADDR, 0x400 + PLS_SPRITE_PTRS_ADDR + 2 * PLS_DATA_ADDR);
#endif
        }
        binfiles.push_back(write_long_table(sprite_list + 0x2000, asm_path, "_defaulttables.bin", 0x100));
    } else {
        binfiles.push_back(write_long_table(sprite_list, asm_path, "_defaulttables.bin", 0x100));
    }
    unsigned char customstatusptrs[0x100 * 15]{};
    for (int i = 0, j = cfg.PerLevel ? 0x2000 : 0; i < 0x100 * 5; i += 5, j++) {
        memcpy(customstatusptrs + (i * 3), &sprite_list[j].ptrs, 15);
    }
    binfiles.push_back(write_all(customstatusptrs, asm_path, "_customstatusptr.bin", 0x100 * 15));

    binfiles.push_back(write_sprite_generic(cluster_list, "_clusterptr.bin"));
    binfiles.push_back(write_sprite_generic(extended_list, "_extendedptr.bin"));
    binfiles.push_back(write_sprite_generic(minor_extended_list, "_minorextendedptr.bin"));
    binfiles.push_back(write_sprite_generic(smoke_list, "_smokeptr.bin"));
    binfiles.push_back(write_sprite_generic(bounce_list, "_bounceptr.bin"));
    binfiles.push_back(write_sprite_generic(spinningcoin_list, "_spinningcoinptr.bin"));
    binfiles.push_back(write_sprite_generic(score_list, "_scoreptr.bin"));

    uint8_t file[SPRITE_COUNT * 3]{};
    for (size_t i = 0; i < SPRITE_COUNT; i++)
        memcpy(file + (i * 3), &extended_list[i].extended_cape_ptr, 3);
    binfiles.push_back(write_all(file, asm_path, "_extendedcapeptr.bin", SPRITE_COUNT * 3));

    // more?
#ifdef DEBUGMSG
    debug_print("Binary tables created.\n");
#endif

    //------------------------------------------------------------------------------------------
    // create custom size table (extra property byte count)
    // and <romname>.xxx files.
    // (and any other stuff that can be done from looping over all 0x100 regular sprites
    //------------------------------------------------------------------------------------------

    // extra byte size file
    // plus data for .ssc, .mwt, .mw2 files
    unsigned char extra_bytes[0x200]{};

    if (!cfg.DisableAllExtensionFiles) {
        FILE* s16 = open_subfile(rom, "s16", "wb");
        FILE* ssc = open_subfile(rom, "ssc", "w");
        FILE* mwt = open_subfile(rom, "mwt", "w");
        FILE* mw2 = open_subfile(rom, "mw2", "wb");

        if (!cfg[ExtType::Ssc].empty()) {
            std::ifstream fin(cfg[ExtType::Ssc].c_str());
            std::string line;
            while (std::getline(fin, line)) {
                fprintf(ssc, "%s\n", line.c_str());
            }
            fin.close();
        }

        if (!cfg[ExtType::Mwt].empty()) {
            std::ifstream fin(cfg[ExtType::Mwt].c_str());
            std::string line;
            while (std::getline(fin, line)) {
                fprintf(mwt, "%s\n", line.c_str());
            }
            fin.close();
        }

        if (!cfg[ExtType::Mw2].empty()) {
            FILE* fp = open(cfg[ExtType::Mw2].c_str(), "rb");
            if (fp == nullptr)
                return EXIT_FAILURE;
            size_t fs_size = file_size(fp);
            if (fs_size == 0) {
                // if size == 0, it means that the file is empty, so we just append the 0x00 and go on with our lives
                fputc(0x00, mw2);
            } else {
                fs_size--; // -1 to skip the 0xFF byte at the end
                auto* mw2_data = new unsigned char[fs_size];
                size_t read_size = fread(mw2_data, 1, fs_size, fp);
                if (read_size != fs_size) {
                    io.error("Couldn't fully read file %s, please check file permissions", cfg[ExtType::Mw2].c_str());
                    return EXIT_FAILURE;
                }
                fclose(fp);
                fwrite(mw2_data, 1, fs_size, mw2);
                delete[] mw2_data;
            }
            fclose(fp);
        } else {
            fputc(0x00, mw2); // binary data starts with 0x00
        }

        if (!cfg[ExtType::S16].empty())
            read_map16(map, cfg[ExtType::S16].c_str());

        if (!generate_lm_data(sprite_list, map, extra_bytes, ssc, mwt, mw2, s16, cfg.PerLevel))
            return EXIT_FAILURE;

        binfiles.push_back(write_all(extra_bytes, asm_path, "_customsize.bin", 0x200));
        // close all the files.
        fclose(s16);
        fclose(ssc);
        fclose(mwt);
        fclose(mw2);
    }

    // apply the actual patches
    using namespace std::string_view_literals;
    std::array patch_names{"main.asm"sv,   "cluster.asm"sv, "extended.asm"sv,     "minorextended.asm"sv,
                           "bounce.asm"sv, "smoke.asm"sv,   "spinningcoin.asm"sv, "score.asm"sv};
    for (const auto& binfile : binfiles) {
        g_memory_files.push_back(binfile.vfile());
    }
    for (auto& patch_name : patch_names) {
        if (!patch(asm_path, patch_name.data(), rom)) {
            return EXIT_FAILURE;
        }
    }

    std::vector<std::string> extraHijacks = listExtraAsm(cfg.AsmDirPath + "/ExtraHijacks", failed);
    if (failed)
        return EXIT_FAILURE;

    if (!extraHijacks.empty()) {
        io.debug("-------- ExtraHijacks prints --------\n", "");
    }
    for (std::string patchUri : extraHijacks) {
        if (!patch(patchUri.c_str(), rom))
            return EXIT_FAILURE;
        int count_extra_prints = 0;
        auto prints = asar_getprints(&count_extra_prints);
        for (int i = 0; i < count_extra_prints; i++) {
            io.debug("From file \"%s\": %s\n", patchUri.c_str(), prints[i]);
        }
    }

    // patch(paths[ASM], "asm/overworld.asm", rom);

    //------------------------------------------------------------------------------------------
    // clean up (if necessary)
    //------------------------------------------------------------------------------------------

    io.print("\nAll sprites applied successfully!\n");

    if (!cfg.ExtModDisabled)
        if (!create_lm_restore(rom.name.data()))
            return EXIT_FAILURE;
    rom.close();
    asar_close();
    int retval = 0;
    if (!cfg.DisableMeiMei) {
        MeiMei::configureSa1Def(cfg.AsmDirPath + "/sa1def.asm");
        retval = MeiMei::run();
    }

#ifdef ON_WINDOWS
    if (!lm_handle.empty()) {
        uint32_t IParam = (verification_code << 16) + 2; // reload rom
        PostMessage(window_handle, 0xBECB, 0, IParam);
    }
#endif
    return retval;
}
