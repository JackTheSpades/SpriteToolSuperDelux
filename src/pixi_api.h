#pragma once

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

struct tile;
struct display;
struct collection;
struct map8x8;
struct map16;
struct status_pointers;
struct sprite_table;
struct sprite;

typedef int pixi_pointer_t;
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

/// <summary>
/// Runs the complete pixi program.
/// Parses the lists and applies the sprite to a rom
/// The first 2 parameters expect exactly the same as a main() function.
/// </summary>
/// <param name="argc">Number of arguments</param>
/// <param name="argv">Arguments</param>
/// <returns>Exit code of the program</returns>
PIXI_EXPORT int pixi_run(int argc, const char** argv);

/// <summary>
/// Returns the API version as 100*edition + 10*major + minor
/// For example: 1.32 would return as 132
/// </summary>
/// <returns>API version as 100*edition + 10*major + minor</returns>
PIXI_EXPORT int pixi_api_version();

/// <summary>
/// Checks equality between the expected (passed in) API version values and the current ones.
/// </summary>
/// <param name="version_edition">Edition (e.g. for Pixi 1.32, it would be 1)</param>
/// <param name="version_major">Major revision (e.g. for Pixi 1.32 it would be 3)</param>
/// <param name="version_minor">Minor revision (e.g. for Pixi 1.32 it would be 2)</param>
/// <returns>1 on equality, 0 otherwise</returns>
PIXI_EXPORT int pixi_check_api_version(int version_edition, int version_major, int version_minor);

PIXI_EXPORT pixi_sprite_t pixi_parse_json_sprite(const char* filename);
PIXI_EXPORT pixi_sprite_t pixi_parse_cfg_sprite(const char* filename);
PIXI_EXPORT void pixi_sprite_free(pixi_sprite_t);
PIXI_EXPORT void pixi_free_map16_array(pixi_map16_array);
PIXI_EXPORT void pixi_free_display_array(pixi_display_array);
PIXI_EXPORT void pixi_free_collection_array(pixi_collection_array);
PIXI_EXPORT void pixi_free_tile_array(pixi_tile_array);
PIXI_EXPORT void pixi_free_string(pixi_string string);
PIXI_EXPORT void pixi_free_byte_array(pixi_byte_array bytearray);

// Sprite information APIs
PIXI_EXPORT int pixi_sprite_line(pixi_sprite_t);
PIXI_EXPORT int pixi_sprite_number(pixi_sprite_t);
PIXI_EXPORT int pixi_sprite_level(pixi_sprite_t);
PIXI_EXPORT pixi_sprite_table_t pixi_sprites_sprite_table(pixi_sprite_t);
PIXI_EXPORT pixi_status_pointers_t pixi_sprite_status_pointers(pixi_sprite_t);
PIXI_EXPORT pixi_pointer_t pixi_extended_cape_ptr(pixi_sprite_t);
PIXI_EXPORT int pixi_sprite_byte_count(pixi_sprite_t);
PIXI_EXPORT int pixi_sprite_extra_byte_count(pixi_sprite_t);
PIXI_EXPORT pixi_string pixi_sprite_directory(pixi_sprite_t, int* size);
PIXI_EXPORT pixi_string pixi_sprite_asm_file(pixi_sprite_t, int* size);
PIXI_EXPORT pixi_string pixi_sprite_cfg_file(pixi_sprite_t, int* size);
PIXI_EXPORT pixi_map16_array pixi_sprite_map_data(pixi_sprite_t, int* size);
PIXI_EXPORT pixi_display_array pixi_sprite_displays(pixi_sprite_t, int* size);
PIXI_EXPORT pixi_collection_array pixi_sprite_collections(pixi_sprite_t, int* size);
PIXI_EXPORT int pixi_sprite_type(pixi_sprite_t);

// Tile information APIs
PIXI_EXPORT int pixi_tile_x_offset(pixi_tile_t);
PIXI_EXPORT int pixi_tile_y_offset(pixi_tile_t);
PIXI_EXPORT int pixi_tile_tile_number(pixi_tile_t);
PIXI_EXPORT pixi_string pixi_tile_text(pixi_tile_t, int* size);

// Display information APIs
PIXI_EXPORT pixi_string pixi_display_description(pixi_display_t, int* size);
PIXI_EXPORT pixi_tile_array pixi_display_tiles(pixi_display_t, int* size);
PIXI_EXPORT int pixi_display_extra_bit(pixi_display_t);
PIXI_EXPORT int pixi_display_x(pixi_display_t);
PIXI_EXPORT int pixi_display_y(pixi_display_t);

// Collection information APIs
PIXI_EXPORT pixi_string pixi_collection_name(pixi_collection_t, int* size);
PIXI_EXPORT int pixi_collection_extra_bit(pixi_collection_t);
PIXI_EXPORT pixi_byte_array pixi_collection_prop(pixi_collection_t, int* size);

// Map8x8 information APIs
PIXI_EXPORT char pixi_map8x8_tile(pixi_map8x8_t);
PIXI_EXPORT char pixi_map8x8_prop(pixi_map8x8_t);

// Map16 information APIs
PIXI_EXPORT pixi_map8x8_t pixi_map16_top_left(pixi_map16_t);
PIXI_EXPORT pixi_map8x8_t pixi_map16_bottom_left(pixi_map16_t);
PIXI_EXPORT pixi_map8x8_t pixi_map16_top_right(pixi_map16_t);
PIXI_EXPORT pixi_map8x8_t pixi_map16_bottom_right(pixi_map16_t);

// Status pointers information APIs
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_carriable(pixi_status_pointers_t);
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_kicked(pixi_status_pointers_t);
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_carried(pixi_status_pointers_t);
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_mouth(pixi_status_pointers_t);
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_goal(pixi_status_pointers_t);

// Sprite table information APIs
PIXI_EXPORT unsigned char pixi_sprite_table_type(pixi_sprite_table_t);
PIXI_EXPORT unsigned char pixi_sprite_table_actlike(pixi_sprite_table_t);
PIXI_EXPORT pixi_byte_array pixi_sprite_table_tweak(pixi_sprite_table_t, int* size);
PIXI_EXPORT pixi_pointer_t pixi_sprite_table_init(pixi_sprite_table_t);
PIXI_EXPORT pixi_pointer_t pixi_sprite_table_main(pixi_sprite_table_t);
PIXI_EXPORT pixi_byte_array pixi_sprite_table_extra(pixi_sprite_table_t, int* size);

// Error information
PIXI_EXPORT pixi_string pixi_last_error(int* size);

// Output information
PIXI_EXPORT pixi_string_array pixi_output(int* size);

PIXI_EXPORT pixi_map16_array pixi_create_map16_array(int size);
PIXI_EXPORT pixi_map16_array pixi_generate_s16(pixi_sprite_t spr, pixi_map16_array map16_array, int map16_size,
                                               int* size, int* map16_tile);
PIXI_EXPORT pixi_string pixi_generate_ssc(pixi_sprite_t spr, int index, int map16_tile);
PIXI_EXPORT pixi_string pixi_generate_mwt(pixi_sprite_t spr, pixi_collection_t coll, int coll_idx);
PIXI_EXPORT pixi_byte_array pixi_generate_mw2(pixi_sprite_t spr, pixi_collection_t coll, int* size);
#ifdef __cplusplus
}
#endif