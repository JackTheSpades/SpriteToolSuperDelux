#include "json.h"
#include "file_io.h"
#include "iohandler.h"
#include "json_const.h"
#include "paths.h"
#include "structs.h"
#include "json/base64.h"
#include <algorithm>
#include <cstring>
#include <fstream>
#include <nlohmann/json.hpp>
#include <filesystem>

using json = nlohmann::json;

bool read_json_file(sprite* spr) {
    iohandler& io = iohandler::get_global();
    json j;
    try {
        std::ifstream instr(spr->cfg_file);
        if (!instr) {
            io.error("JSON file \"%s\" wasn't found, make sure to have the correct filenames in your list file\n",
                     spr->cfg_file.c_str());
            return false;
        }
        instr >> j;
    } catch (const json::parse_error& err) {
        // https://json.nlohmann.me/api/basic_json/operator_gtgt/#exceptions
        switch (err.id) {
        case 101:
            io.error("Unexpected token in json file %s, please make sure that the json file has the correct format. "
                     "Error: %s",
                     spr->cfg_file.c_str(), err.what());
            break;
        case 102:
            io.error(
                "Unicode conversion failure or surrogate error in json file %s, please make sure that the json file "
                "has the correct format. Error: %s",
                spr->cfg_file.c_str(), err.what());
            break;
        case 103:
            io.error("Unicode conversion failure in json file %s, please make sure that the json file has the correct "
                     "format. Error: %s",
                     spr->cfg_file.c_str(), err.what());
            break;
        default:
            io.error("An unexpected json parsing error was encountered (from file %s), please make sure that the json "
                     "file has the correct format. Error: %s",
                     spr->cfg_file.c_str(), err.what());
            break;
        }
        return false;
    } catch (const std::exception& e) {
        io.error(
            "An unknown error has occurred while parsing json file %s, please report the issue at " GITHUB_ISSUE_LINK
            " (provide as much info as possible): %s\n",
            spr->cfg_file.c_str(), e.what());
        return false;
    }

    try {

        spr->table.actlike = j.at("ActLike");
        spr->table.type = j.at("Type");

        // values will only be filled for non-tweak sprites.
        if (spr->table.type) {
            std::string asm_file = j.at("AsmFile");
            spr->asm_file = append_to_dir(spr->cfg_file, asm_file);

            spr->table.extra[0] = j.at("Extra Property Byte 1");
            spr->table.extra[1] = j.at("Extra Property Byte 2");

            spr->byte_count = j.at("Additional Byte Count (extra bit clear)");
            spr->extra_byte_count = j.at("Additional Byte Count (extra bit set)");
            spr->byte_count = std::clamp(spr->byte_count, uint8_t{0}, uint8_t{15});
            spr->extra_byte_count = std::clamp(spr->extra_byte_count, uint8_t{0}, uint8_t{15});
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
        if (map_block_count > 0)
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
        for (auto& jdisplay : j.at("Displays")) {
            auto& dis = spr->displays[counter];

            dis.description = jdisplay.at("Description").get<std::string>();

            if (spr->disp_type == display_type::ExtensionByte) {
                dis.x_or_index = jdisplay.at("Index");
                dis.x_or_index =
                    std::clamp(dis.x_or_index, uint8_t{0}, (dis.extra_bit ? spr->extra_byte_count : spr->byte_count)) +
                    3;
                dis.y_or_value = jdisplay.at("Value");
            } else {
                dis.x_or_index = jdisplay.at("X");
                dis.y_or_value = jdisplay.at("Y");
                dis.x_or_index = std::clamp(dis.x_or_index, uint8_t{0}, uint8_t{0x0F});
                dis.y_or_value = std::clamp(dis.y_or_value, uint8_t{0}, uint8_t{0x0F});
            }

            // for each X,Y or extension byte based appearance check if they have gfx information
            auto gfxinfo_it = jdisplay.find("GFXInfo");
            if (gfxinfo_it != jdisplay.end()) {
                auto& gfxinfo = *gfxinfo_it;
                const std::pair<size_t, std::string_view> indexes[]{{0, "0"}, {1, "1"}, {2, "2"}, {3, "3"}};
                for (const auto& [i, index] : indexes) {
                    auto gfx_it = gfxinfo.find(index);
					if (gfx_it != gfxinfo.end()) {
						auto& gfx = *gfx_it;
                        dis.gfx_files.gfx_files[i].gfx_num = gfx["Value"].get<int>();
                        dis.gfx_files.gfx_files[i].sep = gfx["Separate"].get<bool>();
					}
                }
            }

            if (jdisplay.at("UseText")) {
                dis.tiles.push_back({0, 0, 0, jdisplay.at("DisplayText")});
            } else {
                dis.tiles.resize(jdisplay.at("Tiles").size());
                int counter2 = 0;
                for (auto& jtile : jdisplay.at("Tiles")) {
                    auto& til = dis.tiles[counter2];
                    til.x_offset = jtile.at("X offset");
                    til.y_offset = jtile.at("Y offset");
                    til.tile_number = jtile.at("map16 tile");
                    counter2++;
                }
            }

            dis.extra_bit = jdisplay.at("ExtraBit").get<bool>();
            counter++;
        }

        // verify that all displays use the same extension byte index
        if (spr->displays.size() > 0 && spr->disp_type == display_type::ExtensionByte) {
            auto first_index = spr->displays.front().x_or_index;
            if (!std::all_of(spr->displays.begin(), spr->displays.end(),
                             [first_index](const display& disp) { return disp.x_or_index == first_index; })) {
                io.error("JSON logic error in %s: \nWhen using the extension byte display type, all of the displays "
                         "of one sprite must use the same extension byte index.\n",
                         spr->cfg_file.c_str());
                return false;
            }
        }

        // collections
        counter = 0;
        spr->collections.resize(j.at("Collection").size());
        for (auto& jCollection : j.at("Collection")) {
            auto& col = spr->collections[counter];
            col.name = jCollection.at("Name").get<std::string>();
            col.extra_bit = jCollection.at("ExtraBit");
            for (int i = 1; i <= (col.extra_bit ? spr->extra_byte_count : spr->byte_count); i++) {
                try {
                    col.prop[i - 1] = jCollection.at("Extra Property Byte " + std::to_string(i));
                } catch (const std::out_of_range&) {
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

        io.debug("Parsed %s\n", spr->cfg_file.c_str());

        return true;
    } catch (const std::exception& e) {
        // there are too many exception types to catch, so just catch everything
        // most of them will probably come from here https://json.nlohmann.me/api/basic_json/at/#exceptions
        io.error("Unexpected error when parsing json file %s: %s, report this at " GITHUB_ISSUE_LINK
                 " (include as much info as possible)\n",
                 spr->cfg_file.c_str(), e.what());
        return false;
    }
}
