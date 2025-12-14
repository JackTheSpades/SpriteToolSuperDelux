#include <cstdio>

#include <array>
#include <exception>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <charconv>

#include "MeiMei/MeiMei.h"
#include "argparser.h"
#ifdef ASAR_USE_DLL
#include "asar/asardll.h"
#else
#include "asar/asar.h"
#endif
#include "cfg.h"
#include "config.h"
#include "file_io.h"
#include "iohandler.h"
#include "json.h"
#include "libconsole/libconsole.h"
#include "libplugin/libplugin.h"
#include "lmdata.h"
#include "map16.h"
#include "paths.h"

namespace fs = std::filesystem;

#ifdef ON_WINDOWS
#include <windows.h>
#define DYLIB_EXT ".dll"
#elif defined(__APPLE__)
#define DYLIB_EXT ".dylib"
#else
#define DYLIB_EXT ".so"
#endif

#include <chrono>
namespace cr = std::chrono;
struct PatchTimer {
    cr::high_resolution_clock::time_point m_start;
    std::string m_name;

    PatchTimer(std::string name) : m_start(cr::high_resolution_clock::now()), m_name(std::move(name)) {
    }

    ~PatchTimer() {
        auto end = cr::high_resolution_clock::now();
        [[maybe_unused]] auto dur = cr::duration_cast<cr::milliseconds>(end - m_start);
#if 0
        iohandler::get_global().debug("%s took %lld ms to patch\n", m_name.c_str(), dur.count());
#endif
    }
};

#define STRIMPL(x) #x
#define STR(x) STRIMPL(x)

// change the version in the project() call in the main CMakeLists, not here, changes will propagate.
constexpr uint8_t VERSION_MAJOR = PIXI_VERSION_MAJOR;
constexpr uint8_t VERSION_MINOR = PIXI_VERSION_MINOR;
constexpr uint8_t VERSION_PATCH = PIXI_VERSION_PATCH;
constexpr const char VERSION_DEBUG[] = STR(PIXI_VERSION_DEBUG);
constexpr uint8_t VERSION_PARTIAL = VERSION_MINOR * 10 + VERSION_PATCH;
constexpr uint8_t VERSION_FULL = VERSION_MAJOR * 100 + VERSION_MINOR * 10 + VERSION_PATCH;
static_assert(VERSION_FULL <= std::numeric_limits<uint8_t>::max());

constexpr auto INIT_PTR = 0x01817D; // snes address of default init pointers
constexpr auto MAIN_PTR = 0x0185CC; // guess what?
constexpr auto GOAL_POST_SPRITE_ID = 0x7B;

constexpr auto TEMP_SPR_FILE = "spr_temp.asm";

constexpr std::array<std::pair<ListType, size_t>, FromEnum(ListType::__SIZE__) - 1ull> sprite_sizes = {
    {{ListType::Extended, SPRITE_COUNT},
     {ListType::Cluster, SPRITE_COUNT},
     {ListType::MinorExtended, LESS_SPRITE_COUNT},
     {ListType::Bounce, LESS_SPRITE_COUNT},
     {ListType::Smoke, LESS_SPRITE_COUNT},
     {ListType::SpinningCoin, MINOR_SPRITE_COUNT},
     {ListType::Score, MINOR_SPRITE_COUNT}}};

constexpr std::array<PathType, FromEnum(ListType::__SIZE__)> map_list_to_path{
    PathType::Sprites,       // ListType::Sprite
    PathType::Extended,      // ListType::Extended
    PathType::Cluster,       // ListType::Cluster
    PathType::MinorExtended, // ListType::MinorExtended
    PathType::Bounce,        // ListType::Bounce
    PathType::Smoke,         // ListType::Smoke
    PathType::SpinningCoin,  // ListType::SpinningCoin
    PathType::Score          // ListType::Score
};

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
patchfile g_shared_inscrc_patch{"shared_incsrc.asm"};
std::vector<definedata> g_config_defines{};

struct addtempfile {
    const memoryfile& m_memory_file;
    addtempfile(const patchfile& file) : m_memory_file{g_memory_files.emplace_back(file.vfile())} {
    }
    ~addtempfile() {
        [[maybe_unused]] size_t s =
            std::erase_if(g_memory_files, [&](const memoryfile& mem) { return &mem == &m_memory_file; });
        assert(s == 1);
    }
};

void double_click_exit() {
#ifdef PIXI_EXE_BUILD
    io.getc(); // Pause before exit
#endif
}

template <typename T, size_t N> constexpr size_t array_size(T (&)[N]) {
    return N;
}

#ifdef ASAR_USE_DLL
struct AsarHandler {
    //                                             1.81
    static constexpr int s_asar_leak_max_version = 10801;
    bool m_ok{false};
    int m_asar_version{0};

    void asar_leak_fix() {
        // This is a hack to prevent a memory leak that's present in asar (ver 1.81 and previous)
        // basically when calling getalllabels(), the labeldata structer gets populated
        // but then it doesn't get cleaned up when asar_close() is called.
        // the workaround for this is to apply an empty patch, because before applying the patch
        // asar cleans up all the related data structures (labels included).
        // this prevents the leak.
        // tl,dr: remove this when the new asar version comes out because that version fixes the leak.
        int size = 0;
        const memoryfile file{"clean_labels.asm", "", 0};
        char fake_romdata = '\0';
        struct patchparams params{.structsize = sizeof(struct patchparams),
                                  .patchloc = "clean_labels.asm",
                                  .romdata = &fake_romdata,
                                  .buflen = 0,
                                  .romlen = &size,
                                  .includepaths = nullptr,
                                  .numincludepaths = 0,
                                  .should_reset = true,
                                  .additional_defines = nullptr,
                                  .additional_define_count = 0,
                                  .stdincludesfile = nullptr,
                                  .stddefinesfile = nullptr,
                                  .warning_settings = nullptr,
                                  .warning_setting_count = 0,
                                  .memory_files = &file,
                                  .memory_file_count = 1,
                                  .override_checksum_gen = false,
                                  .generate_checksum = true};
        if (!asar_patch_ex(&params)) {
            io.error(
                "Failed to apply cleanup patch, this is an internal error, please report it here " GITHUB_ISSUE_LINK
                "\n");
        }
        int labels = 0;
        asar_getalllabels(&labels);
        if (labels != 0) {
            io.error("Label count should be 0 after cleanup, this is an internal error, please report it "
                     "here " GITHUB_ISSUE_LINK "\n");
        }
    }

  public:
    AsarHandler() {
        m_ok = asar_init();
        if (m_ok) {
            m_asar_version = asar_version();
        }
    }
    bool ok() const {
        return m_ok;
    }
    ~AsarHandler() {
        if (m_ok) {
            if (m_asar_version <= s_asar_leak_max_version) {
                asar_leak_fix();
            }
            asar_close();
        }
    }
};
#endif

