
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>
#include <unordered_set>

#include "../iohandler.h"
#include "MeiMei.h"

#ifdef ASAR_USE_DLL
#include "../asar/asardll.h"
#else
#include "../asar/asar.h"
#endif

constexpr auto SPR_ADDR_LIMIT = 0x800;

#define ERR(msg)                                                                                                       \
    {                                                                                                                  \
        io.error("Error: %s", msg);                                                                                    \
        goto end;                                                                                                      \
    }

#define ASSERT_SPR_DATA_ADDR_SIZE(val)                                                                                 \
    if ((val) >= SPR_ADDR_LIMIT)                                                                                       \
        ERR("Sprite data is too large!");

bool& MeiMei::AlwaysRemap() {
    return MeiMei::always;
}

bool& MeiMei::Debug() {
    return MeiMei::debug;
}

bool& MeiMei::KeepTemp() {
    return MeiMei::keepTemp;
}

std::string escapeDefines(const std::string& path) {
    std::stringstream ss("");
    for (char c : path) {
        if (c == '!') {
            ss << "\\!";
        } else {
            ss << c;
        }
    }
    return ss.str();
}

void MeiMei::configureSa1Def(const std::string& pathToSa1Def) {
    std::string escapedPath = escapeDefines(pathToSa1Def);
    MeiMei::sa1DefPath = escapedPath;
}

bool MeiMei::patch(const patchfile& patch, const std::vector<patchfile>& patchfiles, ROM& rom) {
    iohandler& io = iohandler::get_global();
    std::vector<memoryfile> memfiles{};
    memfiles.reserve(patchfiles.size() + 1);
    memfiles.push_back(patch.vfile());
    std::transform(patchfiles.begin(), patchfiles.end(), std::back_inserter(memfiles),
                   [](const auto& p) { return p.vfile(); });
    patchparams params{.structsize = sizeof(patchparams),
                       .patchloc = patch.path().c_str(),
                       .romdata = reinterpret_cast<char*>(rom.unheadered_data()),
                       .buflen = MAX_ROM_SIZE,
                       .romlen = &rom.size,
                       .includepaths = nullptr,
                       .numincludepaths = 0,
                       .should_reset = true,
                       .additional_defines = nullptr,
                       .additional_define_count = 0,
                       .stdincludesfile = nullptr,
                       .stddefinesfile = nullptr,
                       .warning_settings = nullptr,
                       .warning_setting_count = 0,
                       .memory_files = memfiles.data(),
                       .memory_file_count = static_cast<int>(memfiles.size()),
                       .override_checksum_gen = false,
                       .generate_checksum = true};
    if (!asar_patch_ex(&params)) {
        int error_count;
        const errordata* errors = asar_geterrors(&error_count);
        io.error("An error has been detected:\n");
        for (int i = 0; i < error_count; i++)
            io.error("%s\n", errors[i].fullerrdata);
        return false;
    }

    if (MeiMei::debug) {
        int print_count = 0;
        const char* const* prints = asar_getprints(&print_count);
        for (int i = 0; i < print_count; ++i) {
            io.print("%s\n", prints[i]);
        }
    }

    return true;
}

struct AddressConstants {
    // these constants are all headered addresses (e.g. +0x200)
    static constexpr int LMLevelSpriteDataBankBytePointer = 0x77300;  /* $0EF100 */
    static constexpr int LMPresentFlagPointer = 0x07750F;             /* $0EF30F should be 0x42 */
    static constexpr int LMSizeTableAddressPointer = 0x07750C;        /* $0EF30C points to the actual table */
    static constexpr int LevelSpriteDataPointerTable = 0x02EE00;      /* $05EC00 */
};

bool MeiMei::initialize(const char* rom_name) {
    MeiMei::name = std::string(rom_name);

    memset(prevEx, 0x03, 0x400);
    memset(nowEx, 0x03, 0x400);

    if (!prev.open(MeiMei::name))
        return false;
    if (prev.read_byte(AddressConstants::LMPresentFlagPointer) == 0x42) {
        auto addr =
            prev.snes_to_pc(prev.read_long(AddressConstants::LMSizeTableAddressPointer));
        prev.read_data(prevEx, 0x0400, addr);
    }
    return true;
}

