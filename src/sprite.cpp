#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <exception>
#include <fstream>
#include <iostream>
#include <iterator>
#include <list>
#include <map>
#include <sstream>

#include "asar/asardll.h"
#include "cfg.h"
#include "file_io.h"
#include "json.h"
#include "map16.h"
#include "paths.h"
#include "structs.h"

#include "MeiMei/MeiMei.h"

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
#include <windows.h>
#define ON_WINDOWS
#endif

#define ROUTINES 0
#define SPRITES 1
#define GENERATORS 2
#define SHOOTERS 3
#define LIST 4
#define ASM 5

#define EXTENDED 6
#define CLUSTER 7
#define OVERWORLD 8

#define EXT_SSC 0
#define EXT_MWT 1
#define EXT_MW2 2
#define EXT_S16 3

#define INIT_PTR 0x01817D // snes address of default init pointers
#define MAIN_PTR 0x0185CC // guess what?

#define TEMP_SPR_FILE "spr_temp.asm"
#define SPRITE_COUNT 0x80 // count for other sprites like cluster, ow, extended

// version 1.xx
const char VERSION = 0x32;
bool PER_LEVEL = false;
bool DISABLE_255_SPRITE_PER_LEVEL = false;
const char *ASM_DIR = nullptr;
unsigned char PLS_LEVEL_PTRS[0x400];
unsigned char PLS_SPRITE_PTRS[0x4000];
int PLS_SPRITE_PTRS_ADDR = 0;
unsigned char PLS_DATA[0x8000];
unsigned char PLS_POINTERS[0x8000];
// index into both PLS_DATA and PLS_POINTERS
int PLS_DATA_ADDR = 0;
int DEFAULT_ROUTINES = 100;
int MAX_ROUTINES = 310;

std::string ASM_DIR_PATH;
bool disableMeiMei = false;
std::vector<std::string> warnings{};

void double_click_exit() {
    getc(stdin); // Pause before exit
}

template <typename T> T *from_table(T *table, int level, int number) {
    if (!PER_LEVEL)
        return table + number;

    if (level > 0x200 || number > 0xFF)
        return nullptr;
    if (level == 0x200)
        return table + (0x2000 + number);
    else if (number >= 0xB0 && number < 0xC0)
        return table + ((level * 0x10) + (number - 0xB0));
    return nullptr;
}

bool patch(const char *patch_name_rel, ROM &rom) {
    std::string patch_path = std::filesystem::absolute(patch_name_rel).generic_string();
    if (!asar_patch(patch_path.c_str(), (char *)rom.real_data, MAX_ROM_SIZE, &rom.size)) {
#ifdef DEBUGMSG
        debug_print("Failure. Try fetch errors:\n");
#endif
        int error_count;
        const errordata *errors = asar_geterrors(&error_count);
        printf("An error has been detected:\n");
        for (int i = 0; i < error_count; i++)
            printf("%s\n", errors[i].fullerrdata);
        exit(-1);
    }
    int warn_count = 0;
    const errordata *loc_warnings = asar_getwarnings(&warn_count);
    for (int i = 0; i < warn_count; i++)
        warnings.push_back(std::string(loc_warnings[i].fullerrdata));
#ifdef DEBUGMSG
    debug_print("Success\n");
#endif
    return true;
}
bool patch(const char *dir, const char *patch_name, ROM &rom) {
    char *path = new char[strlen(dir) + strlen(patch_name) + 1];
    path[0] = 0;
    strcat(path, dir);
    strcat(path, patch_name);
    bool ret = patch(path, rom);
    delete[] path;
    return ret;
}

void addIncScrToFile(FILE *file, const std::list<std::string> &toInclude) {
    for (std::string const &incPath : toInclude) {
        fprintf(file, "incsrc \"%s\"\n", incPath.c_str());
    }
}

FILE *get_debug_output(int argc, char *argv[], int *i) {

    if (!strcmp(argv[(*i) + 1], "-out") && (*i) < argc - 3) {
        const std::string &name = argv[(*i) + 2];
        (*i) += 2;
        if (name.find(".smc") != std::string::npos ||
            name.find("-") == 0) { // failsafe in case the user forgets to specify the debug output file (we check if
                                   // it's a rom or another cmd line option)
            (*i)--; // fallback to stdout and decrement i to keep reading the rest of the cmd line options
            printf("Output debug file specified was invalid or missing, printing to screen...\n");
            return stdout;
        } else {
            FILE *fp = fopen(name.c_str(), "w"); // try opening the file, in case of failure we just fallback to stdout
            if (fp == nullptr) {
                printf("Couldn't open or create the output file, printing to screen...\n");
                return stdout;
            } else {
                return fp; // everything went smoothly, return proper file handler
            }
        }
    } else {
        return stdout; // -out wasn't used, just default to stdout
    }
}

bool ends_with(const char *str, const char *suffix) {
    if (str == nullptr || suffix == nullptr)
        return false;

    size_t str_len = strlen(str);
    size_t suffix_len = strlen(suffix);

    if (suffix_len > str_len)
        return false;

    return 0 == strncmp(str + str_len - suffix_len, suffix, suffix_len);
}

void create_lm_restore(const char *rom) {
    char to_write[50];
    sprintf(to_write, "Pixi v1.%02X\t", VERSION);
    std::string romname(rom);
    std::string restorename = romname.substr(0, romname.find_last_of('.')) + ".extmod";

    FILE *res = fopen(restorename.c_str(), "a+");
    if (res) {
        size_t size = file_size(res);
        char *contents = new char[size + 1];
        size_t read_size = fread(contents, 1, size, res);
        if (size != read_size)
            error("Couldn\'t fully read file %s, please check file permissions", restorename.c_str());
        contents[size] = '\0';
        if (!ends_with(contents, to_write)) {
            fseek(res, 0, SEEK_END);
            fprintf(res, "%s", to_write);
        }
        fclose(res);
        delete[] contents;
    } else {
        error("Couldn't open restore file for writing (%s)\n", restorename.c_str());
    }
}