void clean_sprite_generic(patchfile& clean_patch, int table_address, int original_value, size_t count,
                          const char* preface, ROM& rom) {
    clean_patch.fprintf("%s", preface);
    auto table = rom.pointer_snes(table_address).addr();
    if (table != original_value) // check with default/uninserted address
        for (size_t i = 0; i < count; i++) {
            pointer pointer = rom.pointer_snes(table + 3 * static_cast<int>(i));
            if (!pointer.is_empty())
                clean_patch.fprintf("autoclean $%06X\n", pointer.raw());
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
        {.warnid = "Wrelative_path_used", .enabled = false},
        {.warnid = "W65816_xx_y_assume_16_bit", .enabled = false}
    };
    addtempfile tmp{file};
    const int memfiles_size = static_cast<int>(g_memory_files.size());
    struct patchparams params {
        .structsize = sizeof(struct patchparams), 
        .patchloc = file.path().c_str(),
        .romdata = reinterpret_cast<char*>(rom.unheadered_data()),
        .buflen = MAX_ROM_SIZE,
        .romlen = &rom.size, 
        .includepaths = nullptr,
        .numincludepaths = 0,
        .should_reset = true,
        .additional_defines = g_config_defines.data(), 
        .additional_define_count = static_cast<int>(g_config_defines.size()),
        .stdincludesfile = cfg.AsarStdIncludes.empty() ? nullptr : cfg.AsarStdIncludes.c_str(),
        .stddefinesfile = cfg.AsarStdDefines.empty() ? nullptr : cfg.AsarStdDefines.c_str(),
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
    int print_count = 0;
    const char* const* asar_prints = asar_getprints(&print_count);
    for (int i = 0; i < print_count; i++)
        io.debug("Asar print from %s: %s\n", file.path().c_str(), asar_prints[i]);

    if (!cfg.SymbolsType.empty()) {
        const char* symbols_contents = asar_getsymbolsfile(cfg.SymbolsType.c_str());
        std::string symbols_path{fs::path{file.path()}.replace_extension(cfg.SymbolsType).generic_string()};
        FILE* wla = open(symbols_path.c_str(), "w");
        if (wla) {
            fwrite(symbols_contents, 1, strlen(symbols_contents), wla);
            fclose(wla);
        }
    }

    return true;
}

[[nodiscard]] bool patch(const char* patch_name_rel, ROM& rom) {
    std::string patch_path{patch_name_rel}; //  = std::filesystem::absolute(patch_name_rel).generic_string();
    // clang-format off
    constexpr warnsetting disabled_warnings[] {
        {.warnid = "Wrelative_path_used", .enabled = false},
        {.warnid = "W65816_xx_y_assume_16_bit", .enabled = false}
    };
    patchparams params {
        .structsize = sizeof(patchparams), 
        .patchloc = patch_path.c_str(),
        .romdata = reinterpret_cast<char*>(rom.unheadered_data()),
        .buflen = MAX_ROM_SIZE,
        .romlen = &rom.size, 
        .includepaths = nullptr,
        .numincludepaths = 0,
        .should_reset = true,
        .additional_defines = g_config_defines.data(), 
        .additional_define_count = static_cast<int>(g_config_defines.size()),
        .stdincludesfile = cfg.AsarStdIncludes.empty() ? nullptr : cfg.AsarStdIncludes.c_str(),
        .stddefinesfile = cfg.AsarStdDefines.empty() ? nullptr : cfg.AsarStdDefines.c_str(),
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

    if (!cfg.SymbolsType.empty()) {
        const char* symbols_contents = asar_getsymbolsfile(cfg.SymbolsType.c_str());
        std::string symbols_path{fs::path{patch_name_rel}.replace_extension(cfg.SymbolsType).generic_string()};
        FILE* wla = open(symbols_path.c_str(), "w");
        if (wla) {
            fwrite(symbols_contents, 1, strlen(symbols_contents), wla);
            fclose(wla);
        }
    }

    int print_count = 0;
    const char* const* asar_prints = asar_getprints(&print_count);
    for (int i = 0; i < print_count; i++)
        io.debug("Asar print from %s: %s\n", patch_name_rel, asar_prints[i]);
    return true;
}

[[nodiscard]] bool patch(std::string_view dir, const char* patch_name, ROM& rom) {
    std::string patchloc{dir};
    patchloc += patch_name;
    bool ret = patch(patchloc.c_str(), rom);
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
    snprintf(to_write, sizeof(to_write), "Pixi v%d.%d\t", VERSION_MAJOR, VERSION_PARTIAL);
    std::string romname(rom);
    std::string restorename = romname.substr(0, romname.find_last_of('.')) + ".extmod";

    FILE* res = open(restorename.c_str(), "a+");
    if (res) {
        size_t size = file_size(res);
        auto contents = std::make_unique<char[]>(size + 1);
        size_t read_size = fread(contents.get(), 1, size, res);
        if (size != read_size) {
            io.error("Couldn't fully read file %s, please check file permissions", restorename.c_str());
            return false;
        }
        contents[size] = '\0';
        if (!ends_with(contents.get(), to_write)) {
            fseek(res, 0, SEEK_END);
            fprintf(res, "%s", to_write);
        }
        fclose(res);
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
    return std::equal(first.begin(), first.end(), second.begin(), second.end(),
                      [](char a, char b) { return std::tolower(a) == std::tolower(b); });
}

[[nodiscard]] patchfile create_base_sprite_patch(const std::vector<std::string>& extraDefines, const std::string& dir) {
    std::string escapedDir = escapeDefines(dir);
    std::string escapedAsmdir = escapeDefines(cfg.AsmDir);
    patchfile sprite_patch{TEMP_SPR_FILE};

    const char prelude[] = R"(namespace nested on
warnings push
warnings disable Wrelative_path_used
warnings disable W65816_xx_y_assume_16_bit
incsrc "%ssa1def.asm"
)";
    const char epilogue[] = R"(incsrc "shared.asm"
incsrc "%s_header.asm"
)";
    sprite_patch.fprintf(prelude, escapedAsmdir.c_str());
    addIncScrToFile(sprite_patch, extraDefines);
    sprite_patch.fprintf(epilogue, escapedDir.c_str());
    return sprite_patch;
}

void add_epilogue_to_sprite_patch(patchfile& sprite_patch) {
    const char epilogue[] = R"(incsrc "shared_incsrc.asm"
warnings pull
namespace nested off
)";
    sprite_patch.fprintf(epilogue);
    sprite_patch.close();
}

