#include "pixi_api.h"
#include <filesystem>
#include <fstream>
#include <gtest/gtest.h>

#ifdef _WIN32
// clang-format off
#define _CRTDBG_MAP_ALLOC
#include <Windows.h>
#include <stdlib.h>
#include <DbgHelp.h>
// clang-format on
struct WinCheckMemLeak {
    _CrtMemState begin_state{};
    _CrtMemState end_state{};
    _CrtMemState diff{};
    WinCheckMemLeak() {
        _CrtMemCheckpoint(&begin_state);
    }
    ~WinCheckMemLeak() {
        _CrtMemCheckpoint(&end_state);
        if (_CrtMemDifference(&diff, &begin_state, &end_state)) {
            _CrtMemDumpStatistics(&diff);
            _CrtDumpMemoryLeaks();
        }
    }
};
#else
struct WinCheckMemLeak {};
#endif

TEST(PixiUnitTests, CFGParsing) {
    WinCheckMemLeak leakchecker{};
    pixi_sprite_t cfg_spr = pixi_parse_cfg_sprite("test.cfg");
    ASSERT_NE(cfg_spr, nullptr);
    int size = 0;
    ASSERT_STREQ(pixi_sprite_asm_file(cfg_spr, &size), "test.asm");
    pixi_sprite_table_t table = pixi_sprites_sprite_table(cfg_spr);
    ASSERT_EQ(pixi_sprite_table_type(table), 1);
    ASSERT_EQ(pixi_sprite_table_actlike(table), 0x36);
    pixi_byte_array tbl = pixi_sprite_table_tweak(table, &size);
    ASSERT_EQ(size, 6);
    unsigned char expected_tbl[]{0x00, 0x0D, 0x93, 0x01, 0x11, 0x40};
    for (int i = 0; i < size; i++) {
        ASSERT_EQ(expected_tbl[i], tbl[i]);
    }
    int byte_count = pixi_sprite_byte_count(cfg_spr);
    EXPECT_EQ(byte_count, 2);
    int extra_byte_count = pixi_sprite_extra_byte_count(cfg_spr);
    EXPECT_EQ(extra_byte_count, 3);
    pixi_sprite_free(cfg_spr);
}

TEST(PixiUnitTests, JsonParsing) {
    WinCheckMemLeak leakchecker{};
    pixi_sprite_t json_spr = pixi_parse_json_sprite("test.json");
    ASSERT_NE(json_spr, nullptr);
    int size = 0;
    ASSERT_STREQ(pixi_sprite_asm_file(json_spr, &size), "test.asm");
    pixi_display_array displays = pixi_sprite_displays(json_spr, &size);
    ASSERT_EQ(size, 1);
    ASSERT_STREQ(pixi_display_description(displays[0], &size), "This is a disassembly of sprite 9A - Sumo Brother.");
    ASSERT_FALSE(pixi_display_extra_bit(displays[0]));
    pixi_tile_array tiles = pixi_display_tiles(displays[0], &size);
    ASSERT_EQ(size, 4);
    ASSERT_EQ(pixi_tile_x_offset(tiles[0]), -12);
    ASSERT_EQ(pixi_tile_tile_number(tiles[0]), 478);
    pixi_free_tile_array(tiles);
    pixi_free_display_array(displays);
    pixi_collection_array collections = pixi_sprite_collections(json_spr, &size);
    ASSERT_EQ(size, 1);
    ASSERT_STREQ(pixi_collection_name(collections[0], &size), "Sumo Brother Disassembly");
    pixi_free_collection_array(collections);
    pixi_sprite_free(json_spr);
}

namespace fs = std::filesystem;

TEST(PixiUnitTests, PixiFullRun) {
    std::string_view list_contents{"00 test.json\n01 test.cfg"};
    fs::copy_file("base.smc", "PixiFullRun.smc", fs::copy_options::overwrite_existing);
    fs::copy_file("test.json", "sprites/test.json", fs::copy_options::overwrite_existing);
    fs::copy_file("test.asm", "sprites/test.asm", fs::copy_options::overwrite_existing);
    fs::copy_file("test.cfg", "sprites/test.cfg", fs::copy_options::overwrite_existing);
    {
        std::ofstream list_file{"list.txt", std::ios::trunc};
        list_file << list_contents;
    }
    const char* argv[] = {"PixiFullRun.smc"};
    ASSERT_EQ(pixi_run(sizeof(argv) / sizeof(argv[0]), argv, false), EXIT_SUCCESS);
}

