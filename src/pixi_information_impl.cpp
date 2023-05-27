#include "cfg.h"
#include "iohandler.h"
#include "json.h"
#include "lmdata.h"
#include "structs.h"

#ifdef PIXI_DLL_BUILD
#ifdef _WIN32
#define PIXI_EXPORT __declspec(dllexport)
#else
#define PIXI_EXPORT __attribute__((visibility("default")))
#endif
#else
#define PIXI_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif
enum list_type_t : int;
typedef int pixi_pointer_t;
typedef const struct list_result* pixi_list_result_t;
typedef const struct tile* pixi_tile_t;
typedef const struct display* pixi_display_t;
typedef const struct collection* pixi_collection_t;
typedef const struct map8x8* pixi_map8x8_t;
typedef const struct map16* pixi_map16_t;
typedef const struct status_pointers* pixi_status_pointers_t;
typedef const struct sprite_table* pixi_sprite_table_t;
typedef const struct sprite* pixi_sprite_t;
typedef const char* pixi_string;
typedef const char* const* pixi_string_array;
typedef const unsigned char* pixi_byte_array;
typedef const pixi_map16_t* pixi_map16_array;
typedef const pixi_display_t* pixi_display_array;
typedef const pixi_collection_t* pixi_collection_array;
typedef const pixi_tile_t* pixi_tile_array;
typedef const pixi_sprite_t* pixi_sprite_array;

PIXI_EXPORT pixi_list_result_t pixi_parse_list_file(const char* filename, bool per_level) {
    list_result* result = new list_result;
    static Paths paths{};
    std::vector<sprite> sprite_list{per_level ? MAX_SPRITE_COUNT : 0x100ull};
    std::vector<sprite> cluster_list{SPRITE_COUNT};
    std::vector<sprite> extended_list{SPRITE_COUNT};
    std::vector<sprite> minor_extended_list{LESS_SPRITE_COUNT};
    std::vector<sprite> bounce_list{LESS_SPRITE_COUNT};
    std::vector<sprite> smoke_list{LESS_SPRITE_COUNT};
    std::vector<sprite> spinningcoin_list{MINOR_SPRITE_COUNT};
    std::vector<sprite> score_list{MINOR_SPRITE_COUNT};
    std::array sprites_list_list{sprite_list.data(),         extended_list.data(), cluster_list.data(),
                                 minor_extended_list.data(), bounce_list.data(),   smoke_list.data(),
                                 spinningcoin_list.data(),   score_list.data()};
    result->success = populate_sprite_list(paths, sprites_list_list, filename);

    for (auto& sprites : result->sprite_arrays) {
        for (const auto& spr : sprite_list) {
            if (spr.asm_file.empty())
                continue;
            sprites.push_back(new sprite{spr});
        }
    }
    return result;
}

PIXI_EXPORT int pixi_list_result_success(pixi_list_result_t result) {
    return result->success;
}
PIXI_EXPORT pixi_sprite_array pixi_list_result_sprite_array(pixi_list_result_t result, list_type_t type, int* size) {
    *size = static_cast<int>(result->sprite_arrays[type].size());
    return result->sprite_arrays[type].data();
}
PIXI_EXPORT void pixi_list_result_free(pixi_list_result_t result) {
    for (int i = 0; i < FromEnum(ListType::__SIZE__); ++i) {
        for (const auto* spr : result->sprite_arrays[i]) {
            delete spr;
        }
    }
    delete result;
}

PIXI_EXPORT pixi_sprite_t pixi_parse_json_sprite(const char* filename) {
    sprite* spr = new sprite;
    spr->cfg_file = filename;
    bool res = read_json_file(spr);
    if (!res) {
        delete spr;
        return nullptr;
    }
    return spr;
}

PIXI_EXPORT pixi_sprite_t pixi_parse_cfg_sprite(const char* filename) {
    sprite* spr = new sprite;
    spr->cfg_file = filename;
    bool res = read_cfg_file(spr);
    if (!res) {
        delete spr;
        return nullptr;
    }
    return spr;
}

PIXI_EXPORT void pixi_sprite_free(pixi_sprite_t sprite_ptr) {
    auto* sp = reinterpret_cast<const sprite*>(sprite_ptr);
    delete sp;
}