void add_sprite_to_patch(patchfile& sprite_patch, sprite* spr) {
    std::string escapedAsmfile = escapeDefines(spr->asm_file);
    const char patchstr[] = R"(freecode cleaned
namespace SPRITE_ENTRY_%d
SPRITE_ENTRY_%d:
    incsrc "%s"
namespace off
print "__PIXI_INTERNAL_SPRITE_SEPARATOR__"
)";
    sprite_patch.fprintf(patchstr, spr->number, spr->number, escapedAsmfile.c_str());
}

[[nodiscard]] bool patch_sprite(const std::vector<std::string>& extraDefines, sprite* spr, ROM& rom) {
    std::string escapedDir = escapeDefines(spr->directory);
    std::string escapedAsmfile = escapeDefines(spr->asm_file);
    std::string escapedAsmdir = escapeDefines(cfg.AsmDir);
    patchfile sprite_patch{TEMP_SPR_FILE};
    const char prefix[] = R"(namespace nested on
warnings push
warnings disable Wrelative_path_used
warnings disable W65816_xx_y_assume_16_bit
incsrc "%ssa1def.asm"
)";
    const char postfix[] = R"(incsrc "shared.asm"
incsrc "%s_header.asm"
freecode cleaned
SPRITE_ENTRY_%d:
    incsrc "%s"
incsrc "shared_incsrc.asm"
warnings pull
namespace nested off
)";
    sprite_patch.fprintf(prefix, escapedAsmdir.c_str());
    addIncScrToFile(sprite_patch, extraDefines);
    sprite_patch.fprintf(postfix, escapedDir.c_str(), spr->number, escapedAsmfile.c_str());
    sprite_patch.close();

    if (!patch(sprite_patch, rom))
        return false;

    if (!cfg.SymbolsType.empty()) {
        fs::path symbols_to_file = fs::path{spr->asm_file}.replace_extension(cfg.SymbolsType);
        fs::path symbols_from_file = fs::path{TEMP_SPR_FILE}.replace_extension(cfg.SymbolsType);
        try {
            fs::rename(symbols_from_file, symbols_to_file);
        } catch (const fs::filesystem_error& err) {
            io.error("Trying to rename symbol file of \"%s\" returned \"%s\", aborting insertion\n",
                     spr->asm_file.c_str(), err.what());
            return false;
        }
    }

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

    io.debug("%s\n", spr->asm_file.c_str());
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
                             spr->asm_file.c_str(), required_version, VERSION_PARTIAL);
                    return false;
                }
            } else {
                int ptr = 0;
                auto address = prints[i].substr(ch.name.size());
                trim(address);
                auto err = std::from_chars(address.c_str(), address.c_str() + address.size(), ptr, 16);
                if (err.ec != std::errc{}) {
                    io.error("Invalid pointer at print %s in sprite %s, expected a valid hexadecimal number got \"%s\" "
                             "instead\n",
                             ch.name.data(), spr->asm_file.c_str(), address.c_str());
                    return false;
                } else {
                    ptr_map[ch.name] = ptr;
                }
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
        io.error("Sprite %s had neither INIT nor MAIN defined in its file, insertion has been aborted.",
                 spr->asm_file.c_str());
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
                 spr->table.init.raw(), spr->table.main.raw(), spr->ptrs.carriable.raw(), spr->ptrs.carried.raw(),
                 spr->ptrs.kicked.raw(), spr->ptrs.mouth.raw(), spr->ptrs.goal.raw());
    else if (spr->sprite_type == ListType::Extended)
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n\tCAPE: $%06X"
                 "\n__________________________________\n",
                 spr->table.init.raw(), spr->table.main.raw(), spr->extended_cape_ptr.raw());
    else
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n"
                 "\n__________________________________\n",
                 spr->table.init.raw(), spr->table.main.raw());
    return true;
}

bool fill_single_sprite(sprite* spr, std::span<std::string> prints) {
    using ptr_map_t = std::unordered_map<std::string_view, pointer>;
    using ptr_map_v_t = ptr_map_t::value_type;
    ptr_map_t ptr_map = {
        ptr_map_v_t{"INIT", 0x018021},    ptr_map_v_t{"MAIN", 0x018021},   ptr_map_v_t{"CAPE", 0x000000},
        ptr_map_v_t{"MOUTH", 0x000000},   ptr_map_v_t{"KICKED", 0x000000}, ptr_map_v_t{"CARRIABLE", 0x000000},
        ptr_map_v_t{"CARRIED", 0x000000}, ptr_map_v_t{"GOAL", 0x000000},   ptr_map_v_t{"VERG", 0x000000}};

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

    using namespace std::string_view_literals;
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

    for (int i = 0; i < static_cast<int>(prints.size()); i++) {
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
                             spr->asm_file.c_str(), required_version, VERSION_PARTIAL);
                    return false;
                }
            } else {
                ptr_map[ch.name] = strtol(prints[i].c_str() + ch.name.size(), nullptr, 16);
            }

        } else {
            io.debug("\t%s\n", prints[i].c_str());
        }
    }

    spr->table.init = ptr_map["INIT"];
    spr->table.main = ptr_map["MAIN"];
    if (spr->table.init.is_empty() && spr->table.main.is_empty()) {
        io.error("Sprite %s had neither INIT nor MAIN defined in its file, insertion has been aborted.",
                 spr->asm_file.c_str());
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
                 spr->table.init.raw(), spr->table.main.raw(), spr->ptrs.carriable.raw(), spr->ptrs.carried.raw(),
                 spr->ptrs.kicked.raw(), spr->ptrs.mouth.raw(), spr->ptrs.goal.raw());
    else if (spr->sprite_type == ListType::Extended)
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n\tCAPE: $%06X"
                 "\n__________________________________\n",
                 spr->table.init.raw(), spr->table.main.raw(), spr->extended_cape_ptr.raw());
    else
        io.debug("\tINIT: $%06X\n\tMAIN: $%06X\n"
                 "\n__________________________________\n",
                 spr->table.init.raw(), spr->table.main.raw());

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

    return true;
}

