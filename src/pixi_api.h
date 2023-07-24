#pragma once
#include <stdbool.h>
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
struct list_result;


enum _list_type : int {
    pixi_sprite_normal,
    pixi_sprite_cluster,
    pixi_sprite_extended,
    pixi_sprite_minor_extended,
    pixi_sprite_bounce,
    pixi_sprite_smoke,
    pixi_sprite_spinningcoin,
    pixi_sprite_score
} typedef list_type_t;
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

/// <summary>
/// Runs the complete pixi program.
/// Parses the lists and applies the sprite to a rom
/// The first 2 parameters expect exactly the same as a main() function.
/// </summary>
/// <param name="argc">Number of arguments</param>
/// <param name="argv">Arguments</param>
/// <param name="skip_first">Set to true to ignore the first entry of argv</param>
/// <returns>Exit code of the program</returns>
PIXI_EXPORT int pixi_run(int argc, const char** argv, bool skip_first);

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

/// <summary>
/// Parses a given list file with optional per-level support. The list file is searched via the current working
/// directory <para> Beware that enabling per-level support encurs in a pretty big allocation done up front.
/// </para>
/// </summary>
/// <param name="filename">Filename to parse</param>
/// <param name="per_level">Enable per-level support (at the cost of extra allocation)</param>
/// <returns>The parse result struct</returns>
PIXI_EXPORT pixi_list_result_t pixi_parse_list_file(const char* filename, bool per_level);
/// <summary>
/// Returns whether the call to pixi_parse_list_file that gave that specific result succeeded or not.
/// </summary>
/// <param name="parse_list_result">The parsed list result struct</param>
/// <returns>1 on success, 0 on failure</returns>
PIXI_EXPORT int pixi_list_result_success(pixi_list_result_t);
/// <summary>
/// Returns the sprite array corresponding to that sprite type in that specific pixi_list_result struct
/// the size of the array is written in the size out-param.
/// <para>
/// Note that the sprite pointers returned are <b>not</b> to be freed with pixi_sprite_free.
/// </para>
/// </summary>
/// <param name="parse_list_result">The parsed list result struct</param>
/// <param name="list_type">Sprite type to return</param>
/// <param name="size">Non-null pointer to a integer that will receive the size of the array</param>
/// <returns>An array of sprite pointers that can be given to any of the pixi_sprite_x apis</returns>
PIXI_EXPORT pixi_sprite_array pixi_list_result_sprite_array(pixi_list_result_t, list_type_t, int* size);
/// <summary>
/// Frees the struct associated to a call to pixi_parse_list_file.
/// </summary>
/// <param name="parse_list_result">The struct to be freed</param>
/// <returns></returns>
PIXI_EXPORT void pixi_list_result_free(pixi_list_result_t);

/// <summary>
/// Parses a given json sprite. If the filepath is relative it'll be searched in the current working directory
/// <para>
/// The returned pointer must be freed via a call to pixi_sprite_free
/// </para>
/// </summary>
/// <param name="filename">Filename of the sprite to parse</param>
/// <returns>A parsed sprite struct</returns>
PIXI_EXPORT pixi_sprite_t pixi_parse_json_sprite(const char* filename);
/// <summary>
/// Parses a given cfg sprite. If the filepath is relative it'll be searched in the current working directory
/// <para>
/// The returned pointer must be freed via a call to pixi_sprite_free
/// </para>
/// </summary>
/// <param name="filename">Filename of the sprite to parse</param>
/// <returns>A parsed sprite struct</returns>
PIXI_EXPORT pixi_sprite_t pixi_parse_cfg_sprite(const char* filename);
/// <summary>
/// Frees a sprite struct allocated via a call to pixi_parse_{cfg|json}_sprite
/// </summary>
/// <param name="pixi_sprite">Sprite to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_sprite_free(pixi_sprite_t);
/// <summary>
/// Frees a buffer allocated via pixi_create_map16_buffer
/// </summary>
/// <param name="buffer">The buffer to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_map16_buffer(pixi_map16_t buffer);
/// <summary>
/// Frees an array allocated via pixi_map16_array
/// </summary>
/// <param name="array">The array to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_map16_array(pixi_map16_array);
/// <summary>
/// Frees an array allocated via pixi_sprite_displays
/// </summary>
/// <param name="array">The array to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_display_array(pixi_display_array);
/// <summary>
/// Frees an array allocated via pixi_sprite_collections
/// </summary>
/// <param name="array">The array to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_collection_array(pixi_collection_array);
/// <summary>
/// Frees an array allocated via pixi_display_tiles
/// </summary>
/// <param name="array">The array to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_tile_array(pixi_tile_array);
/// <summary>
/// Frees a pixi_string.
/// </summary>
/// <param name="string">The string to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_string(pixi_string string);
/// <summary>
/// Frees a pixi_byte_array
/// </summary>
/// <param name="bytearray">The byte array to free</param>
/// <returns></returns>
PIXI_EXPORT void pixi_free_byte_array(pixi_byte_array bytearray);