PIXI_EXPORT void pixi_free_map16_buffer(pixi_map16_t buffer) {
    delete[] buffer;
}
PIXI_EXPORT void pixi_free_map16_array(pixi_map16_array array_) {
    delete[] array_;
}
PIXI_EXPORT void pixi_free_display_array(pixi_display_array array_) {
    delete[] array_;
}
PIXI_EXPORT void pixi_free_collection_array(pixi_collection_array array_) {
    delete[] array_;
}
PIXI_EXPORT void pixi_free_tile_array(pixi_tile_array array_) {
    delete[] array_;
}
PIXI_EXPORT void pixi_free_string(pixi_string string) {
    delete[] string;
}
PIXI_EXPORT void pixi_free_byte_array(pixi_byte_array bytearray) {
    delete[] bytearray;
}

// Sprite information APIs
PIXI_EXPORT int pixi_sprite_line(pixi_sprite_t pixi_sprite_ptr) {
    return pixi_sprite_ptr->line;
}
PIXI_EXPORT int pixi_sprite_number(pixi_sprite_t pixi_sprite_ptr) {
    return pixi_sprite_ptr->number;
}
PIXI_EXPORT int pixi_sprite_level(pixi_sprite_t pixi_sprite_ptr) {
    return pixi_sprite_ptr->level;
}
PIXI_EXPORT pixi_sprite_table_t pixi_sprites_sprite_table(pixi_sprite_t pixi_sprite_ptr) {
    return &pixi_sprite_ptr->table;
}
PIXI_EXPORT pixi_status_pointers_t pixi_sprite_status_pointers(pixi_sprite_t pixi_sprite_ptr) {
    return &pixi_sprite_ptr->ptrs;
}
PIXI_EXPORT pixi_pointer_t pixi_extended_cape_ptr(pixi_sprite_t pixi_sprite_ptr) {
    return pixi_sprite_ptr->extended_cape_ptr.addr();
}
PIXI_EXPORT int pixi_sprite_byte_count(pixi_sprite_t pixi_sprite_ptr) {
    return pixi_sprite_ptr->byte_count;
}
PIXI_EXPORT int pixi_sprite_extra_byte_count(pixi_sprite_t pixi_sprite_ptr) {
    return pixi_sprite_ptr->extra_byte_count;
}
PIXI_EXPORT pixi_string pixi_sprite_directory(pixi_sprite_t pixi_sprite_ptr, int* size) {
    pixi_string ptr = pixi_sprite_ptr->directory.c_str();
    *size = static_cast<int>(pixi_sprite_ptr->directory.size());
    return ptr;
}
PIXI_EXPORT pixi_string pixi_sprite_asm_file(pixi_sprite_t pixi_sprite_ptr, int* size) {
    pixi_string ptr = pixi_sprite_ptr->asm_file.c_str();
    *size = static_cast<int>(pixi_sprite_ptr->asm_file.size());
    return ptr;
}
PIXI_EXPORT pixi_string pixi_sprite_cfg_file(pixi_sprite_t pixi_sprite_ptr, int* size) {
    pixi_string str = pixi_sprite_ptr->cfg_file.c_str();
    *size = static_cast<int>(pixi_sprite_ptr->cfg_file.size());
    return str;
}
PIXI_EXPORT pixi_map16_array pixi_sprite_map_data(pixi_sprite_t pixi_sprite_ptr, int* size) {
    size_t map_data_size = pixi_sprite_ptr->map_data.size();
    pixi_map16_t* alloced = new pixi_map16_t[map_data_size];
    for (size_t i = 0; i < map_data_size; i++)
        alloced[i] = &pixi_sprite_ptr->map_data[i];
    *size = static_cast<int>(pixi_sprite_ptr->map_data.size());
    return alloced;
}
PIXI_EXPORT pixi_display_array pixi_sprite_displays(pixi_sprite_t pixi_sprite_ptr, int* size) {
    size_t disp_size = pixi_sprite_ptr->displays.size();
    pixi_display_t* alloced = new pixi_display_t[disp_size];
    for (size_t i = 0; i < disp_size; i++)
        alloced[i] = &pixi_sprite_ptr->displays[i];
    *size = static_cast<int>(pixi_sprite_ptr->displays.size());
    return alloced;
}
PIXI_EXPORT pixi_collection_array pixi_sprite_collections(pixi_sprite_t pixi_sprite_ptr, int* size) {
    size_t coll_size = pixi_sprite_ptr->collections.size();
    pixi_collection_t* alloced = new pixi_collection_t[coll_size];
    for (size_t i = 0; i < coll_size; i++)
        alloced[i] = &pixi_sprite_ptr->collections[i];
    *size = static_cast<int>(pixi_sprite_ptr->collections.size());
    return alloced;
}