[[nodiscard]] bool patch_sprites_all_in_one(std::vector<std::string>& extraDefines, sprite* sprite_list, int size,
                                            ROM& rom, const std::string& dir) {
    std::vector<sprite*> sprites;
    for (int i = 0; i < size; i++) {
        sprite* spr = sprite_list + i;
        if (spr->asm_file.empty())
            continue;
        auto it = std::find_if(sprites.begin(), sprites.end(),
                               [spr](const sprite* other) { return other->asm_file == spr->asm_file; });
        if (it == sprites.end()) {
            sprites.push_back(spr);
        }
    }

    if (sprites.empty())
        return true;

    patchfile file = create_base_sprite_patch(extraDefines, dir);
    for (sprite* spr : sprites) {
        add_sprite_to_patch(file, spr);
    }
    add_epilogue_to_sprite_patch(file);

    if (!patch(file, rom)) {
        int error_count;
        const errordata* cerrors = asar_geterrors(&error_count);
        std::span errors{cerrors, static_cast<size_t>(error_count)};
        if (std::any_of(errors.begin(), errors.end(), [](const errordata& err) { return err.errid == 5095 /* error_id_macro_redefined */; })) {
            io.error("Macro redefinition errors can mean that two sprites define the same macro. This is "
                     "incompatible with the `--onepatch` command line option. Please attempt insertion without it.");
        }
        return false;
    }
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

    auto it = prints.begin();
    std::unordered_map<std::string_view, std::span<std::string>> sprite_prints{};
    constexpr auto separator = "__PIXI_INTERNAL_SPRITE_SEPARATOR__"sv;
    size_t idx = 0;
    while (it != prints.end()) {
        auto sep = std::find(it, prints.end(), separator);
        if (sep != prints.end()) {
            sprite_prints.insert(std::pair{std::string_view{sprites[idx]->asm_file}, std::span{&*it, &*sep}});
            idx++;
            it = sep + 1;
        } else {
            it = sep;
        }
    }

    if (sprite_prints.size() != sprites.size()) {
        io.error("Internal error: prints size does not match sprites size, please report this to the developers "
                 "of the tool here " GITHUB_ISSUE_LINK);
        return false;
    }

    for (int i = 0; i < size; i++) {
        sprite* spr = sprite_list + i;
        if (spr->asm_file.empty())
            continue;
        if (!fill_single_sprite(spr, sprite_prints.at(spr->asm_file))) {
            return false;
        }
    }

    return true;
}