// Sprite information APIs

/// <summary>
/// Returns the line of the list file from which this sprite was parsed from
/// <para>
/// This value is always 0 if the sprite is obtained via manually calling pixi_parse_{json|cfg}_sprite
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>An integer indicating the line</returns>
PIXI_EXPORT int pixi_sprite_line(pixi_sprite_t);
/// <summary>
/// Returns the sprite number associated with this sprite.
/// <para>
/// This value is always 0 if the sprite is obtained via manually calling pixi_parse_{json|cfg}_sprite
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>An integer indicating the number</returns>
PIXI_EXPORT int pixi_sprite_number(pixi_sprite_t);
/// <summary>
/// Returns the level associated with this sprite.
/// <para>
/// This value is always 0x200 if the sprite is obtained via manually calling pixi_parse_{json|cfg}_sprite
/// and it is meaningless when per-level sprites are turned off.
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>An integer indicating the level</returns>
PIXI_EXPORT int pixi_sprite_level(pixi_sprite_t);
/// <summary>
/// Returns the sprite table associated with this sprite
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>A sprite table structure</returns>
PIXI_EXPORT pixi_sprite_table_t pixi_sprites_sprite_table(pixi_sprite_t);
/// <summary>
/// Returns the sprite status pointers associated with this sprite
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>A status pointers struct</returns>
PIXI_EXPORT pixi_status_pointers_t pixi_sprite_status_pointers(pixi_sprite_t);
/// <summary>
/// Returns the extended sprite cape interaction pointer associated with this sprite
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>A snes pointer</returns>
PIXI_EXPORT pixi_pointer_t pixi_extended_cape_ptr(pixi_sprite_t);
/// <summary>
/// Returns the extra byte count used when the sprite has the extra bit turned off
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>An integer indicating the byte count</returns>
PIXI_EXPORT int pixi_sprite_byte_count(pixi_sprite_t);
/// <summary>
/// Returns the extra byte count used when the sprite has the extra bit turned on
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>An integer indicating the byte count</returns>
PIXI_EXPORT int pixi_sprite_extra_byte_count(pixi_sprite_t);
/// <summary>
/// Returns the directory from which the sprite comes from
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <param name="size">An out-param that will receive the size of the returned string</param>
/// <returns>A pixi_string that doesn't need to be freed</returns>
PIXI_EXPORT pixi_string pixi_sprite_directory(pixi_sprite_t, int* size);
/// <summary>
/// Returns the asm file that the sprite refers to
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <param name="size">An out-param that will receive the size of the returned string</param>
/// <returns>A pixi_string that doesn't need to be freed</returns>
PIXI_EXPORT pixi_string pixi_sprite_asm_file(pixi_sprite_t, int* size);
/// <summary>
/// Returns the configuration file that the sprite refers to
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <param name="size">An out-param that will receive the size of the returned string</param>
/// <returns>A pixi_string that doesn't need to be freed</returns>
PIXI_EXPORT pixi_string pixi_sprite_cfg_file(pixi_sprite_t, int* size);
/// <summary>
/// Returns the map16 data associated with the sprite, this array will be empty if the sprite was a .cfg file.
/// <para>
/// The map16 data needs to be freed via a call to pixi_free_map16_array
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <param name="size">An out-param that will receive the size of the returned array</param>
/// <returns>A pixi map16 array</returns>
PIXI_EXPORT pixi_map16_array pixi_sprite_map_data(pixi_sprite_t, int* size);
/// <summary>
/// Returns the displays associated with the sprite, this array will be empty if the sprite was a .cfg file.
/// <para>
/// The display data needs to be freed via a call to pixi_free_display_array
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <param name="size">An out-param that will receive the size of the returned array</param>
/// <returns>A pixi display array</returns>
PIXI_EXPORT pixi_display_array pixi_sprite_displays(pixi_sprite_t, int* size);
/// <summary>
/// Returns the collections associated with the sprite, this array will be empty if the sprite was a .cfg file.
/// <para>
/// The collection data needs to be freed via a call to pixi_free_collection_array
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <param name="size">An out-param that will receive the size of the returned array</param>
/// <returns>A pixi collection array</returns>
PIXI_EXPORT pixi_collection_array pixi_sprite_collections(pixi_sprite_t, int* size);
/// <summary>
/// Returns the type of sprite
/// <para>
/// 0 => Sprite
/// </para>
/// <para>
/// 1 => Extended
/// </para>
/// <para>
/// 2 => Cluster
/// </para>
/// <para>
/// 3 => MinorExtended
/// </para>
/// <para>
/// 4 => Bounce
/// </para>
/// <para>
/// 5 => Smoke
/// </para>
/// <para>
/// 6 => SpinningCoin
/// </para>
/// <para>
/// 7 => Score
/// </para>
/// </summary>
/// <param name="pixi_sprite">The pixi sprite to obtain the information from</param>
/// <returns>An integer representing the type of sprite</returns>
PIXI_EXPORT int pixi_sprite_type(pixi_sprite_t);

