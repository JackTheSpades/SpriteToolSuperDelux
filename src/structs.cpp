#include "structs.h"
#include <cctype>
#include <cstring>
#include <iomanip>
#include <sstream>
#include "libconsole/libconsole.h"

const char *BOOL_STR(bool b) {
    return b ? "true" : "false";
}

bool ROM::open(const char* n) {
    size_t len = libconsole::bytelen(n) + 1;
    name.resize(len);
    std::memcpy(name.data(), n, len);
    return open();
}

void ROM::close() {
    (void)write_all(data, name, size + header_size);
    delete[] data;
    data = nullptr; // assign to nullptr so that when the dtor is called and these already got freed the delete[] is a
                    // no-op
}

bool ROM::open() {
    FILE* file = ::open(name.data(), "r+b"); // call global open
    if (file == nullptr) {
        data = nullptr;
        return false;
    }
    size = static_cast<int>(file_size(file));
    header_size = size & 0x7FFF;
    size -= header_size;
    data = read_all(name.data(), false, MAX_ROM_SIZE + header_size);
    if (data == nullptr)
        return false;
    fclose(file);
    real_data = data + header_size;
    if (real_data[0x7fd5] == 0x23) {
        if (real_data[0x7fd7] == 0x0D) {
            mapper = MapperType::fullsa1rom;
        } else {
            mapper = MapperType::sa1rom;
        }
    } else {
        mapper = MapperType::lorom;
    }
    return true;
}

// stolen from GPS, as most of the rest of the code of this cursed tool
// actually these ones are stolen from asar, an even more cursed tool
int ROM::pc_to_snes(int address, bool header) const {
    if (header)
        address -= header_size;

    if (mapper == MapperType::lorom) {
        return ((address << 1) & 0x7F0000) | (address & 0x7FFF) | 0x8000;
    } else if (mapper == MapperType::sa1rom) {
        for (int i = 0; i < 8; i++) {
            if (sa1banks[i] == (address & 0x700000)) {
                return 0x008000 | (i << 21) | ((address & 0x0F8000) << 1) | (address & 0x7FFF);
            }
        }
    } else if (mapper == MapperType::fullsa1rom) {
        if ((address & 0x400000) == 0x400000) {
            return address | 0xC00000;
        }
        if ((address & 0x600000) == 0x000000) {
            return ((address << 1) & 0x3F0000) | 0x8000 | (address & 0x7FFF);
        }
        if ((address & 0x600000) == 0x200000) {
            return 0x800000 | ((address << 1) & 0x3F0000) | 0x8000 | (address & 0x7FFF);
        }
    }
    return -1;
}

int ROM::snes_to_pc(int address, bool header) const {

    if (mapper == MapperType::lorom) {
        if ((address & 0xFE0000) == 0x7E0000 || (address & 0x408000) == 0x000000 || (address & 0x708000) == 0x700000)
            return -1;
        address = (address & 0x7F0000) >> 1 | (address & 0x7FFF);
    } else if (mapper == MapperType::sa1rom) {
        if ((address & 0x408000) == 0x008000) {
            address = sa1banks[(address & 0xE00000) >> 21] | ((address & 0x1F0000) >> 1) | (address & 0x007FFF);
        } else if ((address & 0xC00000) == 0xC00000) {
            address = sa1banks[((address & 0x100000) >> 20) | ((address & 0x200000) >> 19)] | (address & 0x0FFFFF);
        } else {
            address = -1;
        }
    } else if (mapper == MapperType::fullsa1rom) {
        if ((address & 0xC00000) == 0xC00000) {
            address = (address & 0x3FFFFF) | 0x400000;
        } else if ((address & 0xC00000) == 0x000000 || (address & 0xC00000) == 0x800000) {
            if ((address & 0x008000) == 0x000000)
                return -1;
            address = (address & 0x800000) >> 2 | (address & 0x3F0000) >> 1 | (address & 0x7FFF);
        } else {
            return -1;
        }
    } else {
        return -1;
    }

    return address + (header ? header_size : 0);
}