std::string escapeDefines(const std::string &path, const char *repl = "\\!") {
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

void patch_sprite(const std::list<std::string> &extraDefines, sprite *spr, ROM &rom, FILE *output) {
    std::string escapedDir = escapeDefines(spr->directory);
    std::string escapedAsmfile = escapeDefines(spr->asm_file);
    std::string escapedAsmdir = escapeDefines(ASM_DIR);
    FILE *sprite_patch = open(TEMP_SPR_FILE, "w");
    fprintf(sprite_patch, "namespace nested on\n");
    fprintf(sprite_patch, "incsrc \"%ssa1def.asm\"\n", escapedAsmdir.c_str());
    addIncScrToFile(sprite_patch, extraDefines);
    fprintf(sprite_patch, "incsrc \"shared.asm\"\n");
    fprintf(sprite_patch, "incsrc \"%s_header.asm\"\n", escapedDir.c_str());
    fprintf(sprite_patch, "freecode cleaned\n");
    fprintf(sprite_patch, "warnings push\n");
    fprintf(sprite_patch, "warnings disable w1005\n");
    fprintf(sprite_patch, "SPRITE_ENTRY_%d:\n", spr->number);
    fprintf(sprite_patch, "\tincsrc \"%s\"\n", escapedAsmfile.c_str());
    fprintf(sprite_patch, "warnings pull\n");
    fprintf(sprite_patch, "namespace nested off\n");
    fclose(sprite_patch);

    patch(TEMP_SPR_FILE, rom);
    std::map<std::string, int> ptr_map = {
        std::pair<std::string, int>("init", 0x018021),      std::pair<std::string, int>("main", 0x018021),
        std::pair<std::string, int>("cape", 0x000000),      std::pair<std::string, int>("mouth", 0x000000),
        std::pair<std::string, int>("kicked", 0x000000), // null pointers
        std::pair<std::string, int>("carriable", 0x000000), std::pair<std::string, int>("carried", 0x000000),
        std::pair<std::string, int>("goal", 0x000000)};
    int print_count = 0;
    const char *const *asar_prints = asar_getprints(&print_count);
    char **prints = new char *[print_count];
    const char **og_ptrs = new const char *[print_count];

    for (int i = 0; i < print_count; i++) { // trim prints since now we can't deal with starting spaces
        prints[i] = new char[strlen(asar_prints[i]) + 1];
        strcpy(prints[i], asar_prints[i]);
        og_ptrs[i] = prints[i]; // assign pointer before moving it, this way we can actually free it, prevents leaks
        prints[i] = trim(prints[i]);
    }

    if (output)
        fprintf(output, "%s\n", spr->asm_file);
    if (print_count > 2 && output)
        fprintf(output, "Prints:\n");

    for (int i = 0; i < print_count; i++) {
        if (!strncmp(prints[i], "INIT", 4))
            ptr_map["init"] = strtol(prints[i] + 4, NULL, 16);
        else if (!strncmp(prints[i], "MAIN", 4))
            ptr_map["main"] = strtol(prints[i] + 4, NULL, 16);
        else if (!strncmp(prints[i], "CAPE", 4) && spr->sprite_type == 1)
            ptr_map["cape"] = strtol(prints[i] + 4, NULL, 16);
        else if (!strncmp(prints[i], "CARRIABLE", 9) && spr->sprite_type == 0)
            ptr_map["carriable"] = strtol(prints[i] + 9, NULL, 16);
        else if (!strncmp(prints[i], "CARRIED", 7) && spr->sprite_type == 0)
            ptr_map["carried"] = strtol(prints[i] + 7, NULL, 16);
        else if (!strncmp(prints[i], "KICKED", 6) && spr->sprite_type == 0)
            ptr_map["kicked"] = strtol(prints[i] + 6, NULL, 16);
        else if (!strncmp(prints[i], "MOUTH", 5) && spr->sprite_type == 0)
            ptr_map["mouth"] = strtol(prints[i] + 5, NULL, 16);
        else if (!strncmp(prints[i], "GOAL", 4) && spr->sprite_type == 0)
            ptr_map["goal"] = strtol(prints[i] + 4, NULL, 16);
        else if (!strncmp(prints[i], "VERG", 4)) {
            if (VERSION < strtol(prints[i] + 4, NULL, 16)) {
                printf("Version Guard failed on %s.\n", spr->asm_file);
                exit(-1);
            }
        } else if (output) {
            fprintf(output, "\t%s\n", prints[i]);
        }
    }
    set_pointer(&spr->table.init, ptr_map["init"]);
    set_pointer(&spr->table.main, ptr_map["main"]);
    if (spr->table.init.is_empty() && spr->table.main.is_empty()) {
        error("Sprite %s had neither INIT nor MAIN defined in its file, insertion has been aborted.", spr->asm_file);
    }
    if (spr->sprite_type == 1) {
        set_pointer(&spr->extended_cape_ptr, ptr_map["cape"]);
    } else if (spr->sprite_type == 0) {
        set_pointer(&spr->ptrs.carried, ptr_map["carried"]);
        set_pointer(&spr->ptrs.carriable, ptr_map["carriable"]);
        set_pointer(&spr->ptrs.kicked, ptr_map["kicked"]);
        set_pointer(&spr->ptrs.mouth, ptr_map["mouth"]);
        set_pointer(&spr->ptrs.goal, ptr_map["goal"]);
    }
    if (output) {
        if (spr->sprite_type == 0)
            fprintf(output,
                    "\tINIT: $%06X\n\tMAIN: $%06X\n"
                    "\tCARRIABLE: $%06X\n\tCARRIED: $%06X\n\tKICKED: $%06X\n"
                    "\tMOUTH: $%06X\n\tGOAL: $%06X"
                    "\n__________________________________\n",
                    spr->table.init.addr(), spr->table.main.addr(), spr->ptrs.carriable.addr(),
                    spr->ptrs.carried.addr(), spr->ptrs.kicked.addr(), spr->ptrs.mouth.addr(), spr->ptrs.goal.addr());
        else if (spr->sprite_type == 1)
            fprintf(output,
                    "\tINIT: $%06X\n\tMAIN: $%06X\n\tCAPE: $%06X"
                    "\n__________________________________\n",
                    spr->table.init.addr(), spr->table.main.addr(), spr->extended_cape_ptr.addr());
        else
            fprintf(output,
                    "\tINIT: $%06X\n\tMAIN: $%06X\n"
                    "\n__________________________________\n",
                    spr->table.init.addr(), spr->table.main.addr());
    }
    for (int i = 0; i < print_count; i++)
        delete[] og_ptrs[i];
    delete[] og_ptrs;
    delete[] prints;
}

void patch_sprites(std::list<std::string> &extraDefines, sprite *sprite_list, int size, ROM &rom, FILE *output) {
    for (int i = 0; i < size; i++) {
        sprite *spr = sprite_list + i;
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

        if (!duplicate)
            patch_sprite(extraDefines, spr, rom, output);

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

            if (PLS_DATA_ADDR >= 0x8000)
                error("Too many Per-Level sprites.  Please remove some.\n", "");

            PLS_SPRITE_PTRS[pls_lv_addr] = (unsigned char)(PLS_DATA_ADDR + 1);
            PLS_SPRITE_PTRS[pls_lv_addr + 1] = (unsigned char)((PLS_DATA_ADDR + 1) >> 8);

            memcpy(PLS_DATA + PLS_DATA_ADDR, &spr->table, 0x10);
            memcpy(PLS_POINTERS + PLS_DATA_ADDR, &spr->ptrs, 15);
            PLS_POINTERS[PLS_DATA_ADDR + 0x0F] = 0xFF;
            PLS_DATA_ADDR += 0x10;
        }
    }
}