// Tile information APIs

/// <summary>
/// Returns a tile's x offset
/// </summary>
/// <param name="pixi_tile">The tile to get the offset from</param>
/// <returns>An integer representing the offset in pixels</returns>
PIXI_EXPORT int pixi_tile_x_offset(pixi_tile_t);
/// <summary>
/// Returns a tile's y offset
/// </summary>
/// <param name="pixi_tile">The tile to get the offset from</param>
/// <returns>An integer representing the offset in pixels</returns>
PIXI_EXPORT int pixi_tile_y_offset(pixi_tile_t);
/// <summary>
/// Returns a tile's number
/// </summary>
/// <param name="pixi_tile">The tile to get the number from</param>
/// <returns>An integer representing the tile's number</returns>
PIXI_EXPORT int pixi_tile_tile_number(pixi_tile_t);
/// <summary>
/// Returns the tile's associated text
/// </summary>
/// <param name="pixi_tile">The tile to get the text from</param>
/// <param name="size">An out-param that receives the size of the string</param>
/// <returns>A pixi string</returns>
PIXI_EXPORT pixi_string pixi_tile_text(pixi_tile_t, int* size);

// Display information APIs

/// <summary>
/// Returns the display's associated description
/// </summary>
/// <param name="pixi_display">The display to get the description from</param>
/// <param name="size">An out-param that receives the size of the string</param>
/// <returns>A pixi string</returns>
PIXI_EXPORT pixi_string pixi_display_description(pixi_display_t, int* size);
/// <summary>
/// Returns the display's associated tile array
/// </summary>
/// <param name="pixi_display">The display to get the description from</param>
/// <param name="size">An out-param that receives the size of the array</param>
/// <returns>A pixi tile array</returns>
PIXI_EXPORT pixi_tile_array pixi_display_tiles(pixi_display_t, int* size);
/// <summary>
/// Returns the display's associated extra bit
/// </summary>
/// <param name="pixi_display">The display to get the extra bit from</param>
/// <returns>An int where 0 means extra bit not set and 1 means extra bit set</returns>
PIXI_EXPORT int pixi_display_extra_bit(pixi_display_t);
/// <summary>
/// Returns the display's associated X displacement
/// </summary>
/// <param name="pixi_display">The display to get the X displacement from</param>
/// <returns>An int that represents the Y displacement in pixels</returns>
PIXI_EXPORT int pixi_display_x(pixi_display_t);
/// <summary>
/// Returns the display's associated Y displacement
/// </summary>
/// <param name="pixi_display">The display to get the Y displacement from</param>
/// <returns>An int that represents the Y displacement in pixels</returns>
PIXI_EXPORT int pixi_display_y(pixi_display_t);

// Collection information APIs
/// <summary>
/// Returns the collection's associated name
/// </summary>
/// <param name="pixi_collection">The collection to get the name from</param>
/// <param name="size">An out-param that receives the size of the string</param>
/// <returns>A pixi string</returns>
PIXI_EXPORT pixi_string pixi_collection_name(pixi_collection_t, int* size);
/// <summary>
/// Returns the collection's associated extra bit status
/// </summary>
/// <param name="pixi_collection">The collection to get the extra bit from</param>
/// <returns>An int where 0 means extra bit not set and 1 means extra bit set</returns>
PIXI_EXPORT int pixi_collection_extra_bit(pixi_collection_t);
/// <summary>
/// Returns the collection's property values
/// </summary>
/// <param name="pixi_collection">The collection to get the prop values from</param>
/// <param name="size">An out-param that receives the size of the array</param>
/// <returns>A byte array with the property values</returns>
PIXI_EXPORT pixi_byte_array pixi_collection_prop(pixi_collection_t, int* size);