PIXI_EXPORT int pixi_sprite_type(pixi_sprite_t pixi_sprite_ptr) {
    return static_cast<int>(pixi_sprite_ptr->sprite_type);
}

// Tile information APIs
PIXI_EXPORT int pixi_tile_x_offset(pixi_tile_t pixi_tile_ptr) {
    return pixi_tile_ptr->x_offset;
}
PIXI_EXPORT int pixi_tile_y_offset(pixi_tile_t pixi_tile_ptr) {
    return pixi_tile_ptr->y_offset;
}
PIXI_EXPORT int pixi_tile_tile_number(pixi_tile_t pixi_tile_ptr) {
    return pixi_tile_ptr->tile_number;
}
PIXI_EXPORT pixi_string pixi_tile_text(pixi_tile_t pixi_tile_ptr, int* size) {
    *size = static_cast<int>(pixi_tile_ptr->text.size());
    return pixi_tile_ptr->text.c_str();
}

// Display information APIs
PIXI_EXPORT pixi_string pixi_display_description(pixi_display_t pixi_display_ptr, int* size) {
    pixi_string str = pixi_display_ptr->description.c_str();
    *size = static_cast<int>(pixi_display_ptr->description.size());
    return str;
}
PIXI_EXPORT pixi_tile_array pixi_display_tiles(pixi_display_t pixi_display_ptr, int* size) {
    size_t tiles_size = pixi_display_ptr->tiles.size();
    pixi_tile_t* alloced = new pixi_tile_t[tiles_size];
    for (size_t i = 0; i < tiles_size; i++)
        alloced[i] = &pixi_display_ptr->tiles[i];
    *size = static_cast<int>(pixi_display_ptr->tiles.size());
    return alloced;
}
PIXI_EXPORT int pixi_display_extra_bit(pixi_display_t pixi_display_ptr) {
    return pixi_display_ptr->extra_bit;
}
PIXI_EXPORT int pixi_display_x(pixi_display_t pixi_display_ptr) {
    return pixi_display_ptr->x_or_index;
}
PIXI_EXPORT int pixi_display_y(pixi_display_t pixi_display_ptr) {
    return pixi_display_ptr->y_or_value;
}

// Collection information APIs
PIXI_EXPORT pixi_string pixi_collection_name(pixi_collection_t pixi_collection_ptr, int* size) {
    *size = static_cast<int>(pixi_collection_ptr->name.size());
    return pixi_collection_ptr->name.c_str();
}
PIXI_EXPORT int pixi_collection_extra_bit(pixi_collection_t pixi_collection_ptr) {
    return pixi_collection_ptr->extra_bit;
}
PIXI_EXPORT pixi_byte_array pixi_collection_prop(pixi_collection_t pixi_collection_ptr, int* size) {
    *size = 12;
    return pixi_collection_ptr->prop;
}

// Map8x8 information APIs
PIXI_EXPORT char pixi_map8x8_tile(pixi_map8x8_t pixi_map8x8_ptr) {
    return pixi_map8x8_ptr->tile;
}
PIXI_EXPORT char pixi_map8x8_prop(pixi_map8x8_t pixi_map8x8_ptr) {
    return pixi_map8x8_ptr->prop;
}

// Map16 information APIs
PIXI_EXPORT pixi_map8x8_t pixi_map16_top_left(pixi_map16_t pixi_map16_ptr) {
    return &pixi_map16_ptr->top_left;
}
PIXI_EXPORT pixi_map8x8_t pixi_map16_bottom_left(pixi_map16_t pixi_map16_ptr) {
    return &pixi_map16_ptr->bottom_left;
}
PIXI_EXPORT pixi_map8x8_t pixi_map16_top_right(pixi_map16_t pixi_map16_ptr) {
    return &pixi_map16_ptr->top_right;
}
PIXI_EXPORT pixi_map8x8_t pixi_map16_bottom_right(pixi_map16_t pixi_map16_ptr) {
    return &pixi_map16_ptr->bottom_right;
}