void clean_hack(ROM &rom, const char *pathname) {
    if (!strncmp((char *)rom.data + rom.snes_to_pc(0x02FFE2), "STSD", 4)) { // already installed load old tables

        char *path = new char[strlen(ASM_DIR) + strlen("_cleanup.asm") + 1];
        path[0] = 0;
        strcat(path, ASM_DIR);
        strcat(path, "_cleanup.asm");
        FILE *clean_patch = open(path, "w");

        int version = rom.data[rom.snes_to_pc(0x02FFE6)];
        int flags = rom.data[rom.snes_to_pc(0x02FFE7)];

        bool per_level_sprites_inserted = ((flags & 0x01) == 1) || (version < 2);

        // bit 0 = per level sprites inserted
        if (per_level_sprites_inserted) {
            // remove per level sprites
            // version 1.30+
            if (version >= 30) {
                fprintf(clean_patch, ";Per-Level sprites\n");
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
                                // fprintf(clean_patch, ";Encountered pointer to 0xFFFFFF, assuming there to be no
                                // sprites to clean!\n");
                                continue;
                            }
                            if (!main_pointer.is_empty()) {
                                fprintf(clean_patch, "autoclean $%06X\t;%03X:%02X\n", main_pointer.addr(), level >> 1,
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
                    fprintf(clean_patch, ";Per Level sprites for levels %03X - %03X\n", (bank * 0x80),
                            ((bank + 1) * 0x80) - 1);
                    for (int table_offset = 0x0B; table_offset < 0x8000; table_offset += 0x10) {
                        pointer main_pointer = rom.pointer_snes(level_table_address + table_offset);
                        if (main_pointer.addr() == 0xFFFFFF) {
                            fprintf(clean_patch,
                                    ";Encountered pointer to 0xFFFFFF, assuming there to be no sprites to clean!\n");
                            break;
                        }
                        if (!main_pointer.is_empty()) {
                            fprintf(clean_patch, "autoclean $%06X\n", main_pointer.addr());
                        }
                    }
                    fprintf(clean_patch, "\n");
                }
            }
        }

        // if per level sprites are inserted, we only have 0xF00 bytes of normal sprites
        // due to 10 bytes per sprite and B0-BF not being in the table.
        // but if version is 1.30 or higher, we have 0x1000 bytes.
        const int limit = version >= 30 ? 0x1000 : (per_level_sprites_inserted ? 0xF00 : 0x1000);

        // remove global sprites
        fprintf(clean_patch, ";Global sprites: \n");
        int global_table_address = rom.pointer_snes(0x02FFEE).addr();
        if (rom.pointer_snes(global_table_address).addr() != 0xFFFFFF) {
            for (int table_offset = 0x08; table_offset < limit; table_offset += 0x10) {
                pointer init_pointer = rom.pointer_snes(global_table_address + table_offset);
                if (!init_pointer.is_empty()) {
                    fprintf(clean_patch, "autoclean $%06X\n", init_pointer.addr());
                }
                pointer main_pointer = rom.pointer_snes(global_table_address + table_offset + 3);
                if (!main_pointer.is_empty()) {
                    fprintf(clean_patch, "autoclean $%06X\n", main_pointer.addr());
                }
            }
        }

        // remove global sprites' custom pointers
        fprintf(clean_patch, ";Global sprite custom pointers: \n");
        int pointer_table_address = rom.pointer_snes(0x02FFFD).addr();
        if (pointer_table_address != 0xFFFFFF && rom.pointer_snes(pointer_table_address).addr() != 0xFFFFFF) {
            for (int table_offset = 0; table_offset < 0x100 * 15; table_offset += 3) {
                pointer ptr = rom.pointer_snes(pointer_table_address + table_offset);
                if (!ptr.is_empty() && ptr.addr() != 0) {
                    fprintf(clean_patch, "autoclean $%06X\n", ptr.addr());
                }
            }
        }

        // shared routines
        fprintf(clean_patch, "\n\n;Routines:\n");
        for (int i = 0; i < 100; i++) {
            int routine_pointer = rom.pointer_snes(0x03E05C + i * 3).addr();
            if (routine_pointer != 0xFFFFFF) {
                fprintf(clean_patch, "autoclean $%06X\n", routine_pointer);
                fprintf(clean_patch, "\torg $%06X\n", 0x03E05C + i * 3);
                fprintf(clean_patch, "\tdl $FFFFFF\n");
            }
        }

        // Version 1.01 stuff:
        if (version >= 1) {

            // remove cluster sprites
            fprintf(clean_patch, "\n\n;Cluster:\n");
            int cluster_table = rom.pointer_snes(0x00A68A).addr();
            if (cluster_table != 0x9C1498) // check with default/uninserted address
                for (int i = 0; i < SPRITE_COUNT; i++) {
                    pointer cluster_pointer = rom.pointer_snes(cluster_table + 3 * i);
                    if (!cluster_pointer.is_empty())
                        fprintf(clean_patch, "autoclean $%06X\n", cluster_pointer.addr());
                }

            // remove extended sprites
            fprintf(clean_patch, "\n\n;Extended:\n");
            int extended_table = rom.pointer_snes(0x029B1F).addr();
            if (extended_table != 0x176FBC) // check with default/uninserted address
                for (int i = 0; i < SPRITE_COUNT; i++) {
                    pointer extended_pointer = rom.pointer_snes(extended_table + 3 * i);
                    if (!extended_pointer.is_empty())
                        fprintf(clean_patch, "autoclean $%06X\n", extended_pointer.addr());
                }

            // remove overworld sprites
            // fprintf(clean_patch, "\n\n;Overworld:\n");
            // int ow_table = rom.pointer_snes(0x048633).addr();
            // for(int i = 0; i < SPRITE_COUNT; i++) {
            // pointer ow_pointer = rom.pointer_snes(ow_table + 3 * i);
            // if(!ow_pointer.is_empty())
            // fprintf(clean_patch, "autoclean $%06X\n", ow_pointer.addr());
            // }
        }

        // everything else is being cleaned by the main patch itself.
        fclose(clean_patch);
        patch(path, rom);
        delete[] path;
    } else if (!strncmp((char *)rom.data + rom.snes_to_pc(rom.pointer_snes(0x02A963 + 1).addr() - 3), "MDK",
                        3)) { // check for old sprite_tool code. (this is annoying)
        patch((std::string(pathname) + "spritetool_clean.asm").c_str(), rom);
        // removes all STAR####MDK tags
        const char *mdk = "MDK"; // sprite tool added "MDK" after the rats tag to find it's insertions...
        int number_of_banks = rom.size / 0x8000;
        for (int i = 0x10; i < number_of_banks; ++i) {
            char *bank = (char *)(rom.real_data + i * 0x8000);

            int bank_offset = 8;
            while (1) {
                // look for data inserted on previous uses

                int offset = bank_offset;
                unsigned int j = 0;
                for (; offset < 0x8000; offset++) {
                    if (bank[offset] != mdk[j++])
                        j = 0;
                    if (j == strlen(mdk)) {
                        offset -= strlen(mdk) - 1; // set pointer to start of mdk string
                        break;
                    }
                }

                if (offset >= 0x8000)
                    break;
                bank_offset = offset + strlen(mdk);
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
                    printf("size: %04X, inverted: %04X\n", size - 8, inverted);
                    printf("Bad sprite_tool RATS tag detected at $%06X / 0x%05X. Remove anyway (y/n) ",
                           rom.pc_to_snes(pc), pc);
                    int read_values = scanf("%c", &answer);
                    if ((answer != 'Y' && answer != 'y') || read_values != 1)
                        continue;
                }

                // printf("Clear %04X bytes from $%06X / 0x%05X.\n", size, rom.pc_to_snes(pc), pc);
                memset(bank + offset - 8, 0, size);
                bank_offset = offset - 8 + size;
            }
        }
    }
}