[[nodiscard]] bool patch_sprites(std::vector<std::string>& extraDefines, sprite* sprite_list, int size, ROM& rom) {
    for (int i = 0; i < size; i++) {
        sprite* spr = sprite_list + i;
        if (spr->asm_file.empty())
            continue;

        bool duplicate = false;
        for (int j = i - 1; j >= 0; j--) {
            if (!sprite_list[j].asm_file.empty()) {
                if (spr->asm_file == sprite_list[j].asm_file) {
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
    if (memcmp(rom.data + rom.snes_to_pc(0x02FFE2), "STSD", 4) == 0) { // already installed load old tables

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
                auto level_table_address = rom.pointer_snes(0x02FFF1).addr();
                if (level_table_address != 0xFFFFFF && level_table_address != 0x000000) {
                    auto cleanup_ptr = [&](pointer ptr, std::string_view comment) {
                        if (auto addr = ptr.addr(); !ptr.is_empty() && (addr != 0x000000) && (addr != 0xFFFFFF)) {
                            clean_patch.fprintf("autoclean $%06X; %s\n", addr.raw_value(), comment.data());
                        }
                    };
                    // these pointers are from the PROT commands in main.asm
                    // this code relies on the order of these commands, so do not change it unless you also change
                    // main.asm
                    // offset of last pointer = "STOP" + 1 + 3 = 8
                    // offset of second to last pointer = "PROT" + 1 + 3 + <offset of last pointer> = 16
                    auto custom_pointers_address = rom.pointer_snes(level_table_address - 8).addr();
                    auto sprite_data_address = rom.pointer_snes(level_table_address - 16).addr();
                    auto verify_pointer = [&rom](snesaddress addr) {
                        constexpr auto base_addr = pointer{}.addr();
                        // this function tries to at least make sure that the pointer
                        // 1 - is not $FFFFFF or $000000, these are obviously nonsensical
                        // 2 - is not the "base pointer", the one that pixi uses to indicate a sprite that's missing a
                        // main/init, that address points to original SMW code. 3 - it is a valid snes address that
                        // points to a valid pc address, otherwise it's not a valid pointer
                        return addr != 0xFFFFFF && addr != 0x000000 && addr != base_addr && rom.snes_to_pc(addr) != -1;
                    };
                    if (!verify_pointer(custom_pointers_address) || !verify_pointer(sprite_data_address)) {
                        io.error("Invalid custom pointers address or sprite data address, aborting cleanup\n");
                        return false;
                    }
                    if (auto custom_pointers_size = rom.get_rats_size(pcaddress{custom_pointers_address, rom});
                        custom_pointers_size.has_value()) {
                        uint16_t block_size = custom_pointers_size.value();
                        constexpr size_t block_multiplier = sizeof(status_pointers) + 1;
                        if (block_size % block_multiplier != 0) {
                            io.error("Custom pointers block size is not a multiple of %d, aborting cleanup\n",
                                     block_multiplier);
                            return false;
                        }
                        auto pc_address = rom.snes_to_pc(custom_pointers_address);
                        for (size_t i = 0; i < block_size / block_multiplier; i++) {
                            auto offset = pc_address + static_cast<int>(i * block_multiplier);
                            auto ptrs = rom.read_struct<status_pointers>(offset);
                            if (verify_pointer(ptrs.carriable))
                                cleanup_ptr(ptrs.carriable, "Per-level custom carriable pointer");
                            if (verify_pointer(ptrs.carried))
                                cleanup_ptr(ptrs.carried, "Per-level custom carried pointer");
                            if (verify_pointer(ptrs.goal))
                                cleanup_ptr(ptrs.goal, "Per-level custom goal pointer");
                            if (verify_pointer(ptrs.kicked))
                                cleanup_ptr(ptrs.kicked, "Per-level custom kicked pointer");
                            if (verify_pointer(ptrs.mouth))
                                cleanup_ptr(ptrs.mouth, "Per-level custom mouth pointer");
                        }
                    }
                    if (auto sprite_data_size = rom.get_rats_size(pcaddress{sprite_data_address, rom});
                        sprite_data_size.has_value()) {
                        uint16_t block_size = sprite_data_size.value();
                        constexpr size_t block_multiplier = sizeof(sprite_table);
                        if (block_size % block_multiplier != 0) {
                            io.error("Custom pointers block size is not a multiple of %d, aborting cleanup\n",
                                     block_multiplier);
                            return false;
                        }
                        auto pc_address = rom.snes_to_pc(sprite_data_address);
                        for (size_t i = 0; i < block_size / block_multiplier; i++) {
                            auto offset = pc_address + static_cast<int>(i * block_multiplier);
                            auto tbl = rom.read_struct<sprite_table>(offset);
                            if (verify_pointer(tbl.init))
                                cleanup_ptr(tbl.init, "Per-level custom init pointer");
                            if (verify_pointer(tbl.main))
                                cleanup_ptr(tbl.main, "Per-level custom main pointer");
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
                            clean_patch.fprintf("autoclean $%06X\n", main_pointer.raw());
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
        auto global_table_address = rom.pointer_snes(0x02FFEE).addr();
        if (rom.pointer_snes(global_table_address).addr() != 0xFFFFFF) {
            for (int table_offset = 0x08; table_offset < limit; table_offset += 0x10) {
                pointer init_pointer = rom.pointer_snes(global_table_address + table_offset);
                if (!init_pointer.is_empty()) {
                    clean_patch.fprintf("autoclean $%06X\n", init_pointer.raw());
                }
                pointer main_pointer = rom.pointer_snes(global_table_address + table_offset + 3);
                if (!main_pointer.is_empty()) {
                    clean_patch.fprintf("autoclean $%06X\n", main_pointer.raw());
                }
            }
        }

        // remove global sprites' custom pointers
        clean_patch.fprintf(";Global sprite custom pointers: \n");
        auto pointer_table_address = rom.pointer_snes(0x02FFFD).addr();
        if (pointer_table_address != 0xFFFFFF && rom.pointer_snes(pointer_table_address).addr() != 0xFFFFFF) {
            for (int table_offset = 0; table_offset < 0x100 * 15; table_offset += 3) {
                pointer ptr = rom.pointer_snes(pointer_table_address + table_offset);
                if (!ptr.is_empty() && ptr.addr() != 0) {
                    clean_patch.fprintf("autoclean $%06X\n", ptr.raw());
                }
            }
        }

        // shared routines
        clean_patch.fprintf("\n\n;Routines:\n");
        for (int i = 0; i < MAX_ROUTINES; i++) {
            auto routine_pointer = rom.pointer_snes(0x03E05C + i * 3).addr();
            if (routine_pointer != 0xFFFFFF) {
                clean_patch.fprintf("autoclean $%06X\n", routine_pointer.raw_value());
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
    } else if (!strncmp((char*)(rom.data + rom.snes_to_pc(rom.pointer_snes(0x02A963 + 1).addr() - 3)), "MDK",
                        3)) { // check for old sprite_tool code. (this is annoying)
        std::string spritetool_clean = std::string{pathname} + "spritetool_clean.asm";
        if (!patch(spritetool_clean.c_str(), rom))
            return false;
        // removes all STAR####MDK tags
        const char* mdk = "MDK"; // sprite tool added "MDK" after the rats tag to find it's insertions...
        int number_of_banks = rom.size / 0x8000;
        for (int i = 0x10; i < number_of_banks; ++i) {
            char* bank = (char*)(rom.unheadered_data() + i * 0x8000);

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
    namespace fs = std::filesystem;

    std::string escapedRoutinepath = escapeDefines(routine_path, R"(\\\!)");
    g_shared_inscrc_patch.fprintf("macro include_once(target, base, offset)\n"
                                  "	if defined(\"<base>\")\n"
                                  "    	if !<base> == 1\n"
                                  "	    	pushpc\n"
                                  "		    if read3(<offset>+$03E05C) != $FFFFFF\n"
                                  "			    <base> = read3(<offset>+$03E05C)\n"
                                  "	    	else\n"
                                  "	    		freecode cleaned\n"
                                  "	    			global #<base>:\n"
                                  "	    			print \"    Routine: <base> inserted at $\",pc\n"
                                  "	    			namespace <base>\n"
                                  "	    			incsrc \"<target>\"\n"
                                  "                   namespace off\n"
                                  "	    		ORG <offset>+$03E05C\n"
                                  "	    			dl <base>\n"
                                  "	    	endif\n"
                                  "	    	pullpc\n"
                                  "    	!<base> #= 2\n"
                                  "    	!pixi_incsrc_again #= 1\n"
                                  "    	endif\n"
                                  "    endif\n"
                                  "endmacro\n"
                                  "macro safe_macro_label_wrapper()\n");
    int routine_count = 0;
    if (!fs::exists(cleanPathTrail(routine_path))) {
        io.error("Couldn't open folder \"%s\" for reading.", routine_path.c_str());
        return false;
    }
    try {
        for (const auto& routine_file : fs::recursive_directory_iterator{routine_path, fs::directory_options::follow_directory_symlink}) {
            if (!routine_file.is_regular_file())
                continue;
            const fs::path& p = routine_file.path();
            if (p.extension() != ".asm")
                continue;
            fs::path rel = p.lexically_relative(routine_path); // lexically relative does not resolve symlinks, which is what we want
            std::string path{rel.generic_string()};
            std::string name{};
            for (const auto& path_part : rel.replace_extension()) {
                name += path_part.generic_string();
            }
            if (routine_count > config.Routines) {
                io.error(
                    "More than %d routines located. Please remove some or change the max number of routines with the "
                    "-nr option. \n",
                    config.Routines);
                return false;
            }
            const char* charName = name.c_str();
            const char* charPath = path.c_str();
            g_shared_patch.fprintf("macro %s()\n"
                                   "\t!%s ?= 1\n"
                                   "\tJSL %s\n"
                                   "endmacro\n",
                                   charName, charName, charName);
            g_shared_inscrc_patch.fprintf("\t%%include_once(\"%s%s\", %s, $%02X)\n", escapedRoutinepath.c_str(),
                                          charPath, charName, routine_count * 3);
            routine_count++;
        }
        g_shared_inscrc_patch.fprintf("endmacro\n\n"
                                      "!pixi_incsrc_again = 1\n"
                                      "while !pixi_incsrc_again != 0\n"
                                      "\t!pixi_incsrc_again #= 0\n"
                                      "\t%%safe_macro_label_wrapper()    ; actually insert wrapped routines\n"
                                      "endwhile\n");
    } catch (const fs::filesystem_error& err) {
        io.error("Trying to read folder \"%s\" returned \"%s\", aborting insertion\n", routine_path.c_str(),
                 err.what());
        return false;
    }
    io.print("%d Shared routines registered in \"%s\"\n", routine_count, routine_path.data());
    g_shared_patch.close();
    g_shared_inscrc_patch.close();
    g_memory_files.push_back(g_shared_patch.vfile());
    g_memory_files.push_back(g_shared_inscrc_patch.vfile());
    return true;
}

[[nodiscard]] bool populate_sprite_list(const Paths& paths,
                                        const std::array<sprite*, FromEnum(ListType::__SIZE__)>& sprite_lists,
                                        std::string_view listPath, const ROM* rom) {
    using namespace std::string_view_literals;
    std::ifstream listStream{listPath.data()};
    if (!listStream) {
        io.error("Could not open list file \"%s\" for reading: %s", listPath.data(), strerror(errno));
        return false;
    }
    unsigned int sprite_id, level;
    int lineno = 0;
    int read_res;
    std::string line;
    ListType type = ListType::Sprite;
    sprite* spr = nullptr;
    std::string cfgname{};
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
            cfgname = line.substr(read_until);
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
            cfgname = line.substr(read_until);
        }

        size_t dot = cfgname.find_last_of('.');
        if (dot == std::string::npos) {
            io.error("Error on list line %d: missing extension on filename %s\n", lineno, cfgname.c_str());
            return false;
        }
        size_t space_after_ext = cfgname.find_first_of(' ', dot);
        std::string_view ext = std::string_view{cfgname}.substr(
            dot + 1, space_after_ext == std::string::npos ? space_after_ext : space_after_ext - dot - 1);

        if (rom != nullptr) {
            if (sprite_id == GOAL_POST_SPRITE_ID && rom->is_exlevel()) {
                // sprite $7B is the goal post
                // in LM versions 2.53 and onwards the extra bits of the goal post are used to determine which exit it
                // triggers therefore custom sprites can't be used in this slot. In fact, in main.asm, there are a few
                // branches that check if $7B and then just return
                io.print(
                    "Warning on list line %d: Sprite number 7B (goal post) in Lunar Magic versions from 2.53 onwards "
                    "uses the extra bits 2 and 3 to activate secret exits, this means that it can't be used as a "
                    "custom sprite slot, it will still be inserted in the ROM but will be ignored at runtime\n",
                    lineno);
            }
        }

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
        std::string fullFileName = std::string{dir} + cfgname.substr(0, space_after_ext);

        if (type != ListType::Sprite) {
            if (ext != "asm" && ext != "ASM") {
                io.error("Error on list line %d: not an asm file\n", lineno, fullFileName.c_str());
                return false;
            }
            if (space_after_ext != std::string::npos) {
                io.error("Error on list line %d: display type not supported for ASM files\n", lineno);
                return false;
            }
            spr->asm_file = std::move(fullFileName);
        } else {
            spr->cfg_file = std::move(fullFileName);
            if (ext == "cfg" || ext == "CFG") {
                spr->displays_in_lm = false;
                if (space_after_ext != std::string::npos) {
                    // may be "display|nodisplay"
                    std::string display = std::string{cfgname}.substr(space_after_ext + 1);
                    trim(display);
                    if (display == "nodisplay"sv) {
                        spr->displays_in_lm = false;
                    } else if (display == "display"sv) {
                        spr->displays_in_lm = true;
                    } else {
                        io.error("Error on list line %d: Unknown display type %s\n", lineno, display.c_str());
                        return false;
                    }
                }
                if (!read_cfg_file(spr)) {
                    io.error("Error on list line %d: Cannot parse CFG file %s.\n", lineno, spr->cfg_file.c_str());
                    return false;
                }
            } else if (ext == "json" || ext == "JSON") {
                if (space_after_ext != std::string::npos) {
                    io.error("Error on list line %d: display type not supported for JSON files\n", lineno);
                    return false;
                }
                if (!read_json_file(spr)) {
                    io.error("Error on list line %d: Cannot parse JSON file %s.\n", lineno, spr->cfg_file.c_str());
                    return false;
                }
                spr->displays_in_lm = true;
            } else {
                io.error("Error on list line %d: Unknown filetype %s\n", lineno, ext.data());
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
    fs::path path{rom.name};
    path.replace_extension(ext);
    std::string spath = path.generic_string();
    FILE* r = open(spath.c_str(), mode);
    return r;
}

void remove(std::string_view dir, const char* file) {
    fs::remove(fs::path{dir} / file);
}

bool check_warnings() {
    if (!warnings.empty() && cfg.warningsEnabled()) {
        io.print("One or more warnings have been detected:\n");
        for (const std::string& warning : warnings) {
            io.print("%s\n", warning.c_str());
        }
        if (!cfg.ScriptMode) {
            io.print("Do you want to continue insertion anyway? [Y/n] (Default is yes):\n");
            char c = io.getc();
            if (tolower(c) == 'n') {
                io.print("Insertion was stopped, press any button to exit...\n");
                io.getc();
                return false;
            }
        }
        else {
            io.print("Script mode is enabled, continuing insertion...\n");
        }
    }
    return true;
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
    g_shared_inscrc_patch.clear();
    g_config_defines.clear();
    patchfile::set_keep(false, false);
    cfg.reset();
}

PIXI_EXPORT int pixi_api_version() {
    return VERSION_FULL;
}

PIXI_EXPORT int pixi_check_api_version(int version_edition, int version_major, int version_minor) {
    return version_edition == VERSION_MAJOR && version_major == VERSION_MINOR && version_minor == VERSION_PATCH;
}

PIXI_EXPORT int pixi_run(int argc, const char** argv, bool skip_first) {
#ifndef PIXI_EXE_BUILD
    pixi_reset();
#endif
    ROM rom;
    MeiMei meimei{};
    // individual lists containing the sprites for the specific sections
    static sprite sprite_list[MAX_SPRITE_COUNT];
    static sprite cluster_list[SPRITE_COUNT];
    static sprite extended_list[SPRITE_COUNT];
    static sprite minor_extended_list[LESS_SPRITE_COUNT];
    static sprite bounce_list[LESS_SPRITE_COUNT];
    static sprite smoke_list[LESS_SPRITE_COUNT];
    static sprite spinningcoin_list[MINOR_SPRITE_COUNT];
    static sprite score_list[MINOR_SPRITE_COUNT];

    std::vector<plugins::plugin> plugin_list{};
    const fs::path plugins_path = fs::current_path() / "plugins";
    if (fs::is_directory(plugins_path)) {
        for (const auto& entry : fs::directory_iterator(plugins_path)) {
            if (entry.is_regular_file() && entry.path().extension() == DYLIB_EXT) {
                plugin_list.emplace_back(entry.path().native());
            }
        }
        for (auto& plugin : plugin_list) {
            if (int code = plugin.load(); code != EXIT_SUCCESS) {
                return EXIT_FAILURE;
            }
        }
    }

    if (plugins::for_each_plugin(plugin_list, &plugins::plugin::check_version, (int)VERSION_FULL) != EXIT_SUCCESS) {
        return EXIT_FAILURE;
    };

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
        nlohmann::json j;
        try {
            std::ifstream settings_file{"pixi_settings.json"};
            if (!settings_file) {
                io.error("pixi_settings.json was detected but it failed to open, please check file permissions\n");
                return EXIT_FAILURE;
            } else {
                settings_file >> j;
            }
        } catch (const nlohmann::json::parse_error& err) {
            // https://json.nlohmann.me/api/basic_json/operator_gtgt/#exceptions
            switch (err.id) {
            case 101:
                io.error("Unexpected token in pixi_settings.json, please make sure that the json file has the correct "
                         "format. "
                         "Error: %s",
                         err.what());
                break;
            case 102:
                io.error(
                    "Unicode conversion failure or surrogate error in pixi_settings.json, please make sure that the "
                    "json file "
                    "has the correct format. Error: %s",
                    err.what());
                break;
            case 103:
                io.error("Unicode conversion failure in  pixi_settings.json, please make sure that the json file has "
                         "the correct "
                         "format. Error: %s",
                         err.what());
                break;
            default:
                io.error("An unexpected json parsing error was encountered in pixi_settings.json, please make sure "
                         "that the json "
                         "file has the correct format. Error: %s",
                         err.what());
                break;
            }
            return EXIT_FAILURE;
        } catch (const std::exception& e) {
            io.error("An unknown error has occurred while parsing pixi_settings.json, please report the issue "
                     "at " GITHUB_ISSUE_LINK " (provide as much info as possible): %s\n",
                     e.what());
            return EXIT_FAILURE;
        }
        if (!optparser.init(j)) {
            io.error("Invalid argument in pixi_settings.json");
            return EXIT_FAILURE;
        }
    } else {
        optparser.init(skip_first ? argc - 1 : argc, skip_first ? argv + 1 : argv);
    }
    optparser.add_version(VERSION_PARTIAL, VERSION_MAJOR);
    optparser.allow_unmatched(1);
    optparser.add_usage_string("pixi <options> [ROM]");
    optparser.add_option("-v", "Print version information", version_requested)
        .add_option("--version", "Print version information", version_requested)
        .add_option("--rom", "ROMFILE",
                    "ROM file, when the --rom is not given, it is assumed to be the first unmatched argument", rom.name)
        .add_option("-d", "Enable debug output", cfg.DebugEnabled)
        .add_option("--debug", "Enable debug output", cfg.DebugEnabled)
        .add_option("--exerel",
                    "Resolve list.txt and ssc/mw2/mwt/s16 paths relative to the executable rather than the ROM",
                    cfg.SearchForFilesInExePath)
        .add_option("-k", "Keep debug files", cfg.KeepFiles)
        .add_option("--symbols", "SYMBOLSTYPE", "Enable writing debugging symbols files in format wla or nocash",
                    cfg.SymbolsType)
        .add_option("-l", "list path", "Specify a custom list file", cfg[PathType::List])
        .add_option("-pl", "Per level sprites - will insert perlevel sprite code", cfg.PerLevel)
        .add_option("-npl", "Disable per level sprites (default), kept for compatibility reasons", argparser::no_value)
        .add_option("-d255spl", "Disable 255 sprites per level support (won't do the 1938 remap)",
                    cfg.Disable255Sprites)
        .add_option("-w", "[Deprecated and unused] Enable asar warnings check, recommended to use when developing sprites", cfg.Warnings)
        .add_option("-wno", "Disable asar warnings check, only present for backwards compatibility, not recommended", cfg.NoWarnings)
        .add_option("--script-mode", "Disable all user confirmation prompts", cfg.ScriptMode)
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
        .add_option("-meimei-a", "Enables always remap sprite data", meimei.AlwaysRemap())
        .add_option("-meimei-k", "Enables keep temp patches files", meimei.KeepTemp())
        .add_option("-meimei-d", "Enables debug for MeiMei patches", meimei.Debug())
        .add_option("--onepatch", "Applies all sprites into a single big patch", cfg.AllSpritesOnePatch)
        .add_option("--stdincludes", "INCLUDEPATH", "Specify a text file with a list of search paths for asar",
                    cfg.AsarStdIncludes)
        .add_option("--stddefines", "DEFINEPATH", "Specify a text file with a list of defines for asar",
                    cfg.AsarStdDefines)
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
    if (cfg.Disable255Sprites) {
        io.error("Disabling the 255 sprites per level patch is not supported since 1.41 because the RAM recovered by "
                 "moving the table from 1938 is used by misc tables for minor sprite types");
        return EXIT_FAILURE;
    }
    if (argc < 2 && !cfg.ScriptMode) {
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
    if (cfg.SymbolsType != "" && cfg.SymbolsType != "wla" && cfg.SymbolsType != "nocash") {
        io.error("Invalid --symbols format. Supported formats are wla or nocash");
        return EXIT_FAILURE;
    }

    // DEV_BUILD means either debug build or CI build.
    if constexpr (PIXI_DEV_BUILD) {
        io.print("Pixi development version %d.%d - %s\n", VERSION_MAJOR, VERSION_PARTIAL, VERSION_DEBUG);
    } else if (version_requested) {
        const char message[]{"Pixi version %d.%d\n"
                             "Originally developed in 2017 by JackTheSpades\n"
                             "Maintained by RPGHacker (2018), Tattletale (2018-2020)\n"
                             "Currently maintained by Atari2.0 (2020-2025)\n"};
        io.print(message, VERSION_MAJOR, VERSION_PARTIAL);
        return EXIT_SUCCESS;
    }
#ifdef ASAR_USE_DLL
    AsarHandler asar_handler{};
    if (!asar_handler.ok()) {
        io.error(
            "Error: Asar library is missing or couldn't be initialized, please redownload the tool or add the dll.\n");
        return EXIT_FAILURE;
    }
#endif

#ifdef ON_WINDOWS
    if (!lm_handle.empty()) {
        window_handle = (HWND)std::stoull(lm_handle, nullptr, 16);
        verification_code = (uint16_t)(std::stoi(lm_handle.substr(lm_handle.find_first_of(':') + 1), 0, 16));
    }
#endif

    patchfile::set_keep(cfg.KeepFiles, meimei.KeepTemp());
    versionflag[1] = (cfg.PerLevel ? 1 : 0);

    if (plugins::for_each_plugin(plugin_list, &plugins::plugin::before_patching) != EXIT_SUCCESS) {
        return EXIT_FAILURE;
    };

    //------------------------------------------------------------------------------------------
    // Get ROM name if none has been passed yet.
    //------------------------------------------------------------------------------------------

    if (optparser.unmatched().empty() && rom.name.empty()) {
        if (cfg.ScriptMode) {
            io.error("A ROM file must be passed as an argument in script mode\n");
            return EXIT_FAILURE;
        }
        io.print("Enter a ROM file name, or drag and drop the ROM here: ");
        char ROM_name[FILENAME_MAX];
        if (auto readlen = libconsole::read(ROM_name, FILENAME_MAX, libconsole::handle::in); readlen.has_value()) {
            size_t length = readlen.value();
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
            if (!rom.open(std::string{ROM_name, length}))
                return EXIT_FAILURE;
        } else {
            // failed to libconsole::read for some reason
            io.error("Failed to read ROM name from console\n");
            return EXIT_FAILURE;
        }
    } else if (rom.name.empty()) {
        if (!rom.open(optparser.unmatched().front()))
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
        io.error("This is version %d.%d\n", VERSION_MAJOR, VERSION_PARTIAL);
        io.error("Please get a newer version.");
        rom.close();
        return EXIT_FAILURE;
    }

    auto lm_edit_ptr = rom.pointer_snes(0x06F624); // thanks p4plus2
    if (lm_edit_ptr.addr() == 0xFFFFFF) {
        io.print(
            "You're inserting Pixi without having modified a level in Lunar Magic, this will cause bugs\nDo you "
            "want to abort insertion now [y/n]?\nIf you choose 'n', to fix the bugs just reapply Pixi after having "
            "modified a level\n");
        if (!cfg.ScriptMode) {
            char c = io.getc();
            if (tolower(c) == 'y') {
                rom.close();
                io.error("Insertion was stopped, press any button to exit...\n");
                io.getc();
                return EXIT_FAILURE;
            }
            fflush(stdin); // uff
        }
        else {
            io.print("Script mode, defaulting to yes\n");
            io.error("Insertion was stopped\n");
            return EXIT_FAILURE;
        }
    }

    unsigned char vram_jump = rom.data[rom.snes_to_pc(0x00F6E4)];
    if (vram_jump != 0x5C) {
        io.error("You haven't installed the VRAM optimization patch in Lunar Magic, this will cause many features of "
                 "Pixi to work incorrectly, insertion was aborted...\n");
        if (!cfg.ScriptMode) {
            io.getc();
        }
        return EXIT_FAILURE;
    }

    // Initialize MeiMei
    if (!cfg.DisableMeiMei) {
        if (!meimei.initialize(rom.name.data()))
            return EXIT_FAILURE;
    }

    //------------------------------------------------------------------------------------------
    // set path for directories relative to pixi or rom, not working dir.
    //------------------------------------------------------------------------------------------

    for (size_t i = 0; i < FromEnum(PathType::__SIZE__); i++) {
        if (i == FromEnum(PathType::List) && !cfg.SearchForFilesInExePath)
            set_paths_relative_to(cfg[ToEnum<PathType>(i)], rom.name.data());
        else
            set_paths_relative_to(cfg[ToEnum<PathType>(i)], argv[0]);
#ifdef DEBUGMSG
        debug_print("paths[%d] = %s\n", i, cfg.m_Paths[i].c_str());
#endif
    }
    set_paths_relative_to(cfg.AsarStdIncludes, argv[0]);
    set_paths_relative_to(cfg.AsarStdDefines, argv[0]);
#ifdef DEBUGMSG
    debug_print("asar std includes = %s\n", cfg.AsarStdIncludes.c_str());
    debug_print("asar std defines = %s\n", cfg.AsarStdDefines.c_str());
#endif

    cfg.AsmDir = cfg[PathType::Asm];
    cfg.AsmDirPath = cleanPathTrail(cfg.AsmDir);

    for (size_t i = 0; i < FromEnum(ExtType::__SIZE__); i++) {
        if (cfg.SearchForFilesInExePath)
            set_paths_relative_to(cfg[ToEnum<ExtType>(i)], argv[0]);
        else
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
    if (!populate_sprite_list(cfg.GetPaths(), sprites_list_list, cfg[PathType::List], &rom))
        return EXIT_FAILURE;

    if (!clean_hack(rom, cfg[PathType::Asm]))
        return EXIT_FAILURE;

    if (!create_shared_patch(cfg[PathType::Routines], cfg))
        return EXIT_FAILURE;

    int normal_sprites_size = cfg.PerLevel ? MAX_SPRITE_COUNT : 0x100;

    if (cfg.AllSpritesOnePatch) {
        {
            PatchTimer sprites{cfg[PathType::Sprites]};
            if (!patch_sprites_all_in_one(extraDefines, sprite_list, normal_sprites_size, rom, cfg[PathType::Sprites]))
                return EXIT_FAILURE;
        }
        for (const auto& [type, size] : sprite_sizes) {
            {
                PatchTimer other{cfg[map_list_to_path[FromEnum(type)]]};
                if (!patch_sprites_all_in_one(extraDefines, sprites_list_list[FromEnum(type)], static_cast<int>(size),
                                              rom, cfg[map_list_to_path[FromEnum(type)]]))
                    return EXIT_FAILURE;
            }
        }
    } else {
        {
            PatchTimer sprites{cfg[PathType::Sprites]};
            if (!patch_sprites(extraDefines, sprite_list, normal_sprites_size, rom))
                return EXIT_FAILURE;
        }
        for (const auto& [type, size] : sprite_sizes) {
            {
                PatchTimer other{cfg[map_list_to_path[FromEnum(type)]]};
                if (!patch_sprites(extraDefines, sprites_list_list[FromEnum(type)], static_cast<int>(size), rom))
                    return EXIT_FAILURE;
            }
        }
    }

    if (!check_warnings())
        return EXIT_FAILURE;

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
                auto mw2_data = std::make_unique<unsigned char[]>(fs_size);
                size_t read_size = fread(mw2_data.get(), 1, fs_size, fp);
                if (read_size != fs_size) {
                    fclose(fp);
                    io.error("Couldn't fully read file %s, please check file permissions", cfg[ExtType::Mw2].c_str());
                    return EXIT_FAILURE;
                }
                fwrite(mw2_data.get(), 1, fs_size, mw2);
            }
            fclose(fp);
        } else {
            fputc(0x00, mw2); // binary data starts with 0x00
        }

        if (!cfg[ExtType::S16].empty())
            read_map16(map, cfg[ExtType::S16].c_str());

        if (!generate_lm_data(sprite_list, map, extra_bytes, ssc, mwt, mw2, s16, cfg.PerLevel))
            return EXIT_FAILURE;

        binfiles.push_back(write_all(extra_bytes, asm_path, "_customsize.bin"));
        // close all the files.
        fclose(s16);
        fclose(ssc);
        fclose(mwt);
        fclose(mw2);
    } else {
        if (!generate_lm_data_ex_bytes_only(sprite_list, extra_bytes, cfg.PerLevel))
            return EXIT_FAILURE;

        binfiles.push_back(write_all(extra_bytes, asm_path, "_customsize.bin"));
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

    if (!check_warnings())
        return EXIT_FAILURE;

    // patch(paths[ASM], "asm/overworld.asm", rom);

    //------------------------------------------------------------------------------------------
    // clean up (if necessary)
    //------------------------------------------------------------------------------------------

    io.print("\nAll sprites applied successfully!\n");

    if (!cfg.ExtModDisabled)
        if (!create_lm_restore(rom.name.data()))
            return EXIT_FAILURE;
    rom.close();
    int retval = 0;
    if (!cfg.DisableMeiMei) {
        meimei.configureSa1Def(cfg.AsmDirPath + "/sa1def.asm");
        retval = meimei.run();
    }

    if (!check_warnings())
        return EXIT_FAILURE;

    if (plugins::for_each_plugin(plugin_list, &plugins::plugin::after_patching) != EXIT_SUCCESS) {
        return EXIT_FAILURE;
    };

#ifdef ON_WINDOWS
    if (!lm_handle.empty()) {
        uint32_t IParam = (verification_code << 16) + 2; // reload rom
        PostMessage(window_handle, 0xBECB, 0, IParam);
    }
#endif
    return retval;
}
