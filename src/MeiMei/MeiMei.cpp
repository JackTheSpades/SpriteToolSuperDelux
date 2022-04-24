
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

#include "MeiMei.h"

#include "../asar/asardll.h"

constexpr auto SPR_ADDR_LIMIT = 0x800;

#define ERR(msg)                                                                                                       \
    {                                                                                                                  \
        printf("Error: %s", msg);                                                                                      \
        goto end;                                                                                                      \
    }

#define ASSERT_SPR_DATA_ADDR_SIZE(val)                                                                                 \
    if ((val) >= SPR_ADDR_LIMIT)                                                                                         \
        ERR("Sprite data is too large!");

void MeiMei::setAlwaysRemap() {
    MeiMei::always = true;
}

void MeiMei::setDebug() {
    MeiMei::debug = true;
}

void MeiMei::setKeepTemp() {
    MeiMei::keepTemp = true;
}

std::string escapeDefines(const std::string &path) {
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

void MeiMei::configureSa1Def(const string &pathToSa1Def) {
    string escapedPath = escapeDefines(pathToSa1Def);
    MeiMei::sa1DefPath = escapedPath;
}

bool MeiMei::patch(const char *patch_name, ROM &rom) {
    if (!asar_patch(patch_name, (char *)rom.real_data, MAX_ROM_SIZE, &rom.size)) {
        int error_count;
        const errordata *errors = asar_geterrors(&error_count);
        printf("An error has been detected:\n");
        for (int i = 0; i < error_count; i++)
            printf("%s\n", errors[i].fullerrdata);
        return false;
    }

    if (MeiMei::debug) {
        int print_count = 0;
        const char *const *prints = asar_getprints(&print_count);
        for (int i = 0; i < print_count; ++i) {
            std::cout << "\t" << prints[i] << '\n';
        }
    }

    return true;
}

bool MeiMei::initialize(const char *rom_name) {
    MeiMei::name = std::string(rom_name);

    memset(prevEx, 0x03, 0x400);
    memset(nowEx, 0x03, 0x400);

    if (!prev.open(MeiMei::name.c_str()))
        return false;
    if (prev.read_byte(0x07730F) == 0x42) {
        int addr = prev.snes_to_pc(prev.read_long(0x07730C), false);
        prev.read_data(prevEx, 0x0400, addr);
    }
    return true;
}

int MeiMei::run() {
    ROM rom;
    if (!rom.open(MeiMei::name.c_str()))
        return 1;
    if (!asar_init()) {
        error("Error: Asar library is missing or couldn't be initialized, please redownload the tool or add the dll.\n",
              "");
    }

    int returnValue = MeiMei::run(rom);

    if (returnValue) {
        prev.close();
        asar_close();
        printf("\n\nError occurred in MeiMei.\n"
               "Your rom has reverted to before pixi insert.\n");
        return returnValue;
    }

    rom.close();
    asar_close();
    return returnValue;
}

int MeiMei::run(ROM &rom) {
    ROM now;
    if (!now.open(MeiMei::name.c_str()))
        return 1;
    if (prev.read_byte(0x07730F) == 0x42) {
        int addr = now.snes_to_pc(now.read_long(0x07730C), false);
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
        printf("\nExtra bytes change detected\n");
    }

    if (changeEx || MeiMei::always) {
        uchar sprAllData[SPR_ADDR_LIMIT]{};
        uchar sprCommonData[3];
        bool remapped[0x0200]{};

        for (int lv = 0; lv < 0x200; lv++) {
            if (remapped[lv])
                continue;

            int sprAddrSNES = (now.read_byte(0x077100 + lv) << 16) + now.read_word(0x02EC00 + lv * 2);
            int sprAddrPC = now.snes_to_pc(sprAddrSNES, false);
            if (sprAddrPC == -1) {
                ERR("Sprite Data has invalid address.")
            }

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
                std::stringstream ss;
                ss << std::uppercase << std::hex << lv;
                std::string levelAsHex = ss.str();

                // create sprite data binary
                std::string binaryFileName("_tmp_bin_");
                binaryFileName.append(levelAsHex);
                binaryFileName.append(".bin");
                std::ofstream binFile(binaryFileName, ios::out | ios::binary);
                for (int ara = 0; ara <= nowOfs; ara++) {
                    binFile << sprAllData[ara];
                }
                binFile.close();

                // create patch for sprite data binary
                std::string fileName("_tmp_");
                fileName.append(levelAsHex);
                fileName.append(".asm");
                std::ofstream spriteDataPatch(fileName, std::ios::out | std::ios::binary);

                std::string binaryLabel("SpriteData");
                binaryLabel.append(levelAsHex);

                std::ostringstream oss;
                oss << std::setfill('0') << std::setw(6) << std::hex << now.pc_to_snes(0x077100 + lv, false);
                std::string levelBankAddress = oss.str();

                oss = std::ostringstream();
                oss << std::setfill('0') << std::setw(6) << std::hex << now.pc_to_snes(0x02EC00 + lv * 2, false);
                std::string levelWordAddress = oss.str();

                // create actual asar patch
                spriteDataPatch << "incsrc \"" << MeiMei::sa1DefPath << "\"" << "\n" << '\n';
                spriteDataPatch << "!oldDataPointer = read2($" << levelWordAddress << ")|(read1($" << levelBankAddress
                                << ")<<16)" << '\n';
                spriteDataPatch << "!oldDataSize = read2(pctosnes(snestopc(!oldDataPointer)-4))+1" << '\n';
                spriteDataPatch << "autoclean !oldDataPointer" << "\n" << '\n';

                spriteDataPatch << "org $" << levelBankAddress << '\n';
                spriteDataPatch << "\tdb " << binaryLabel << ">>16" << "\n" << '\n';

                spriteDataPatch << "org $" << levelWordAddress << '\n';
                spriteDataPatch << "\tdw " << binaryLabel << "\n" << '\n';

                spriteDataPatch << "freedata cleaned" << '\n';
                spriteDataPatch << binaryLabel << ":" << '\n';
                spriteDataPatch << "\t!newDataPointer = " << binaryLabel << '\n';
                spriteDataPatch << "\tincbin " << binaryFileName << '\n';
                spriteDataPatch << binaryLabel << "_end:" << '\n';

                spriteDataPatch << "\tprint \"Data pointer  $\",hex(!oldDataPointer),\" : $\",hex(!newDataPointer)"
                                << '\n';
                spriteDataPatch << "\tprint \"Data size     $\",hex(!oldDataSize),\" : $\",hex(" << binaryLabel
                                << "_end-" << binaryLabel << "-1)" << '\n';

                spriteDataPatch.close();

                if (MeiMei::debug) {
                    std::cout << "__________________________________" << '\n';
                    std::cout << "Fixing sprite data for level " << levelAsHex << '\n';
                }

                if (!MeiMei::patch(fileName.c_str(), rom)) {
                    ERR("An error occured when patching sprite data with asar.")
                }

                if (MeiMei::debug) {
                    std::cout << "Done!" << '\n';
                }

                if (!MeiMei::keepTemp) {
                    remove(binaryFileName.c_str());
                    remove(fileName.c_str());
                }

                remapped[lv] = true;
            }
        }

        if (MeiMei::debug) {
            std::cout << "__________________________________" << "\n" << '\n';
        }

        printf("Sprite data remapped successfully.\n");
        revert = false;
    }
end:
    if (revert) {
        return 1;
    }

    return 0;
}
