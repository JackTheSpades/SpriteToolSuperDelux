#include "structs.h"
#include <cctype>
#include <iomanip>
#include <sstream>
#include <string.h>


inline const char *const BOOL_STR(bool b) {
    return b ? "true" : "false";
}

void ROM::open(const char *n) {
    name = new char[strlen(n) + 1]();
    strcpy(name, n);
    FILE *file = ::open(name, "r+b"); // call global open
    size = file_size(file);
    header_size = size & 0x7FFF;
    size -= header_size;
    data = read_all(name, false, MAX_ROM_SIZE + header_size);
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
}

void ROM::close() {
    write_all(data, name, size + header_size);
    delete[] data;
    delete[] name;
    data = nullptr; // assign to nullptr so that when the dtor is called and these already got freed the delete[] is a
                    // no-op
    name = nullptr;
}

// stolen from GPS, as most of the rest of the code of this cursed tool
// actually these ones are stolen from asar, an even more cursed tool
int ROM::pc_to_snes(int address, bool header) {
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

int ROM::snes_to_pc(int address, bool header) {

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

pointer ROM::pointer_snes(int address, int size, int bank) {
    return pointer(::get_pointer(data, snes_to_pc(address), size, bank));
}
pointer ROM::pointer_pc(int address, int size, int bank) {
    return pointer(::get_pointer(data, address, size, bank));
}

unsigned char ROM::read_byte(int addr) {
    return real_data[addr];
}
unsigned short ROM::read_word(int addr) {
    return real_data[addr] | (real_data[addr + 1] << 8);
}
unsigned int ROM::read_long(int addr) {
    return real_data[addr] | (real_data[addr + 1] << 8) | (real_data[addr + 2] << 16);
}
void ROM::write_byte(int addr, unsigned char val) {
    real_data[addr] = val;
}
void ROM::write_word(int addr, unsigned short val) {
    real_data[addr] = val & 0xFF;
    real_data[addr + 1] = (val >> 8) & 0xFF;
}
void ROM::write_long(int addr, unsigned int val) {
    real_data[addr] = val & 0xFF;
    real_data[addr + 1] = (val >> 8) & 0xFF;
    real_data[addr + 2] = (val >> 16) & 0xFF;
}
void ROM::write_data(unsigned char *data, size_t size, int addr) {
    memcpy(real_data + addr, data, size);
}
void ROM::read_data(unsigned char *dst, size_t size, int addr) {
    if (data == nullptr)
        data = (unsigned char *)malloc(sizeof(unsigned char) * size);
    memcpy(dst, real_data + addr, size);
}

void set_pointer(pointer *p, int address) {
    p->lowbyte = (char)(address & 0xFF);
    p->highbyte = (char)((address >> 8) & 0xFF);
    p->bankbyte = (char)((address >> 16) & 0xFF);
}

ROM::~ROM() {
    delete[] data;
    delete[] name;
}

simple_string get_line(const char *text, int offset) {
    simple_string string;
    if (!text[offset]) {
        return string;
    }
    string.length = strcspn(text + offset, "\r\n") + 1;
    string.data = new char[string.length]();
    strncpy(string.data, text + offset, string.length - 1);
    return string;
}

bool is_empty_table(sprite *spr, int size) {
    for (int i = 0; i < size; i++) {
        if (!spr[i].table.init.is_empty() || !spr[i].table.main.is_empty())
            return false;
    }
    return true;
}

int get_pointer(unsigned char *data, int address, int size, int bank) {
    address = (data[address]) | (data[address + 1] << 8) | ((data[address + 2] << 16) * (size - 2));
    return address | (bank << 16);
}

char *trim(char *text) {
    while (isspace(*text)) { // trim front
        text++;
    }
    for (int i = strlen(text); isspace(text[i - 1]); i--) { // trim back
        text[i - 1] = 0;
    }
    return text;
}

sprite::~sprite() {
    if (asm_file)
        delete[] asm_file;
    if (cfg_file)
        delete[] cfg_file;
    if (map_data)
        delete[] map_data;
    if (displays)
        delete[] displays;
    if (collections)
        delete[] collections;
}

void sprite::print(FILE *stream) {
    fprintf(stream, "Type:       %02X\n", table.type);
    fprintf(stream, "ActLike:    %02X\n", table.actlike);
    fprintf(stream, "Tweak:      %02X, %02X, %02X, %02X, %02X, %02X\n", table.tweak[0], table.tweak[1], table.tweak[2],
            table.tweak[3], table.tweak[4], table.tweak[5]);

    // not needed for tweaks
    if (table.type) {
        fprintf(stream, "Extra:      %02X, %02X\n", table.extra[0], table.extra[1]);
        fprintf(stream, "ASM File:   %s\n", asm_file);
        fprintf(stream, "Byte Count: %d, %d\n", byte_count, extra_byte_count);
    }

    if (map_block_count) {
        fprintf(stream, "Map16:\n");
        unsigned char *mapdata = (unsigned char *)map_data;
        for (int i = 0; i < map_block_count * 8; i++) {
            if ((i % 8) == 0)
                fprintf(stream, "\t");
            fprintf(stream, "%02X, ", (int)mapdata[i]);
            if ((i % 8) == 7)
                fprintf(stream, "\n");
        }
    }

    if (display_count) {
        fprintf(stream, "Displays:\n");
        for (int i = 0; i < display_count; i++) {
            display *d = displays + i;
            fprintf(stream, "\tX: %d, Y: %d, Extra-Bit: %s\n", d->x, d->y, BOOL_STR(d->extra_bit));
            fprintf(stream, "\tDescription: %s\n", d->description);
            for (int j = 0; j < d->tile_count; j++) {
                tile *t = d->tiles + j;
                if (t->text)
                    fprintf(stream, "\t\t%d,%d,*%s*\n", t->x_offset, t->y_offset, t->text);
                else
                    fprintf(stream, "\t\t%d,%d,%X\n", t->x_offset, t->y_offset, t->tile_number);
            }
        }
    }

    if (display_count) {
        fprintf(stream, "Collections:\n");
        for (int i = 0; i < collection_count; i++) {
            collection *c = collections + i;
            std::stringstream coll;
            coll << "\tExtra-Bit: " << BOOL_STR(c->extra_bit) << ", Property Bytes: ( ";
            for (int j = 0; j < (c->extra_bit ? extra_byte_count : byte_count); j++) {
                coll << std::hex << std::uppercase << std::setw(2) << std::setfill('0') << static_cast<int>(c->prop[j])
                     << " ";
            }
            coll << ") Name: " << c->name << std::endl;
            fprintf(stream, "%s", coll.str().c_str());
        }
    }
}

tile::~tile() {
    if (text)
        delete[] text;
}

display::~display() {
    if (description)
        delete[] description;
    if (tiles)
        delete[] tiles;
}

collection::~collection() {
    if (name)
        delete[] name;
}