// Map8x8 information APIs

/// <summary>
/// Returns the 8x8 associated tile number
/// </summary>
/// <param name="pixi_map8x8">The 8x8 tile to get the tile number from</param>
/// <returns>A tile number</returns>
PIXI_EXPORT char pixi_map8x8_tile(pixi_map8x8_t);
/// <summary>
/// Returns the 8x8 associated prop value
/// </summary>
/// <param name="pixi_map8x8">The 8x8 tile to get the property value from</param>
/// <returns>The 8x8 property value</returns>
PIXI_EXPORT char pixi_map8x8_prop(pixi_map8x8_t);

// Map16 information APIs

/// <summary>
/// Returns the top left 8x8 tile of the map16 tile
/// </summary>
/// <param name="pixi_map16">The map16 tile to get the 8x8 from</param>
/// <returns>The 8x8 tile</returns>
PIXI_EXPORT pixi_map8x8_t pixi_map16_top_left(pixi_map16_t);
/// <summary>
/// Returns the bottom left 8x8 tile of the map16 tile
/// </summary>
/// <param name="pixi_map16">The map16 tile to get the 8x8 from</param>
/// <returns>The 8x8 tile</returns>
PIXI_EXPORT pixi_map8x8_t pixi_map16_bottom_left(pixi_map16_t);
/// <summary>
/// Returns the top right 8x8 tile of the map16 tile
/// </summary>
/// <param name="pixi_map16">The map16 tile to get the 8x8 from</param>
/// <returns>The 8x8 tile</returns>
PIXI_EXPORT pixi_map8x8_t pixi_map16_top_right(pixi_map16_t);
/// <summary>
/// Returns the bottom right 8x8 tile of the map16 tile
/// </summary>
/// <param name="pixi_map16">The map16 tile to get the 8x8 from</param>
/// <returns>The 8x8 tile</returns>
PIXI_EXPORT pixi_map8x8_t pixi_map16_bottom_right(pixi_map16_t);

// Status pointers information APIs

/// <summary>
/// Returns the pointer to the routine that's ran when the sprite is in carriable state
/// </summary>
/// <param name="pixi_status_pointers">The sprite status pointers to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_carriable(pixi_status_pointers_t);
/// <summary>
/// Returns the pointer to the routine that's ran when the sprite is in kicked state
/// </summary>
/// <param name="pixi_status_pointers">The sprite status pointers to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_kicked(pixi_status_pointers_t);
/// <summary>
/// Returns the pointer to the routine that's ran when the sprite is in carried state
/// </summary>
/// <param name="pixi_status_pointers">The sprite status pointers to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_carried(pixi_status_pointers_t);
/// <summary>
/// Returns the pointer to the routine that's ran when the sprite is in yoshi's mouth
/// </summary>
/// <param name="pixi_status_pointers">The sprite status pointers to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_mouth(pixi_status_pointers_t);
/// <summary>
/// Returns the pointer to the routine that's ran when the sprite is in "goal passed" state
/// </summary>
/// <param name="pixi_status_pointers">The sprite status pointers to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_status_pointers_goal(pixi_status_pointers_t);

// Sprite table information APIs