// Status pointers information APIs
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_carriable(pixi_status_pointers_t pixi_status_pointers_ptr) {
    return pixi_status_pointers_ptr->carriable.addr();
}
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_kicked(pixi_status_pointers_t pixi_status_pointers_ptr) {
    return pixi_status_pointers_ptr->kicked.addr();
}
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_carried(pixi_status_pointers_t pixi_status_pointers_ptr) {
    return pixi_status_pointers_ptr->carried.addr();
}
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_mouth(pixi_status_pointers_t pixi_status_pointers_ptr) {
    return pixi_status_pointers_ptr->mouth.addr();
}
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_goal(pixi_status_pointers_t pixi_status_pointers_ptr) {
    return pixi_status_pointers_ptr->goal.addr();
}

// Sprite table information APIs
PIXI_EXPORT unsigned char pixi_sprite_table_type(pixi_sprite_table_t pixi_sprite_table_ptr) {
    return pixi_sprite_table_ptr->type;
}
PIXI_EXPORT unsigned char pixi_sprite_table_actlike(pixi_sprite_table_t pixi_sprite_table_ptr) {
    return pixi_sprite_table_ptr->actlike;
}
PIXI_EXPORT pixi_byte_array pixi_sprite_table_tweak(pixi_sprite_table_t pixi_sprite_table_ptr, int* size) {
    *size = 6;
    return pixi_sprite_table_ptr->tweak;
}
PIXI_EXPORT pixi_pointer_t pixi_sprite_table_init(pixi_sprite_table_t pixi_sprite_table_ptr) {
    return pixi_sprite_table_ptr->init.addr();
}
PIXI_EXPORT pixi_pointer_t pixi_sprite_table_main(pixi_sprite_table_t pixi_sprite_table_ptr) {
    return pixi_sprite_table_ptr->main.addr();
}
PIXI_EXPORT pixi_byte_array pixi_sprite_table_extra(pixi_sprite_table_t pixi_sprite_table_ptr, int* size) {
    *size = 2;
    return pixi_sprite_table_ptr->extra;
}
PIXI_EXPORT pixi_string pixi_last_error(int* size) {
    const auto& last_error = iohandler::get_global().last_error();
    *size = static_cast<int>(last_error.size());
    return last_error.c_str();
}
PIXI_EXPORT pixi_string_array pixi_output(int* size) {
    const auto& history = iohandler::get_global().output_lines();
    *size = static_cast<int>(history.size());
    return history.data();
}

PIXI_EXPORT pixi_map16_t pixi_create_map16_buffer(int size) {
    const map16* map16_array = new map16[size];
    return map16_array;
}
PIXI_EXPORT pixi_map16_array pixi_generate_s16(pixi_sprite_t spr, pixi_map16_t map16_buffer, int map16_size, int* size,
                                               int* map16_tile) {
    const auto [tileno, span] = generate_s16_data(spr, map16_buffer, map16_size);
    const size_t sz = span.size();
    *size = static_cast<int>(sz);
    *map16_tile = static_cast<int>(tileno);
    pixi_map16_t* alloced = new pixi_map16_t[sz];
    for (size_t i = 0; i < sz; i++)
        alloced[i] = &span[i];
    return alloced;
}
PIXI_EXPORT pixi_string pixi_generate_ssc(pixi_sprite_t spr, int index, int map16_tile) {
    const auto ssc = generate_ssc_data(reinterpret_cast<const sprite*>(spr), index, map16_tile);
    char* c = new char[ssc.size() + 1];
    strcpy(c, ssc.c_str());
    return c;
}
PIXI_EXPORT pixi_string pixi_generate_mwt(pixi_sprite_t spr, pixi_collection_t coll, int coll_idx) {
    const auto mwt = generate_mwt_data(reinterpret_cast<const sprite*>(spr), *reinterpret_cast<const collection*>(coll),
                                       coll_idx == 0);
    char* c = new char[mwt.size() + 1];
    strcpy(c, mwt.c_str());
    return c;
}
PIXI_EXPORT pixi_byte_array pixi_generate_mw2(pixi_sprite_t spr, pixi_collection_t coll, int* size) {
    const auto mw2 =
        generate_mw2_data(reinterpret_cast<const sprite*>(spr), *reinterpret_cast<const collection*>(coll));
    unsigned char* uc = new unsigned char[mw2.size()];
    memcpy(uc, mw2.data(), mw2.size());
    *size = static_cast<int>(mw2.size());
    return uc;
}
#ifdef __cplusplus
}
#endif