bool areConfigFlagsToggled() {
    return PER_LEVEL == true || DISABLE_255_SPRITE_PER_LEVEL == true || true; // for now config is recreated on all runs
}

void create_config_file(const std::string path) {
    if (areConfigFlagsToggled()) {
        FILE *config = open(path.c_str(), "w");
        fprintf(config, "!PerLevel = %d\n", (int)PER_LEVEL);
        fprintf(config, "!Disable255SpritesPerLevel = %d", (int)DISABLE_255_SPRITE_PER_LEVEL);
        fclose(config);
    }
}

std::list<std::string> listExtraAsm(const std::string path) {
    std::list<std::string> extraDefines;
    if (!std::filesystem::exists(cleanPathTrailFromString(path))) {
        return extraDefines;
    }
    try {
        for (auto &file : std::filesystem::directory_iterator(path)) {
            std::string path = file.path().generic_string();
            if (nameEndWithAsmExtension(path)) {
                extraDefines.push_back(path);
            }
        }
    } catch (const std::filesystem::filesystem_error &err) {
        error("Trying to read folder \"%s\" returned \"%s\", aborting insertion\n", path.c_str(), err.what());
    }
    return extraDefines;
}

std::string cleanPathTrail(const char *path) {
    return cleanPathTrailFromString(std::string(path));
}

void create_shared_patch(const char *routine_path) {
    std::string escapedRoutinepath = escapeDefines(routine_path, R"(\\\!)");
    FILE *shared_patch = open("shared.asm", "w");
    fprintf(shared_patch, "macro include_once(target, base, offset)\n"
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
        error("Couldn't open folder \"%s\" for reading.", routine_path);
    }
    try {
        for (const auto &routine_file : std::filesystem::directory_iterator(routine_path)) {
            std::string name(routine_file.path().filename().generic_string());
            if (routine_count > DEFAULT_ROUTINES) {
                error("More than 100 routines located. Please remove some. \n", "");
            }
            if (nameEndWithAsmExtension(name)) {
                name = name.substr(0, name.length() - 4);
                const char *charName = name.c_str();
                fprintf(shared_patch,
                        "!%s = 0\n"
                        "macro %s()\n"
                        "\t%%include_once(\"%s%s.asm\", %s, $%.2X)\n"
                        "\tJSL %s\n"
                        "endmacro\n",
                        charName, charName, escapedRoutinepath.c_str(), charName, charName, routine_count * 3,
                        charName);
                routine_count++;
            }
        }
    } catch (const std::filesystem::filesystem_error &err) {
        error("Trying to read folder \"%s\" returned \"%s\", aborting insertion\n", routine_path, err.what());
    }
    printf("%d Shared routines registered in \"%s\"\n", routine_count, routine_path);
    fclose(shared_patch);
}

// needs same order as defines at the top...
enum ListType { Sprite = 0, Extended = 1, Cluster = 2, Overworld = 3 };

void populate_sprite_list(const char **paths, sprite **sprite_lists, const char *listPath, FILE *output) {
    std::ifstream listStream(listPath);
    if (!listStream)
        error("Couldn't open list file %s for reading", listPath);
    unsigned int sprite_id, level;
    int lineno = 0;
    int read_res;
    std::string line;
    ListType type = Sprite;
    sprite *spr = nullptr;
    char cfgname[FILENAME_MAX] = {0};
    const char *dir = nullptr;
    while (std::getline(listStream, line)) {
        int read_until = -1;
        sprite *sprite_list = sprite_lists[type];
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
            if (read_res != 1 || read_res == EOF || read_until == -1)
                error("Line %d was malformed: \"%s\"\n", lineno, line.c_str());
            strcpy(cfgname, line.c_str() + read_until);
        } else if (line.find(':') == line.length() - 1) { // if it's the last char in the string, it's a type change
            if (line == "SPRITE:") {
                type = Sprite;
            } else if (line == "CLUSTER:") {
                type = Cluster;
            } else if (line == "EXTENDED:") {
                type = Extended;
            }
            continue;
        } else { // if there's a ':' but it's not at the end, it may be a per level sprite
            read_res = sscanf(line.c_str(), "%x:%x %n", &level, &sprite_id, &read_until);
            if (read_res != 2 || read_res == EOF || read_until == -1)
                error("Line %d was malformed: \"%s\"\n", lineno, line.c_str());
            if (!PER_LEVEL)
                error("Trying to insert per level sprites without using the -pl flag, at line %d: \"%s\"\n", lineno,
                      line.c_str());
            strcpy(cfgname, line.c_str() + read_until);
        }

        char *dot = strrchr(cfgname, '.');
        if (dot == nullptr)
            error("Error on line %d: missing extension on filename %s\n", lineno, cfgname);
        dot++;

        if (type == Sprite) {
            spr = from_table<sprite>(sprite_list, level, sprite_id);
            // verify sprite pointer and determine cause if invalid
            if (!spr) {
                if (sprite_id >= 0x100)
                    error("Error on line %d: Sprite number must be less than 0x100\n", lineno);
                if (level > 0x200)
                    error("Error on line %d: Level must range from 000-1FF\n", lineno);
                if (sprite_id >= 0xB0 && sprite_id < 0xC0)
                    error("Error on line %d: Only sprite B0-BF must be assigned a level.\n", lineno);
            }
        } else {
            if (sprite_id > SPRITE_COUNT)
                error("Error on line %d: Sprite number must be less than %x\n", lineno, SPRITE_COUNT);
            spr = sprite_list + sprite_id;
        }

        if (spr->line)
            error("Error on line %d: Sprite number %x already used.\n", lineno, sprite_id);

        // initialize some.
        spr->line = lineno;
        spr->level = level;
        spr->number = sprite_id;
        spr->sprite_type = type;

        // set the directory for the desired type
        if (type != Sprite)
            dir = paths[EXTENDED - 1 + type];
        else {
            if (sprite_id < 0xC0)
                dir = paths[SPRITES];
            else if (sprite_id < 0xD0)
                dir = paths[SHOOTERS];
            else
                dir = paths[GENERATORS];
        }
        spr->directory = dir;

        char *fullFileName = new char[strlen(dir) + strlen(cfgname) + 1];
        strcpy(fullFileName, dir);
        strcat(fullFileName, cfgname);

        if (type != Sprite) {
            if (strcmp(dot, "asm") && strcmp(dot, "ASM"))
                error("Error on line %d: not an asm file\n", lineno);
            spr->asm_file = fullFileName;
        } else {
            spr->cfg_file = fullFileName;
            if (!strcmp(dot, "cfg") || !strcmp(dot, ".CFG")) {
                if (!read_cfg_file(spr, output))
                    error("Error on line %d: Cannot parse CFG file.\n", lineno);
            } else if (!strcmp(dot, "json")) {
                if (!read_json_file(spr, output))
                    error("Error on line %d: Cannot parse JSON file.\n", lineno);
            } else
                error("Error on line %d: Unknown filetype\n", lineno);
        }

        if (output) {
            fprintf(output, "Read from line %d\n", spr->line);
            if (spr->level != 0x200)
                fprintf(output, "Number %02X for level %03X\n", spr->number, spr->level);
            else
                fprintf(output, "Number %02X\n", spr->number);
            spr->print(output);
            fprintf(output, "\n--------------------------------------\n");
        }

        // if sprite is tweak, set init and main pointer to contents of ROM pointer table.
        if (!spr->table.type) {
            set_pointer(&spr->table.init, (INIT_PTR + 2 * spr->number));
            set_pointer(&spr->table.main, (MAIN_PTR + 2 * spr->number));
        }
    }
}