int MeiMei::run() {
    ROM rom;
    iohandler& io = iohandler::get_global();
    if (!rom.open(MeiMei::name))
        return 1;

    int returnValue = MeiMei::run(rom);

    if (returnValue) {
        prev.close();
        io.error("\n\nError occurred in MeiMei.\n"
                 "Your rom has reverted to before pixi insert.\n");
        return returnValue;
    }

    rom.close();
    return returnValue;
}

int MeiMei::run(ROM& rom) {
    iohandler& io = iohandler::get_global();
    ROM now;
    if (!now.open(MeiMei::name))
        return 1;
    if (prev.read_byte(AddressConstants::LMPresentFlagPointer) == 0x42) {
        auto addr = now.snes_to_pc(now.read_long(AddressConstants::LMSizeTableAddressPointer));
        now.read_data(nowEx, 0x0400, addr);
    }

    bool changeEx = false;
    for (int i = 0; i < 0x400; i++) {
        if (prevEx[i] != nowEx[i]) {
            changeEx = true;
            break;
        }
    }

    bool revert = changeEx || MeiMei::always;
    if (changeEx) {
        io.print("\nExtra bytes change detected, MeiMei will autofix the sprite data\n\n");
    }

    if (changeEx || MeiMei::always) {
        uint8_t sprAllData[SPR_ADDR_LIMIT]{};
        uint8_t sprCommonData[3];
        std::unordered_set<pcaddress> sprDataPointers{};

        patchfile meimei_patch{"_meimei_fixup.asm", patchfile::openflags::w, /* from_mei_mei= */ true};
        meimei_patch.fprintf("incsrc \"%s\"\n", MeiMei::sa1DefPath.c_str());
        std::vector<patchfile> meimei_fixup_patches{};

        for (int lv = 0; lv < 0x200; lv++) {

            int sprAddrSNES = (now.read_byte(AddressConstants::LMLevelSpriteDataBankBytePointer + lv) << 16) +
                              now.read_word(AddressConstants::LevelSpriteDataPointerTable + lv * 2);
            auto sprAddrPC = now.snes_to_pc(sprAddrSNES);
            if (sprAddrPC == -1) {
                ERR("Sprite Data has invalid address.")
            }
            auto [_, inserted] = sprDataPointers.insert(sprAddrPC);
            if (!inserted)
                continue;

            memset(sprAllData, 0, SPR_ADDR_LIMIT);

            sprAllData[0] = now.read_byte(sprAddrPC);
            int prevOfs = 1;
            int nowOfs = 1;
            bool exlevelFlag = sprAllData[0] & (uint8_t)0x20;
            bool changeData = false;

            while (true) {
                now.read_data(sprCommonData, 3, sprAddrPC + prevOfs);
                if (nowOfs >= SPR_ADDR_LIMIT - 3) {
                    ERR("Sprite data is too large!")
                }

                if (sprCommonData[0] == 0xFF) {
                    sprAllData[nowOfs++] = 0xFF;
                    if (!exlevelFlag) {
                        break;
                    }

                    sprAllData[nowOfs++] = sprCommonData[1];
                    if (sprCommonData[1] == 0xFE) {
                        break;
                    } else {
                        prevOfs += 2;
                        now.read_data(sprCommonData, 3, sprAddrPC + prevOfs);
                    }
                }

                sprAllData[nowOfs++] = sprCommonData[0]; // YYYYEEsy
                sprAllData[nowOfs++] = sprCommonData[1]; // XXXXSSSS
                sprAllData[nowOfs++] = sprCommonData[2]; // NNNNNNNN

                int sprNum = ((sprCommonData[0] & 0x0C) << 6) | (sprCommonData[2]);

                if (nowEx[sprNum] > prevEx[sprNum]) {
                    changeData = true;
                    int i;
                    for (i = 3; i < prevEx[sprNum]; i++) {
                        sprAllData[nowOfs++] = now.read_byte(sprAddrPC + prevOfs + i);
                        ASSERT_SPR_DATA_ADDR_SIZE(nowOfs)
                    }
                    for (; i < nowEx[sprNum]; i++) {
                        sprAllData[nowOfs++] = 0x00;
                        ASSERT_SPR_DATA_ADDR_SIZE(nowOfs)
                    }
                } else if (nowEx[sprNum] < prevEx[sprNum]) {
                    changeData = true;
                    for (int i = 3; i < nowEx[sprNum]; i++) {
                        sprAllData[nowOfs++] = now.read_byte(sprAddrPC + prevOfs + i);
                        ASSERT_SPR_DATA_ADDR_SIZE(nowOfs)
                    }
                } else {
                    for (int i = 3; i < nowEx[sprNum]; i++) {
                        sprAllData[nowOfs++] = now.read_byte(sprAddrPC + prevOfs + i);
                        ASSERT_SPR_DATA_ADDR_SIZE(nowOfs)
                    }
                }
                prevOfs += prevEx[sprNum];
            }

            if (changeData) {
                std::string lvlstr = std::to_string(lv);
                // create sprite data binary
                std::string binaryFileName{"_tmp_bin_"};
                binaryFileName.append(lvlstr);
                binaryFileName.append(".bin");
                patchfile binFile{binaryFileName, patchfile::openflags::wb, /* from_mei_mei= */ true};
                binFile.fwrite(sprAllData, nowOfs);
                binFile.close();

                // create patch for sprite data binary
                std::string fileName{"_tmp_"};
                fileName.append(lvlstr);
                fileName.append(".asm");
                patchfile spriteDataPatch{fileName, patchfile::openflags::w, /* from_mei_mei= */ true};

                std::string binaryLabel{"SpriteData"};
                binaryLabel.append(lvlstr);

                // create actual asar patch
                const auto levelBankAddress =
                    now.pc_to_snes(AddressConstants::LMLevelSpriteDataBankBytePointer + lv);
                const auto levelWordAddress =
                    now.pc_to_snes(AddressConstants::LevelSpriteDataPointerTable + lv * 2);
                const char* binL = binaryLabel.c_str();
                spriteDataPatch.fprintf(
                    "!level_%03X_oldDataPointer = read2($%06X)|(read1($%06X)<<16)\n"
                    "!level_%03X_oldDataSize = read2(pctosnes(snestopc(!level_%03X_oldDataPointer)-4))+1\n"
                    "autoclean !level_%03X_oldDataPointer\n\n"
                    "org $%06X\n"
                    "\tdb %s>>16\n\n"
                    "org $%06X\n"
                    "\tdw %s\n\n"
                    "freedata cleaned\n"
                    "%s:\n"
                    "\t!level_%03X_newDataPointer = %s\n"
                    "\tincbin \"%s\"\n"
                    "%s_end:\n"
                    "\tprint \"---- Level %03X ----\"\n"
                    "\tprint \"Data pointer from $\",hex(!level_%03X_oldDataPointer),\" to "
                    "$\",hex(!level_%03X_newDataPointer)\n"
                    "\tprint \"Data size    from $\",hex(!level_%03X_oldDataSize),\" to $\",hex(%s_end-%s)\n",
                    lv, levelWordAddress, levelBankAddress, lv, lv, lv, levelBankAddress, binL, levelWordAddress, binL,
                    binL, lv, binL, binaryFileName.c_str(), binL, lv, lv, lv, lv, binL, binL);
                spriteDataPatch.close();

                meimei_fixup_patches.push_back(std::move(binFile));
                meimei_fixup_patches.push_back(std::move(spriteDataPatch));

                meimei_patch.fprintf("incsrc \"%s\"\n", fileName.c_str());
            }
        }

        meimei_patch.close();

        if (!meimei_fixup_patches.empty()) {
            if (!MeiMei::patch(meimei_patch, meimei_fixup_patches, rom)) {
                ERR("An error occured when patching sprite data with asar.")
            }
        }

        io.print("\nSprite data remapped successfully.\n");
        revert = false;
    }
end:
    if (revert) {
        return 1;
    }

    return 0;
}