pointer ROM::pointer_snes(int address, int bank) const {
    int pc_address = snes_to_pc(address);
    int ptr = (data[pc_address]) | (data[pc_address + 1] << 8) | (data[pc_address + 2] << 16);
    return pointer{ptr | (bank << 16)};
}

unsigned char ROM::read_byte(int addr) const {
    return real_data[addr];
}
unsigned short ROM::read_word(int addr) const {
    return real_data[addr] | (real_data[addr + 1] << 8);
}
unsigned int ROM::read_long(int addr) const {
    return real_data[addr] | (real_data[addr + 1] << 8) | (real_data[addr + 2] << 16);
}

void ROM::read_data(unsigned char *dst, size_t wsize, int addr) const {
    if (dst == nullptr)
        dst = (unsigned char *)malloc(sizeof(unsigned char) * wsize);
    memcpy(dst, real_data + addr, wsize);
}

ROM::~ROM() {
    delete[] data;
}

bool is_empty_table(std::span<sprite> sprites) {
    for (const auto& sprite : sprites) {
        if (sprite.has_empty_table())
            return false;
    }
    return true;
}

bool sprite::has_empty_table() const {
    return table.init.is_empty() && table.main.is_empty();
}

sprite::~sprite() {
    if (asm_file)
        delete[] asm_file;
    if (cfg_file)
        delete[] cfg_file;
}

void sprite::print(FILE *stream) {
    cfprintf(stream, "Type:       %02X\n", table.type);
    cfprintf(stream, "ActLike:    %02X\n", table.actlike);
    cfprintf(stream, "Tweak:      %02X, %02X, %02X, %02X, %02X, %02X\n", table.tweak[0], table.tweak[1], table.tweak[2],
            table.tweak[3], table.tweak[4], table.tweak[5]);

    // not needed for tweaks
    if (table.type) {
        cfprintf(stream, "Extra:      %02X, %02X\n", table.extra[0], table.extra[1]);
        cfprintf(stream, "ASM File:   %s\n", asm_file);
        cfprintf(stream, "Byte Count: %d, %d\n", byte_count, extra_byte_count);
    }

    if (!map_data.empty()) {
        cfprintf(stream, "Map16:\n");
        auto print_map16 = [stream](const map16 &map) {
            cfprintf(stream, "\t%02X, %02X, %02X, %02X, %02X, %02X, %02X, %02X\n", map.top_left.tile, map.top_left.prop,
                    map.bottom_left.tile, map.bottom_left.prop, map.top_right.tile, map.top_right.prop,
                    map.bottom_right.tile, map.bottom_right.prop);
        };
        for (const auto &m : map_data) {
            print_map16(m);
        }
    }

    if (!displays.empty()) {
        cfprintf(stream, "Displays:\n");
        for (const auto &d : displays) {
            cfprintf(stream, "\tX: %d, Y: %d, Extra-Bit: %s\n", d.x_or_index, d.y_or_value, BOOL_STR(d.extra_bit));
            cfprintf(stream, "\tDescription: %s\n", d.description.c_str());
            for (const auto &t : d.tiles) {
                if (t.text.size())
                    cfprintf(stream, "\t\t%d,%d,*%s*\n", t.x_offset, t.y_offset, t.text.c_str());
                else
                    cfprintf(stream, "\t\t%d,%d,%X\n", t.x_offset, t.y_offset, t.tile_number);
            }
        }
    }

    if (!collections.empty()) {
        cfprintf(stream, "Collections:\n");
        for (const auto &c : collections) {
            std::stringstream coll;
            coll << "\tExtra-Bit: " << BOOL_STR(c.extra_bit) << ", Property Bytes: ( ";
            for (int j = 0; j < (c.extra_bit ? extra_byte_count : byte_count); j++) {
                coll << std::hex << std::uppercase << std::setw(2) << std::setfill('0') << static_cast<int>(c.prop[j])
                     << " ";
            }
            coll << ") Name: " << c.name << std::endl;
            cfprintf(stream, "%s", coll.str().c_str());
        }
    }
}