// spr      = sprite array
// filename = duh
// size     = number of sprites to loop over
void write_long_table(sprite *spr, const char *dir, const char *filename, int size = 0x800) {
    unsigned char dummy[0x10] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
    unsigned char *file = new unsigned char[size * 0x10];

    if (is_empty_table(spr, size))
        write_all(dummy, dir, filename, 0x10);
    else {
        for (int i = 0; i < size; i++) {
            memcpy(file + (i * 0x10), &spr[i].table, 0x10);
        }
        write_all(file, dir, filename, size * 0x10);
    }
    delete[] file;
}

FILE *open_subfile(ROM &rom, const char *ext, const char *mode) {
    char *name = new char[strlen(rom.name) + 1];
    strcpy(name, rom.name);
    char *dot = strrchr(name, '.');
    strcpy(dot + 1, ext);
#ifdef DEBUGMSG
    debug_print("\ttry opening %s mode %s\n", name, mode);
#endif
    FILE *r = open(name, mode);
    delete[] name;
    return r;
}

void remove(const char *dir, const char *file) {
    char *path = new char[strlen(dir) + strlen(file) + 1];
    path[0] = 0;
    strcat(path, dir);
    strcat(path, file);
    remove(path);
    delete[] path;
}

int main(int argc, char *argv[]) {
    ROM rom;

    // individual lists containing the sprites for the specific sections
    sprite *sprite_list = new sprite[MAX_SPRITE_COUNT];
    sprite *cluster_list = new sprite[SPRITE_COUNT];
    sprite *extended_list = new sprite[SPRITE_COUNT];
    sprite *ow_list = new sprite[SPRITE_COUNT];

    // the list containing the lists...
    sprite *sprites_list_list[4];
    sprites_list_list[Sprite] = sprite_list;
    sprites_list_list[Extended] = extended_list;
    sprites_list_list[Cluster] = cluster_list;
    sprites_list_list[Overworld] = ow_list;

    FILE *output = nullptr;
    bool keep_temp = false;
    bool extmod = true;
    bool stop_on_warnings = false;
#ifdef ON_WINDOWS
    std::string lm_handle;
    uint16_t verification_code = 0;
    HWND window_handle = 0;
#endif
    // first is version 1.xx, others are preserved
    unsigned char versionflag[4] = {VERSION, 0x00, 0x00, 0x00};

    const char *paths[9];
    paths[LIST] = "list.txt";
    paths[SPRITES] = "sprites/";
    paths[SHOOTERS] = "shooters/";
    paths[GENERATORS] = "generators/";
    paths[ROUTINES] = "routines/";
    paths[ASM] = "asm/";
    paths[EXTENDED] = "extended/";
    paths[CLUSTER] = "cluster/";
    paths[OVERWORLD] = "overworld/";

    // list of strings containing the files to be used as base for <romname.xxx>
    // all nullptr by default
    const char *extensions[4] = {0};

    // map16 for sprite displays
    map16 *map = new map16[MAP16_SIZE];

    if (argc < 2) {
        atexit(double_click_exit);
    }

    if (!asar_init()) {
        error("Error: Asar library is missing or couldn't be initialized, please redownload the tool or add the dll.\n",
              "");
    }

    //------------------------------------------------------------------------------------------
    // handle arguments passed to tool
    //------------------------------------------------------------------------------------------

    for (int i = 1; i < argc; i++) {

#define SET_PATH(str, index)                                                                                           \
    else if (!strcmp(argv[i], str) && i < argc - 2) {                                                                  \
        paths[index] = argv[i + 1];                                                                                    \
        i++;                                                                                                           \
    }
#define SET_EXT(str, index)                                                                                            \
    else if (!strcmp(argv[i], str) && i < argc - 2) {                                                                  \
        extensions[index] = argv[i + 1];                                                                               \
        i++;                                                                                                           \
    }

        if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            printf("Version 1.%02d\n", VERSION);
            printf("Usage: pixi <options> <ROM>\nOptions are:\n");
            printf("-d\t\tEnable debug output, the following flag <-out> only works when this is set\n");
            printf("-out <filename>\t\tTo be used IMMEDIATELY after -d, will redirect the debug output to the "
                   "specified file, if omitted, the output will default to prompt\n");
            printf("-k\t\tKeep debug files\n");
            printf("-l  <listpath>\tSpecify a custom list file (Default: %s)\n", paths[LIST]);
            printf("-pl\t\tPer level sprites - will insert perlevel sprite code\n");
            printf("-npl\t\tSame as the current default, no sprite per level will be inserted, left dangling for "
                   "compatibility reasons\n");
            printf("-d255spl\t\tDisable 255 sprite per level support (won't do the 1938 remap)\n");
            printf("-w\t\tEnable asar warnings check, recommended to use when developing sprites.\n");
            printf("\n");

            printf("-a  <asm>\tSpecify a custom asm directory (Default %s)\n", paths[ASM]);
            printf("-sp <sprites>\tSpecify a custom sprites directory (Default %s)\n", paths[SPRITES]);
            printf("-sh <shooters>\tSpecify a custom shooters directory (Default %s)\n", paths[SHOOTERS]);
            printf("-g  <generators>\tSpecify a custom generators directory (Default %s)\n", paths[GENERATORS]);
            printf("-e  <extended>\tSpecify a custom extended sprites directory (Default %s)\n", paths[EXTENDED]);
            printf("-c  <cluster>\tSpecify a custom cluster sprites directory (Default %s)\n", paths[CLUSTER]);
            // printf("-ow <cluster>\tSpecify a custom overworld sprites directory (Default %s)\n", paths[OVERWORLD]);
            printf("\n");

            printf("-r   <routines>\tSpecify a shared routine directory (Default %s)\n", paths[ROUTINES]);
            printf("-nr <number>\tSpecify limit to shared routines (Default %d, Maximum value %d)\n", DEFAULT_ROUTINES,
                   MAX_ROUTINES);
            printf("\n");

            printf("-ext-off\t Disables extmod file logging (check LM's readme for more info on what extmod is)\n");
            printf("-ssc <append ssc>\tSpecify ssc file to be copied into <romname>.ssc\n");
            printf("-mwt <append mwt>\tSpecify mwt file to be copied into <romname>.mwt\n");
            printf("-mw2 <append mw2>\tSpecify mw2 file to be copied into <romname>.mw2, the provided file is assumed "
                   "to have 0x00 first byte sprite header and the 0xFF end byte\n");
            printf("-s16 <base s16>\tSpecify s16 file to be used as a base for <romname>.s16\n");
            printf("     Do not use <romname>.xxx as an argument as the file will be overwriten\n");

#ifdef ON_WINDOWS
            printf("-lm-handle <lm_handle_code>\t To be used only within LM's custom user toolbar file, it receives "
                   "LM's handle to reload the rom\n");
#endif

            printf("\nMeiMei flags:\n");
            printf("-meimei-off\t\tShuts down MeiMei completely\n");
            printf("-meimei-a\t\tEnables always remap sprite data\n");
            printf("-meimei-k\t\tEnables keep temp patches files\n");
            printf("-meimei-d\t\tEnables debug for MeiMei patches\n\n");

            exit(0);
        } else if (!strcmp(argv[i], "-d") || !strcmp(argv[i], "--debug")) {
            output = get_debug_output(argc, argv, &i);
        } else if (!strcmp(argv[i], "-k")) {
            keep_temp = true;
        } else if (!strcmp(argv[i], "-nr")) {
            DEFAULT_ROUTINES = std::atoi(argv[i + 1]);
            i++;
            if (DEFAULT_ROUTINES > MAX_ROUTINES)
                DEFAULT_ROUTINES = MAX_ROUTINES;
            if (DEFAULT_ROUTINES == 0)
                DEFAULT_ROUTINES = 100;
        } else if (!strcmp(argv[i], "-pl")) {
            PER_LEVEL = true;
        } else if (!strcmp(argv[i], "-npl")) {
            PER_LEVEL = false;
        } else if (!strcmp(argv[i], "-d255spl")) {
            DISABLE_255_SPRITE_PER_LEVEL = true;
        } else if (!strcmp(argv[i], "-w")) {
            stop_on_warnings = true;
        } else if (!strcmp(argv[i], "-meimei-a")) {
            MeiMei::setAlwaysRemap();
        } else if (!strcmp(argv[i], "-meimei-d")) {
            MeiMei::setDebug();
        } else if (!strcmp(argv[i], "-meimei-k")) {
            MeiMei::setKeepTemp();
        } else if (!strcmp(argv[i], "-meimei-off")) {
            disableMeiMei = true;
        } else if (!strcmp(argv[i], "-ext-off")) {
            extmod = false;
        }
#ifdef ON_WINDOWS
        else if (!strcmp(argv[i], "-lm-handle")) {
            lm_handle = argv[i + 1];
            window_handle = (HWND)std::stoull(lm_handle, 0, 16);
            verification_code = std::stoi(lm_handle.substr(lm_handle.find_first_of(':') + 1), 0, 16);
            i++;
        }
#endif
        SET_PATH("-r", ROUTINES)
        SET_PATH("-a", ASM)
        SET_PATH("-sp", SPRITES)
        SET_PATH("-sh", SHOOTERS)
        SET_PATH("-g", GENERATORS)
        SET_PATH("-l", LIST)
        SET_PATH("-e", EXTENDED)
        SET_PATH("-c", CLUSTER)

        SET_EXT("-ssc", EXT_SSC)
        SET_EXT("-mwt", EXT_MWT)
        SET_EXT("-mw2", EXT_MW2)
        SET_EXT("-s16", EXT_S16)
        else {
            if (i == argc - 1) {
                break;
            }
            if (strcmp(argv[i], "-out") == 0)
                error("ERROR: \"%s\" command line option used without having the \"-d\" command line option active.\n",
                      argv[i]);
            else
                error("ERROR: Invalid command line option \"%s\".\n", argv[i]);
        }
    }

    versionflag[1] = (PER_LEVEL ? 1 : 0);

    //------------------------------------------------------------------------------------------
    // Get ROM name if none has been passed yet.
    //------------------------------------------------------------------------------------------

    if (argc < 2) {
        printf("Enter a ROM file name, or drag and drop the ROM here: ");
        char ROM_name[FILENAME_MAX];
        if (fgets(ROM_name, FILENAME_MAX, stdin)) {
            int length = strlen(ROM_name) - 1;
            ROM_name[length] = 0;
            if ((ROM_name[0] == '"' && ROM_name[length - 1] == '"') ||
                (ROM_name[0] == '\'' && ROM_name[length - 1] == '\'')) {
                ROM_name[length - 1] = 0;
                for (int i = 0; ROM_name[i]; i++) {
                    ROM_name[i] = ROM_name[i + 1]; // no buffer overflow there are two null chars.
                }
            }
        }
        rom.open(ROM_name);
    } else {
        rom.open(argv[argc - 1]);
    }

    //------------------------------------------------------------------------------------------
    // Check if a newer version has been used before.
    //------------------------------------------------------------------------------------------

    char version = rom.data[rom.snes_to_pc(0x02FFE2 + 4)];
    if (version > VERSION) {
        printf("The ROM has been patched with a newer version of PIXI (1.%02d) already.\n", version);
        printf("This is version 1.%02d\n", VERSION);
        printf("Please get a newer version.");
        rom.close();
        asar_close();
        exit(-1);
    }

    int lm_edit_ptr = get_pointer(rom.data, rom.snes_to_pc(0x06F624)); // thanks p4plus2
    if (lm_edit_ptr == 0xFFFFFF) {
        printf("You're inserting Pixi without having modified a level in Lunar Magic, this will cause bugs\nDo you "
               "want to abort insertion now [y/n]?\nIf you choose 'n', to fix the bugs just reapply Pixi after having "
               "modified a level\n");
        char c = getchar();
        if (tolower(c) == 'y') {
            rom.close();
            asar_close();
            printf("Insertion was stopped, press any button to exit...\n");
            getchar();
            exit(-1);
        }
        fflush(stdin); // uff
    }

    unsigned char vram_jump = rom.data[rom.snes_to_pc(0x00F6E4)];
    if (vram_jump != 0x5C) {
        printf("You haven't installed the VRAM optimization patch in Lunar Magic, this will cause many features of "
               "Pixi to work incorrectly, insertion was aborted...\n");
        getchar();
        exit(-1);
    }

    // Initialize MeiMei
    if (!disableMeiMei) {
        MeiMei::initialize(rom.name);
    }

    //------------------------------------------------------------------------------------------
    // set path for directories relative to pixi or rom, not working dir.
    //------------------------------------------------------------------------------------------

    for (int i = 0; i < 9; i++) {
        if (i == LIST)
            set_paths_relative_to(paths + i, rom.name);
        else
            set_paths_relative_to(paths + i, argv[0]);
#ifdef DEBUGMSG
        debug_print("paths[%d] = %s\n", i, paths[i]);
#endif
    }
    ASM_DIR = paths[ASM];
    ASM_DIR_PATH = cleanPathTrail(ASM_DIR);

    for (int i = 0; i < 4; i++) {
        set_paths_relative_to(extensions + i, rom.name);
#ifdef DEBUGMSG
        debug_print("extensions[%d] = %s\n", i, extensions[i]);
#endif
    }

    //------------------------------------------------------------------------------------------
    // regular stuff
    //------------------------------------------------------------------------------------------
    create_config_file(ASM_DIR_PATH + "/config.asm");
    std::list<std::string> extraDefines = listExtraAsm(ASM_DIR_PATH + "/ExtraDefines");
    populate_sprite_list(paths, sprites_list_list, paths[LIST], output);

    clean_hack(rom, paths[ASM]);

    create_shared_patch(paths[ROUTINES]);

    int size = PER_LEVEL ? MAX_SPRITE_COUNT : 0x100;
    patch_sprites(extraDefines, sprite_list, size, rom, output);
    patch_sprites(extraDefines, cluster_list, SPRITE_COUNT, rom, output);
    patch_sprites(extraDefines, extended_list, SPRITE_COUNT, rom, output);
    // patch_sprites(extraDefines, ow_list, SPRITE_COUNT, rom, output);

    if (!warnings.empty() && stop_on_warnings) {
        printf("A warning has been detected:\n");
        for (const std::string &warning : warnings) {
            printf("%s\n", warning.c_str());
        }
        printf("Do you want to continue insertion anyway? [Y/n] (Default is yes):\n");
        char c = getchar();
        if (tolower(c) == 'n') {
            asar_close();
            printf("Insertion was stopped, press any button to exit...\n");
            getchar();
            exit(-1);
        }
        fflush(stdin); // uff
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
    write_all(versionflag, paths[ASM], "_versionflag.bin", 4);
    if (PER_LEVEL) {
        write_all(PLS_LEVEL_PTRS, paths[ASM], "_PerLevelLvlPtrs.bin", 0x400);
        if (PLS_DATA_ADDR == 0) {
            unsigned char dummy[1] = {0xFF};
            write_all(dummy, paths[ASM], "_PerLevelSprPtrs.bin", 1);
            write_all(dummy, paths[ASM], "_PerLevelT.bin", 1);
            write_all(dummy, paths[ASM], "_PerLevelCustomPtrTable.bin", 1);
        } else {
            write_all(PLS_SPRITE_PTRS, paths[ASM], "_PerLevelSprPtrs.bin", PLS_SPRITE_PTRS_ADDR);
            write_all(PLS_DATA, paths[ASM], "_PerLevelT.bin", PLS_DATA_ADDR);
            write_all(PLS_POINTERS, paths[ASM], "_PerLevelCustomPtrTable.bin", PLS_DATA_ADDR);
#ifdef DEBUGMSG
            debug_print("Per-level sprites data size : 0x400+0x%04X+2*0x%04X = %04X\n", PLS_SPRITE_PTRS_ADDR,
                        PLS_DATA_ADDR, 0x400 + PLS_SPRITE_PTRS_ADDR + 2 * PLS_DATA_ADDR);
#endif
        }
        write_long_table(sprite_list + 0x2000, paths[ASM], "_DefaultTables.bin", 0x100);
    } else {
        write_long_table(sprite_list, paths[ASM], "_DefaultTables.bin", 0x100);
    }
    unsigned char customstatusptrs[0x100 * 15];
    for (int i = 0, j = PER_LEVEL ? 0x2000 : 0; i < 0x100 * 5; i += 5, j++) {
        memcpy(customstatusptrs + (i * 3), &sprite_list[j].ptrs, 15);
    }
    write_all(customstatusptrs, paths[ASM], "_CustomStatusPtr.bin", 0x100 * 15);

    // cluster
    unsigned char file[SPRITE_COUNT * 3];
    for (int i = 0; i < SPRITE_COUNT; i++)
        memcpy(file + (i * 3), &cluster_list[i].table.main, 3);
    write_all(file, paths[ASM], "_ClusterPtr.bin", SPRITE_COUNT * 3);

    // extended
    for (int i = 0; i < SPRITE_COUNT; i++)
        memcpy(file + (i * 3), &extended_list[i].table.main, 3);
    write_all(file, paths[ASM], "_ExtendedPtr.bin", SPRITE_COUNT * 3);
    for (int i = 0; i < SPRITE_COUNT; i++)
        memcpy(file + (i * 3), &extended_list[i].extended_cape_ptr, 3);
    write_all(file, paths[ASM], "_ExtendedCapePtr.bin", SPRITE_COUNT * 3);

    // overworld
    // for(int i = 0; i < SPRITE_COUNT; i++)
    // memcpy(file + (i * 3), &ow_list[i].table.main, 3);
    // write_all(file, paths[ASM], "_OverworldMainPtr.bin", SPRITE_COUNT * 3);
    // for(int i = 0; i < SPRITE_COUNT; i++)
    // memcpy(file + (i * 3), &ow_list[i].table.init, 3);
    // write_all(file, paths[ASM], "_OverworldInitPtr.bin", SPRITE_COUNT * 3);

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
    unsigned char extra_bytes[0x200];

#ifdef DEBUGMSG
    debug_print("Try create romname files.\n");
#endif
    FILE *s16 = open_subfile(rom, "s16", "wb");
    FILE *ssc = open_subfile(rom, "ssc", "w");
    FILE *mwt = open_subfile(rom, "mwt", "w");
    FILE *mw2 = open_subfile(rom, "mw2", "wb");
#ifdef DEBUGMSG
    debug_print("Romname files opened.\n");
#endif

    if (extensions[EXT_SSC]) {
        std::ifstream fin(extensions[EXT_SSC]);
        std::string line;
        while (std::getline(fin, line)) {
            fprintf(ssc, "%s\n", line.c_str());
        }
        fin.close();
    }

    if (extensions[EXT_MWT]) {
        std::ifstream fin(extensions[EXT_MWT]);
        std::string line;
        while (std::getline(fin, line)) {
            fprintf(mwt, "%s\n", line.c_str());
        }
        fin.close();
    }

    if (extensions[EXT_MW2]) {
        FILE *fp = fopen(extensions[EXT_MW2], "rb");
        size_t fs_size = file_size(fp);
        if (fs_size == 0) {
            // if size == 0, it means that the file is empty, so we just append the 0x00 and go on with our lives
            fputc(0x00, mw2);
        } else {
            fs_size--; // -1 to skip the 0xFF byte at the end
            unsigned char *mw2_data = new unsigned char[fs_size];
            size_t read_size = fread(mw2_data, 1, fs_size, fp);
            if (read_size != fs_size)
                error("Couldn't fully read file %s, please check file permissions", extensions[EXT_MW2]);
            fclose(fp);
            fwrite(mw2_data, 1, fs_size, mw2);
            delete[] mw2_data;
        }
        fclose(fp);
    } else {
        fputc(0x00, mw2); // binary data starts with 0x00
    }

    if (extensions[EXT_S16])
        read_map16(map, extensions[EXT_S16]);

    for (int i = 0; i < 0x100; i++) {
        sprite *spr = from_table<sprite>(sprite_list, 0x200, i);

        // sprite pointer being null indicates per-level sprite
        if (!spr || (PER_LEVEL && i >= 0xB0 && i < 0xC0)) {
            extra_bytes[i] = 7; // 3 bytes + 4 extra bytes because the old one broke basically any sprite that wasn't
                                // using exactly 9 extra bytes
            extra_bytes[i + 0x100] = 7; // 12 was wrong anyway, should've been 15
        } else {
            // line number within the list file indicates we've got a filled out sprite
            if (spr->line) {
                extra_bytes[i] = 3 + spr->byte_count;
                extra_bytes[i + 0x100] = 3 + spr->extra_byte_count;

                //----- s16 / map16 -------------------------------------------------

                int map16_tile = find_free_map(map, spr->map_block_count);
                if (map16_tile == -1) {
                    error("There wasn't enough space in your s16 file to fit everything, was trying to fit %d blocks, "
                          "couldn't find space\n",
                          spr->map_block_count);
                }
                memcpy(map + map16_tile, spr->map_data, spr->map_block_count * sizeof(map16));

                //----- ssc / display -----------------------------------------------
                for (int j = 0; j < spr->display_count; j++) {
                    display *d = spr->displays + j;

                    // 4 digit hex value. First is Y pos (0-F) then X (0-F) then custom/extra bit combination
                    // here custom bit is always set (because why the fuck not?)
                    int ref = d->y * 0x1000 + d->x * 0x100 + 0x20 + (d->extra_bit ? 0x10 : 0);

                    // if no description (or empty) just asm filename instead.
                    if (d->description && strlen(d->description))
                        fprintf(ssc, "%02X %04X %s\n", i, ref, d->description);
                    else
                        fprintf(ssc, "%02X %04X %s\n", i, ref, spr->asm_file);

                    // loop over tiles and append them into the output.
                    fprintf(ssc, "%02X %04X", i, ref + 2);
                    for (int k = 0; k < d->tile_count; k++) {
                        tile *t = d->tiles + k;
                        if (t->text) {
                            fprintf(ssc, " 0,0,*%s*", t->text);
                            break;
                        } else {
                            // tile numbers > 0x300 indicates it's a "custom" map16 tile, so we add the offset we got
                            // earlier +0x100 because in LM these start at 0x400.
                            int tile_num = t->tile_number;
                            if (tile_num >= 0x300)
                                tile_num += 0x100 + map16_tile;
                            // note we're using %d because x/y are signed integers here
                            fprintf(ssc, " %d,%d,%X", t->x_offset, t->y_offset, tile_num);
                        }
                    }
                    fprintf(ssc, "\n");
                }

                //----- mwt,mw2 / collection ------------------------------------------
                for (int j = 0; j < spr->collection_count; j++) {
                    collection *c = spr->collections + j;

                    // mw2
                    // build 3 byte level format
                    char c1 = 0x79 + (c->extra_bit ? 0x04 : 0);
                    fputc(c1, mw2);
                    fputc(0x70, mw2);
                    fputc(spr->number, mw2);
                    // add the extra property bytes
                    int byte_count = (c->extra_bit ? spr->extra_byte_count : spr->byte_count);
                    fwrite(c->prop, 1, byte_count, mw2);

                    // mwt
                    // first one prints sprite number as well, all others just their name.
                    if (j == 0)
                        fprintf(mwt, "%02X\t%s\n", spr->number, c->name);
                    else
                        fprintf(mwt, "\t%s\n", c->name);
                }

                // no line means unused sprite, so just set to default 3.
            } else {
                extra_bytes[i] = 3;
                extra_bytes[i + 0x100] = 3;
            }
        }
    }
    fputc(0xFF, mw2); // binary data ends with 0xFF (see SMW level data format)

    write_all(extra_bytes, paths[ASM], "_CustomSize.bin", 0x200);
    fwrite(map, sizeof(map16), MAP16_SIZE, s16);
    // close all the files.
    fclose(s16);
    fclose(ssc);
    fclose(mwt);
    fclose(mw2);

    // apply the actual patches
    patch(paths[ASM], "main.asm", rom);
    patch(paths[ASM], "cluster.asm", rom);
    patch(paths[ASM], "extended.asm", rom);

    std::list<std::string> extraHijacks = listExtraAsm(ASM_DIR_PATH + "/ExtraHijacks");
    for (std::string patchUri : extraHijacks) {
        patch(patchUri.c_str(), rom);
    }

    // patch(paths[ASM], "asm/overworld.asm", rom);

    //------------------------------------------------------------------------------------------
    // clean up (if necessary)
    //------------------------------------------------------------------------------------------

    if (!keep_temp) {
        remove(paths[ASM], "_versionflag.bin");

        remove(paths[ASM], "_DefaultTables.bin");
        remove(paths[ASM], "_CustomStatusPtr.bin");
        if (PER_LEVEL) {
            remove(paths[ASM], "_PerLevelLvlPtrs.bin");
            remove(paths[ASM], "_PerLevelSprPtrs.bin");
            remove(paths[ASM], "_PerLevelT.bin");
            remove(paths[ASM], "_PerLevelCustomPtrTable.bin");
        }

        remove(paths[ASM], "_ClusterPtr.bin");
        remove(paths[ASM], "_ExtendedPtr.bin");
        remove(paths[ASM], "_ExtendedCapePtr.bin");
        // remove("asm/_OverworldMainPtr.bin");
        // remove("asm/_OverworldInitPtr.bin");

        remove(paths[ASM], "_CustomSize.bin");
        remove("shared.asm");
        remove(TEMP_SPR_FILE);

        remove(paths[ASM], "_cleanup.asm");
    }

    printf("\nAll sprites applied successfully!\n");

    for (int i = 0; i < 9; i++) {
        delete[] paths[i];
    }

    for (int i = 0; i < 4; i++) {
        delete[] extensions[i];
    }

    if (extmod)
        create_lm_restore(rom.name);

    rom.close();
    asar_close();
    int retval = 0;
    if (!disableMeiMei) {
        MeiMei::configureSa1Def(ASM_DIR_PATH.append("/sa1def.asm"));
        retval = MeiMei::run();
    }

#ifdef ON_WINDOWS
    if (!lm_handle.empty()) {
        uint32_t IParam = (verification_code << 16) + 2; // reload rom
        PostMessage(window_handle, 0xBECB, 0, IParam);
    }
#endif
    delete[] map;
    delete[] sprite_list;
    delete[] extended_list;
    delete[] cluster_list;
    delete[] ow_list;
    return retval;
}