TEST(PixiUnitTests, PixiFullRunPerLevel) {
    std::string_view list_contents{"BA test.json\n012:BA test.cfg"};
    fs::copy_file("base.smc", "PixiFullRunPerLevel.smc", fs::copy_options::overwrite_existing);
    fs::copy_file("test.json", "sprites/test.json", fs::copy_options::overwrite_existing);
    fs::copy_file("test.asm", "sprites/test.asm", fs::copy_options::overwrite_existing);
    fs::copy_file("test.cfg", "sprites/test.cfg", fs::copy_options::overwrite_existing);
    {
        std::ofstream list_file{"list.txt", std::ios::trunc};
        list_file << list_contents;
    }
    const char* argv[] = {"-pl", "PixiFullRunPerLevel.smc"};
    ASSERT_EQ(pixi_run(sizeof(argv) / sizeof(argv[0]), argv, false), EXIT_SUCCESS);
}

TEST(PixiUnitTests, PixiFullRunPerLevelFail) {
    std::string_view list_contents{"BA test.json\nBA:012 test.json"};
    fs::copy_file("base.smc", "PixiFullRunPerLevelFail.smc", fs::copy_options::overwrite_existing);
    fs::copy_file("test.json", "sprites/test.json", fs::copy_options::overwrite_existing);
    fs::copy_file("test.asm", "sprites/test.asm", fs::copy_options::overwrite_existing);
    fs::copy_file("test.cfg", "sprites/test.cfg", fs::copy_options::overwrite_existing);
    {
        std::ofstream list_file{"list.txt", std::ios::trunc};
        list_file << list_contents;
    }
    const char* argv[] = {"-pl", "PixiFullRunPerLevelFail.smc"};
    ASSERT_EQ(pixi_run(sizeof(argv) / sizeof(argv[0]), argv, false), EXIT_FAILURE);
    int size = 0;
    constexpr std::string_view expected_error{
        "Error on list line 2: Per-level sprite valid range is B0-BF, was given 12 instead\n"};
    pixi_string error = pixi_last_error(&size);
    ASSERT_EQ(size, expected_error.size());
    ASSERT_STREQ(error, expected_error.data());
}

TEST(PixiUnitTests, LMDataTest) {
    WinCheckMemLeak leakchecker{};
    constexpr const char expected_ssc[] =
        "00 0020 This is a disassembly of sprite 9A - Sumo Brother.\n00 0022 -12,1,1DE 4,1,1DF 2,-15,1CF -4,17,1CE\n";
	// start and end bytes not included (they're global, not per-sprite)
    constexpr unsigned char expected_mw2[] = {/* 0x00, */ 0x79, 0x70, 0x00 /*, 0xff */};
    constexpr const char expected_mwt[] = "00\tSumo Brother Disassembly\n";
	
    pixi_sprite_t json_spr = pixi_parse_json_sprite("test.json");
    ASSERT_NE(json_spr, nullptr);
    pixi_map16_array buf = pixi_create_map16_array(0xFF);
    int size = 0;
    int map16_tile = 0;
	// the map16 of this sprite is empty, so 0, 0 and null are expected.
    pixi_map16_array maps = pixi_generate_s16(json_spr, buf, 0xFF, &size, &map16_tile);
    EXPECT_EQ(map16_tile, 0);
    EXPECT_EQ(size, 0);
    EXPECT_EQ(maps, nullptr);
    pixi_string ssc = pixi_generate_ssc(json_spr, 0, map16_tile);
    EXPECT_STREQ(ssc, expected_ssc);
    int coll_size = 0;
    pixi_collection_array collections = pixi_sprite_collections(json_spr, &coll_size);
	EXPECT_EQ(coll_size, 1);
    pixi_string mwt = pixi_generate_mwt(json_spr, collections[0], 0);
    EXPECT_STREQ(mwt, expected_mwt);
	int mw2_size = 0;
    pixi_byte_array mw2 = pixi_generate_mw2(json_spr, collections[0], &mw2_size);
    EXPECT_EQ(mw2_size, sizeof(expected_mw2));
    EXPECT_EQ(memcmp(mw2, expected_mw2, mw2_size), 0);
	
    pixi_free_map16_array(buf);
    pixi_free_collection_array(collections);
    pixi_free_string(ssc);
    pixi_free_string(mwt);
    pixi_free_byte_array(mw2);
    pixi_sprite_free(json_spr);
}