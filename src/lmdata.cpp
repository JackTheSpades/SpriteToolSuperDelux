#include "lmdata.h"
#include "iohandler.h"
#include <sstream>
#include <cstdio>

static const sprite* from_table(const sprite (&sprite_list)[MAX_SPRITE_COUNT], int level, int number, bool perlevel) {
    if (!perlevel)
        return &sprite_list[number];

    if (level > 0x200 || number > 0xFF)
        return nullptr;
    if (level == 0x200)
        return &sprite_list[0x2000 + number];
    else if (number >= 0xB0 && number < 0xC0)
        return &sprite_list[(level * 0x10) + (number - 0xB0)];
    return nullptr;
}

std::pair<size_t, std::span<const map16>> generate_s16_data(const sprite* spr, const map16* const map, size_t map_size) {
    size_t map16_tile = find_free_map(map, map_size, spr->map_data.size());
    auto map16_span = std::span{spr->map_data.data(), spr->map_data.size()};
    return std::make_pair(map16_tile, map16_span);
}

std::string generate_mwt_data(const sprite* spr, const collection& c, bool first) {
    if (first)
        return fstring("%02X\t%s\n", spr->number, c.name.c_str());
    else
        return fstring("\t%s\n", c.name.c_str());
}

std::vector<char> generate_mw2_data(const sprite* spr, const collection& c) {
    std::vector<char> data{};
    // mw2
    // build 3 byte level format
    char c1 = 0x79 + (c.extra_bit ? 0x04 : 0);
    data.push_back(c1);
    data.push_back(0x70);
    data.push_back(spr->number);
    // add the extra property bytes
    int byte_count = (c.extra_bit ? spr->extra_byte_count : spr->byte_count);
    data.insert(data.end(), std::begin(c.prop), std::begin(c.prop) + byte_count);
    return data;
}

std::string generate_ssc_data(const sprite* spr, int i, size_t map16_tile) {
    std::stringstream ssc{};
    for (const auto& d : spr->displays) {
        // 4 digit hex value. First is Y pos (0-F) then X (0-F) then custom/extra bit combination
        // here custom bit is always set (because why the fuck not?)
        // if no description (or empty) just asm filename instead.
        int ref = 0;
        if (spr->disp_type == display_type::ExtensionByte) {
            ref = 0x20 + (d.extra_bit ? 0x10 : 0);
            if (!d.description.empty())
                ssc << fstring("%02X %1X%02X%02X %s\n", i, d.x_or_index, d.y_or_value, ref, d.description.c_str());
            else
                ssc << fstring("%02X %1X%02X%02X %s\n", i, d.x_or_index, d.y_or_value, ref, spr->asm_file);
        } else {
            ref = d.y_or_value * 0x1000 + d.x_or_index * 0x100 + 0x20 + (d.extra_bit ? 0x10 : 0);
            if (!d.description.empty())
                ssc << fstring("%02X %04X %s\n", i, ref, d.description.c_str());
            else
                ssc << fstring("%02X %04X %s\n", i, ref, spr->asm_file);
        }

        if (d.gfx_files.has_value()) {
            const int prefix = 0x20 + (d.extra_bit ? 0x10 : 0);
            const auto& gfx = d.gfx_files;
            ssc << fstring("%02X %02X ", i, prefix + 0x8);
            ssc << fstring("%X,%X,%X,%X ", gfx.gfx_files[0].value(), gfx.gfx_files[1].value(), gfx.gfx_files[2].value(),
                    gfx.gfx_files[3].value());
            ssc << '\n';
        }

        // loop over tiles and append them into the output.
        if (spr->disp_type == display_type::ExtensionByte)
            ssc << fstring("%02X %1X%02X%02X", i, d.x_or_index, d.y_or_value, ref + 2);
        else
            ssc << fstring("%02X %04X", i, ref + 2);
        for (const auto& t : d.tiles) {
            if (!t.text.empty()) {
                ssc << fstring(" 0,0,*%s*", t.text.c_str());
                break;
            } else {
                // tile numbers > 0x300 indicates it's a "custom" map16 tile, so we add the offset we got
                // earlier +0x100 because in LM these start at 0x400.
                int tile_num = t.tile_number;
                if (tile_num >= 0x300)
                    tile_num += 0x100 + static_cast<int>(map16_tile);
                // note we're using %d because x/y are signed integers here
                ssc << fstring(" %d,%d,%X", t.x_offset, t.y_offset, tile_num);
            }
        }
        ssc << '\n';
    }
    return ssc.str();
}


bool generate_lm_data(const sprite (&sprite_list)[MAX_SPRITE_COUNT], map16 (&map)[MAP16_SIZE], unsigned char (&extra_bytes)[0x200], FILE* ssc, FILE* mwt, FILE* mw2, FILE* s16, bool perlevel) {
    auto& io = iohandler::get_global();
    for (int i = 0; i < 0x100; i++) {
        auto* spr = from_table(sprite_list, 0x200, i, perlevel);
        if (!spr || (perlevel && i >= 0xB0 && i < 0xC0)) {
            extra_bytes[i] = 7; // 3 bytes + 4 extra bytes because the old one broke basically any sprite that wasn't
                                // using exactly 9 extra bytes
            extra_bytes[i + 0x100] = 7; // 12 was wrong anyway, should've been 15
        } else {
            // line number within the list file indicates we've got a filled out sprite
            if (spr->line) {
                extra_bytes[i] = (unsigned char)(3 + spr->byte_count);
                extra_bytes[i + 0x100] = (unsigned char)(3 + spr->extra_byte_count);

                //----- s16 / map16 -------------------------------------------------
                const auto [map16_tile, map16_span] = generate_s16_data(spr, map, MAP16_SIZE);
                if (map16_tile == static_cast<size_t>(-1)) {
                    io.error(
                        "There wasn't enough space in your s16 file to fit everything, was trying to fit %d blocks, "
                        "couldn't find space\n",
                        map16_span.size());
                    return false;
                }
                memcpy(map + map16_tile, map16_span.data(), map16_span.size_bytes());

                //----- ssc / display -----------------------------------------------
                std::string ssc_data = generate_ssc_data(spr, i, map16_tile);
                fprintf(ssc, "%s", ssc_data.c_str());

                //----- mwt,mw2 / collection ------------------------------------------
                bool first = true;
                for (const auto& c : spr->collections) {
                    // mw2
                    auto mw2_data = generate_mw2_data(spr, c);
                    fwrite(mw2_data.data(), 1, mw2_data.size(), mw2);
                    // mwt
                    // first one prints sprite number as well, all others just their name.
                    auto mwt_data = generate_mwt_data(spr, c, first);
                    fprintf(mwt, "%s", mwt_data.c_str());
                    first = false;
                }
                // no line means unused sprite, so just set to default 3.
            } else {
                extra_bytes[i] = 3;
                extra_bytes[i + 0x100] = 3;
            }
        }
    }
    fputc(0xFF, mw2); // binary data ends with 0xFF (see SMW level data format)
    fwrite(map, sizeof(map16), MAP16_SIZE, s16);
    return true;
}