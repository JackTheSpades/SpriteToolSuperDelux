#pragma once
#include "structs.h"
#include "map16.h"
#include <utility>
#include <span>
#include <vector>
#include <string>

bool generate_lm_data(const sprite (&sprite_list)[MAX_SPRITE_COUNT], map16 (&map)[MAP16_SIZE],
                      unsigned char (&extra_bytes)[0x200], FILE* ssc, FILE* mwt, FILE* mw2, FILE* s16, bool perlevel);

std::pair<size_t, std::span<const map16>> generate_s16_data(const sprite* spr, const map16* map, size_t map_size);
std::string generate_mwt_data(const sprite* spr, const collection& c, bool first);
std::vector<char> generate_mw2_data(const sprite* spr, const collection& c);
std::string generate_ssc_data(const sprite* spr, int i, size_t map16_tile);