#include "json.h"
#include "file_io.h"
#include "json_const.h"
#include "paths.h"
#include "structs.h"
#include "json/base64.h"
#include <nlohmann/json.hpp>
#include <algorithm>
#include <cstring>
#include <fstream>

using json = nlohmann::json;

bool read_json_file(sprite *spr, FILE *output) {

    json j;
    try {
        std::ifstream instr(spr->cfg_file);
        if (!instr) {
            if (output)
                fprintf(output, "Json file with name %s wasn't found, exiting\n", spr->cfg_file);
            printf("\"%s\" wasn't found, make sure to have the correct filenames in your list file\n", spr->cfg_file);
            return false;
        }
        instr >> j;
    } catch (const std::exception &e) {
        if (strstr(e.what(), "parse error") != nullptr) {
            printf("An error was encountered while parsing %s, please make sure that the json file has the correct "
                   "format. (error: %s)",
                   spr->cfg_file, e.what());
        } else {
            printf("An unknown error has occurred while parsing %s, please contact the developer providing a "
                   "screenshot of this error: %s\n",
                   spr->cfg_file, e.what());
        }
        return false;
    }

    try {

        spr->table.actlike = j.at("ActLike");
        spr->table.type = j.at("Type");

        // values will only be filled for non-tweak sprites.
        if (spr->table.type) {
            std::string asm_file = j.at("AsmFile");
            spr->asm_file = append_to_dir(spr->cfg_file, asm_file.c_str());

            spr->table.extra[0] = j.at("Extra Property Byte 1");
            spr->table.extra[1] = j.at("Extra Property Byte 2");

            spr->byte_count = j.at("Additional Byte Count (extra bit clear)");
            spr->extra_byte_count = j.at("Additional Byte Count (extra bit set)");
            spr->byte_count = std::clamp(spr->byte_count, 0, 15);
            spr->extra_byte_count = std::clamp(spr->extra_byte_count, 0, 15);
        }
        spr->table.tweak[0] = j1656(j);
        spr->table.tweak[1] = j1662(j);
        spr->table.tweak[2] = j166e(j);
        spr->table.tweak[3] = j167a(j);
        spr->table.tweak[4] = j1686(j);
        spr->table.tweak[5] = j190f(j);

        std::string decoded = base64_decode(j.at("Map16"));
        size_t map_block_count = decoded.size() / sizeof(map16);
        spr->map_data.resize(map_block_count);
        memcpy(spr->map_data.data(), decoded.c_str(), map_block_count * sizeof(map16));
        // displays
        auto disp_type_it = j.find("DisplayType");
        if (disp_type_it != j.end()) {
            auto disp_type = disp_type_it->get<std::string>();
            if (disp_type == "XY") {
                spr->disp_type = display_type::XYPosition;
            } else if (disp_type == "ExByte") {
                spr->disp_type = display_type::ExtensionByte;
            } else {
                throw std::domain_error("Unknown type of display " + disp_type);
            }
        } else {
            spr->disp_type = display_type::XYPosition;
        }
        spr->displays.resize(j.at("Displays").size());
        int counter = 0;
        for (auto &jdisplay : j.at("Displays")) {
            auto &dis = spr->displays[counter];

            dis.description = jdisplay.at("Description").get<std::string>();

            if (spr->disp_type == display_type::ExtensionByte) {
                dis.x_or_index = jdisplay.at("Index");
                dis.x_or_index =
                    std::clamp(dis.x_or_index, 0, (dis.extra_bit ? spr->extra_byte_count : spr->byte_count)) + 3;
                dis.y_or_value = jdisplay.at("Value");
            } else {
                dis.x_or_index = jdisplay.at("X");
                dis.y_or_value = jdisplay.at("Y");
                dis.x_or_index = std::clamp(dis.x_or_index, 0, 0x0F);
                dis.y_or_value = std::clamp(dis.y_or_value, 0, 0x0F);
            }

            // for each X,Y or extension byte based appearance check if they have gfx information
            auto gfxinfo = jdisplay.find("GFXInfo");
            if (gfxinfo != jdisplay.end()) {
                auto &gfxarray = *gfxinfo;
                dis.gfx_files.resize(gfxarray.size());
                size_t n = 0;
                for (const auto &gfx : gfxarray) {
                    bool separate = gfx.at("Separate");
                    for (int gfx_idx = 0; gfx_idx < 4; gfx_idx++) {
                        try {
                            dis.gfx_files[n].gfx_files[gfx_idx] =
                                gfx.at(std::to_string(gfx_idx)).get<int>() | (separate ? 0x8000 : 0);
                        } catch (const std::out_of_range &) {
                            dis.gfx_files[n].gfx_files[gfx_idx] = 0x7F;
                        }
                    }
                    n++;
                }
            }

            if (jdisplay.at("UseText")) {
                dis.tiles.push_back({0, 0, 0, jdisplay.at("DisplayText")});
            } else {
                dis.tiles.resize(jdisplay.at("Tiles").size());
                int counter2 = 0;
                for (auto &jtile : jdisplay.at("Tiles")) {
                    auto &til = dis.tiles[counter2];
                    til.x_offset = jtile.at("X offset");
                    til.y_offset = jtile.at("Y offset");
                    til.tile_number = jtile.at("map16 tile");
                    counter2++;
                }
            }
            counter++;
        }

        // collections
        counter = 0;
        spr->collections.resize(j.at("Collection").size());
        for (auto &jCollection : j.at("Collection")) {
            auto &col = spr->collections.emplace_back();
            col.name = jCollection.at("Name").get<std::string>();
            col.extra_bit = jCollection.at("ExtraBit");
            for (int i = 1; i <= (col.extra_bit ? spr->extra_byte_count : spr->byte_count); i++) {
                try {
                    col.prop[i - 1] = jCollection.at("Extra Property Byte " + std::to_string(i));
                } catch (const std::out_of_range &) {
                    col.prop[i - 1] = 0;
                    // if it's not specified in the json just set it at 0, who cares anyway, just add a warning
                    warnings.push_back("Your json file \"" +
                                       std::filesystem::path(spr->cfg_file).filename().generic_string() +
                                       "\" is missing a definition for Extra Property Byte " + std::to_string(i) +
                                       " at collection \"" + col.name + "\"");
                }
            }
            counter++;
        }

        if (output) {
            fprintf(output, "Parsed %s\n", spr->cfg_file);
        }

        return true;
    } catch (const std::exception &e) {
        if (output)
            fprintf(output, "Error when parsing json: %s\n", e.what());
        else
            fprintf(stdout, "Error when parsing json: %s\n", e.what());
        return false;
    }
}
