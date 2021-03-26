#include "json.h"
#include "file_io.h"
#include "json_const.h"
#include "paths.h"
#include "structs.h"
#include "json/base64.h"
#include "json/json.hpp"

#include <fstream>
#include <cstring>
#include <algorithm>

using json = nlohmann::json;

// string clone.
// takes a c-string and returns a point to a new one. Needs to be deleted manually.
char *strcln(const char *str) {
    char *ret = new char[strlen(str) + 1];
    strcpy(ret, str);
    return ret;
}
char *strcln(std::string const &str) {
    return strcln(str.c_str());
}

bool read_json_file(sprite *spr, FILE *output) {

    json j;
    try {
        std::ifstream instr(spr->cfg_file);
        if (!instr) {
            if (output)
                fprintf(output, "Json file with name %s wasn't found, exiting\n", spr->cfg_file);
            printf("\"%s\" wasn't found, make sure to have the correct filenames in your list file\n", spr->cfg_file);
            exit(-1);
        }
        instr >> j;
    } catch (const std::exception &e) {
        if (strstr(e.what(), "parse error") != NULL) {
            printf("An error was encountered while parsing %s, please make sure that the json file has the correct "
                   "format. (error: %s)",
                   spr->cfg_file, e.what());
        } else {
            printf("An unknown error has occurred while parsing %s, please contact the developer providing a "
                   "screenshot of this error: %s\n",
                   spr->cfg_file, e.what());
        }
        exit(-1);
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
        spr->map_block_count = decoded.size() / 8;
        spr->map_data = (map16 *)strcln(decoded);

        // displays
        spr->display_count = j.at("Displays").size();
        spr->displays = new display[spr->display_count];
        int counter = 0;
        for (auto jdisplay : j.at("Displays")) {
            display *dis = spr->displays + counter;

            dis->description = strcln(jdisplay.at("Description"));

            dis->x = jdisplay.at("X");
            dis->y = jdisplay.at("Y");
            dis->x = std::clamp(dis->x, 0, 0x0F);
            dis->y = std::clamp(dis->y, 0, 0x0F);
            dis->extra_bit = jdisplay.at("ExtraBit");

            if (jdisplay.at("UseText")) {
                dis->tile_count = 1;
                dis->tiles = new tile[1];
                dis->tiles->text = strcln(jdisplay.at("DisplayText"));
            } else {
                dis->tile_count = jdisplay.at("Tiles").size();
                dis->tiles = new tile[dis->tile_count];
                int counter2 = 0;
                for (auto jtile : jdisplay.at("Tiles")) {
                    tile *til = dis->tiles + counter2;
                    til->x_offset = jtile.at("X offset");
                    til->y_offset = jtile.at("Y offset");
                    til->tile_number = jtile.at("map16 tile");
                    counter2++;
                }
            }
            counter++;
        }

        // collections
        counter = 0;
        spr->collection_count = j.at("Collection").size();
        spr->collections = new collection[spr->collection_count];
        for (auto jCollection : j.at("Collection")) {
            collection *col = spr->collections + counter;
            col->name = strcln(jCollection.at("Name"));
            col->extra_bit = jCollection.at("ExtraBit");
            for (int i = 1; i <= (col->extra_bit ? spr->extra_byte_count : spr->byte_count); i++) {
                try {
                    col->prop[i - 1] = jCollection.at("Extra Property Byte " + std::to_string(i));
                } catch (const std::out_of_range &exc) {
                    col->prop[i - 1] = 0;
                    // if it's not specified in the json just set it at 0, who cares anyway, just add a warning
                    warnings.push_back("Your json file \"" +
                                       std::filesystem::path(spr->cfg_file).filename().generic_string() +
                                       "\" is missing a definition for Extra Property Byte " + std::to_string(i) +
                                       " at collection \"" + col->name + "\"");
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
            fprintf(output, "Error when parsing json: %s", e.what());
        return false;
    }
}
