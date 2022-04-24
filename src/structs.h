#ifndef STRUCTS_H
#define STRUCTS_H

#include "file_io.h"
#include "config.h"
#include <cstring>
#include <vector>
#include <string>

// use 16MB ROM size to avoid asar malloc/memcpy on 8MB of data per block.
constexpr auto MAX_ROM_SIZE = 16 * 1024 * 1024;

constexpr auto RTL_BANK = 0x01;
constexpr auto RTL_HIGH = 0x80;
constexpr auto RTL_LOW = 0x21;

// 10 per level, 200 level + 100 global
constexpr auto MAX_SPRITE_COUNT = 0x2100;

struct pointer {
    unsigned char lowbyte = RTL_LOW;   // point to RTL
    unsigned char highbyte = RTL_HIGH; //
    unsigned char bankbyte = RTL_BANK; //

    pointer() = default;
    explicit pointer(int snes) {
        lowbyte = (unsigned char)(snes & 0xFF);
        highbyte = (unsigned char)((snes >> 8) & 0xFF);
        bankbyte = (unsigned char)((snes >> 16) & 0xFF);
    }
    pointer(const pointer &) = default;
    ~pointer() = default;
    [[nodiscard]] bool is_empty() const {
        return lowbyte == RTL_LOW && highbyte == RTL_HIGH && bankbyte == RTL_BANK;
    }

    [[nodiscard]] int addr() const {
        return (bankbyte << 16) + (highbyte << 8) + lowbyte;
    }
};

struct tile {
    int x_offset = 0;
    int y_offset = 0;
    int tile_number = 0;
    std::string text{};
};

struct gfx_info {
    int gfx_files[4] = {0x7F, 0x7F, 0x7F, 0x7F};
};

enum class display_type { XYPosition, ExtensionByte };

struct display {
    std::string description{};
    std::vector<tile> tiles{};
    bool extra_bit = false;
    int x_or_index = 0;
    int y_or_value = 0;
    std::vector<gfx_info> gfx_files{};
};

struct collection {
    std::string name{};
    bool extra_bit = false;
    unsigned char prop[12] = {0}; // why was this 4 again?
};

struct map8x8 {
    char tile = 0;
    char prop = 0;
};

struct map16 {
    map8x8 top_left;
    map8x8 bottom_left;
    map8x8 top_right;
    map8x8 bottom_right;
};

struct status_pointers { // the order of these actually matters
    pointer carriable;
    pointer kicked;
    pointer carried;
    pointer mouth;
    pointer goal;
};

// 00: type {0=tweak,1=custom,2=generator/shooter, 3+=other}
// 3+ can only be gotten when using the new cfg editor
// 01: "acts like"
// 02-07: tweaker bytes
// 08-10: init pointer
// 11-13: main pointer
// 14: extra property byte 1
// 15: extra property byte 2
struct sprite_table {
    unsigned char type = 0;
    unsigned char actlike = 0;
    unsigned char tweak[6] = {0};
    pointer init;
    pointer main;
    unsigned char extra[2] = {0};
};

struct sprite {
    int line = 0;
    int number = 0;
    int level = 0x200;
    sprite_table table;
    status_pointers ptrs;
    pointer extended_cape_ptr;
    int byte_count = 0;
    int extra_byte_count = 0;

    const char *directory = nullptr;
    const char *asm_file = nullptr;
    const char *cfg_file = nullptr;

    std::vector<map16> map_data{};

    display_type disp_type = display_type::XYPosition;
    std::vector<display> displays{};

    std::vector<collection> collections{};

    ListType sprite_type = ListType::Sprite; 
    ~sprite();
    void print(FILE *stream);
};

int get_pointer(const unsigned char *data, int address, int size = 3, int bank = 0x00);

enum class MapperType { lorom, sa1rom, fullsa1rom };

struct ROM {
    inline static const int sa1banks[8] = {0 << 20, 1 << 20, -1, -1, 2 << 20, 3 << 20, -1, -1};
    unsigned char *data;
    unsigned char *real_data;
    char *name;
    int size;
    int header_size;
    MapperType mapper;

    [[nodiscard]] bool open(const char *n);
    void close();

    int pc_to_snes(int address, bool header = true) const;
    int snes_to_pc(int address, bool header = true) const;

    pointer pointer_snes(int address, int size = 3, int bank = 0x00) const;
    unsigned char read_byte(int addr) const;
    unsigned short read_word(int addr) const;
    unsigned int read_long(int addr) const;
    void read_data(unsigned char *dst, size_t size, int addr) const;
    ~ROM();
};

void set_pointer(pointer *p, int address);
bool is_empty_table(sprite *spr, int size);
char *trim(char *text);

#endif