/// <summary>
/// Returns the type of sprite as seen by pixi
/// <para>
/// 0 => Normal
/// </para>
/// <para>
/// 1 => Custom
/// </para>
/// <para>
/// 2 => Generator/Shooter
/// </para>
/// <para>
/// 3+ => Other
/// </para>
/// </summary>
/// <param name="pixi_sprite_table">The sprite table to get the type from</param>
/// <returns>The type number</returns>
PIXI_EXPORT unsigned char pixi_sprite_table_type(pixi_sprite_table_t);
/// <summary>
/// Returns the sprite's act-like setting
/// </summary>
/// <param name="pixi_sprite_table">The sprite table to get the type from</param>
/// <returns>The act-like number</returns>
PIXI_EXPORT unsigned char pixi_sprite_table_actlike(pixi_sprite_table_t);
/// <summary>
/// Returns the sprite's tweak bytes
/// </summary>
/// <param name="pixi_sprite_table">The sprite table to get the tweak values from</param>
/// <param name="size">An out-param that receives the size of the array</param>
/// <returns>The byte array with the tweak values</returns>
PIXI_EXPORT pixi_byte_array pixi_sprite_table_tweak(pixi_sprite_table_t, int* size);
/// <summary>
/// Returns the sprite's INIT routine pointer
/// </summary>
/// <param name="pixi_sprite_table">The sprite table to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_sprite_table_init(pixi_sprite_table_t);
/// <summary>
/// Returns the sprite's MAIN routine pointer
/// </summary>
/// <param name="pixi_sprite_table">The sprite table to get the pointer from</param>
/// <returns>The SNES pointer to the routine</returns>
PIXI_EXPORT pixi_pointer_t pixi_sprite_table_main(pixi_sprite_table_t);
/// <summary>
/// Returns the sprite's extra property bytes
/// </summary>
/// <param name="pixi_sprite_table">The sprite table to get the extra property bytes from</param>
/// <param name="size">An out-param that receives the size of the array</param>
/// <returns>The byte array with the extra property bytes values</returns>
PIXI_EXPORT pixi_byte_array pixi_sprite_table_extra(pixi_sprite_table_t, int* size);

// Error information

/// <summary>
/// Returns pixi's last error
/// </summary>
/// <param name="size">An out-param that receives the size of the string</param>
/// <returns>A pixi string containg the error information</returns>
PIXI_EXPORT pixi_string pixi_last_error(int* size);

// Output information

/// <summary>
/// Returns pixi's complete output as if it was stdout
/// </summary>
/// <param name="size">An out-param that receives the size of the string</param>
/// <returns>A pixi string containing the entire output</returns>
PIXI_EXPORT pixi_string_array pixi_output(int* size);

/// <summary>
/// Allocates a map16 buffer to be used with pixi_generate_s16
/// The buffer is to be freed with pixi_free_map16_buffer
/// </summary>
/// <param name="size">The size of the buffer to allocate</param>
/// <returns>A newly allocated map16 buffer</returns>
PIXI_EXPORT pixi_map16_t pixi_create_map16_buffer(int size);
/// <summary>
/// Generates s16 information given a sprite and an allocated and populated map16 buffer (with pixi_create_map16_buffer) 
/// </summary>
/// <param name="spr">The sprite to generate the s16 from</param>
/// <param name="map16_buffer">The buffer to use to generate the s16 information</param>
/// <param name="map16_size">The size of the passed in buffer</param>
/// <param name="size">An out-param with the size of the returned map16 array</param>
/// <param name="map16_tile">The index of the tile where the map16 array was allocated in the map16 buffer</param>
/// <returns>The map16 array generated, to be freed with pixi_free_map16_array</returns>
PIXI_EXPORT pixi_map16_array pixi_generate_s16(pixi_sprite_t spr, pixi_map16_t map16_buffer, int map16_size, int* size,
                                               int* map16_tile);
/// <summary>
/// Generates ssc information given a sprite, an index and a map16 tile.
/// </summary>
/// <param name="spr">The sprite to generate the ssc from</param>
/// <param name="index">The index where you want this ssc information to be generated at</param>
/// <param name="map16_tile">The map16 tile given by pixi_generate_s16</param>
/// <returns>A null-terminated c-string with the SSC information, to be freed with pixi_free_string</returns>
PIXI_EXPORT pixi_string pixi_generate_ssc(pixi_sprite_t spr, int index, int map16_tile);
/// <summary>
/// Generates mwt information given a sprite, a collection and its index
/// </summary>
/// <param name="spr">The sprite to generate the mwt from</param>
/// <param name="coll">The collection to generate the mwt of</param>
/// <param name="coll_idx">The index of the collection</param>
/// <returns>A null-terminated c-string with the MWT information, to be freed with pixi_free_string</returns>
PIXI_EXPORT pixi_string pixi_generate_mwt(pixi_sprite_t spr, pixi_collection_t coll, int coll_idx);
/// <summary>
/// Generates mw2 information given a sprite and a collection
/// </summary>
/// <param name="spr">The sprite to generate the mw2 from</param>
/// <param name="coll">The collection to generate the mw2 of</param>
/// <param name="size">An out-param that will have the size of the returned array</param>
/// <returns>A byte array with the mw2 data, to be freed with pixi_free_byte_array</returns>
PIXI_EXPORT pixi_byte_array pixi_generate_mw2(pixi_sprite_t spr, pixi_collection_t coll, int* size);
#ifdef __cplusplus
}
#endif