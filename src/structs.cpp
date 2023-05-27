#include "structs.h"
#include "asar/asardll.h"
#include "file_io.h"
#include "iohandler.h"
#include <cctype>
#include <cstring>
#include <iomanip>
#include <sstream>
#include <filesystem>

namespace fs = std::filesystem;

const char* BOOL_STR(bool b) {
    return b ? "true" : "false";
}

bool patchfile::s_meimei_keep = false;
bool patchfile::s_pixi_keep = false;

patchfile::patchfile(const std::string& path, patchfile::openflags mode, bool from_mei_mei)
    : m_fs_path{path}, m_data_stream{static_cast<std::ios::openmode>(mode)}, m_from_meimei{from_mei_mei} {
    m_vfile = std::make_unique<memoryfile>();
    m_binary = (static_cast<std::ios::openmode>(mode) & std::ios::binary) != 0;
    std::transform(path.begin(), path.end(), std::back_inserter(m_path),
                   [](char c) { return static_cast<char>(std::tolower(c)); });
}

patchfile::patchfile(patchfile&& other) noexcept
    : m_fs_path{std::move(other.m_fs_path)}, m_path{std::move(other.m_path)},
      m_data_stream{std::move(other.m_data_stream)}, m_data{std::move(other.m_data)},
      m_from_meimei{other.m_from_meimei}, m_binary{other.m_binary} {
    m_vfile = std::move(other.m_vfile);
    m_vfile->buffer = m_data.c_str();
    m_vfile->length = m_data.size();
    m_vfile->path = m_path.c_str();
}

void patchfile::set_keep(bool pixi, bool meimei) {
    s_meimei_keep = meimei;
    s_pixi_keep = pixi;
}

void patchfile::fprintf(const char* format, ...) {
    va_list list{};
    va_list copy{};
    va_start(list, format);
    va_copy(copy, list);
    size_t needed_space = std::vsnprintf(nullptr, 0, format, list);
    std::string buf{};
    buf.resize(needed_space);
    std::vsnprintf(buf.data(), buf.size() + 1, format, copy);
    va_end(list);
    va_end(copy);
    m_data_stream << buf;
}

void patchfile::fwrite(const char* bindata, size_t size) {
    m_data_stream.write(bindata, size);
}

void patchfile::fwrite(const unsigned char* bindata, size_t size) {
    m_data_stream.write(reinterpret_cast<const char*>(bindata), size);
}

void patchfile::close() {
    m_data = m_data_stream.str();
    m_vfile->buffer = m_data.c_str();
    m_vfile->length = m_data.size();
    m_vfile->path = m_path.c_str();
}

patchfile::~patchfile() {
    if (m_path.empty())
        return;
    if (m_from_meimei ? s_meimei_keep : s_pixi_keep) {
        FILE* fp = open(m_fs_path.c_str(), m_binary ? "wb" : "w");
        if (fp == nullptr)
            return;
        ::fwrite(m_vfile->buffer, sizeof(char), m_vfile->length, fp);
        fclose(fp);
    } else {
        fs::path filepath{m_fs_path};
        if (fs::exists(filepath)) {
            fs::remove(filepath);
        }
    }
}

void patchfile::clear() {
    m_data_stream.str("");
    m_data.clear();
    m_vfile.reset(new memoryfile);
}

bool ROM::open(std::string n) {
    name = std::move(n);
    return open();
}

void ROM::close() {
    FILE* romfile = fopen(name.c_str(), "wb");
    if (romfile == nullptr)
        return;
    fwrite(data, sizeof(char), size + header_size, romfile);
    fclose(romfile);
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

void ROM::read_data(unsigned char* dst, size_t wsize, int addr) const {
    if (dst == nullptr)
        dst = (unsigned char*)malloc(sizeof(unsigned char) * wsize);
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

void sprite::print() {
    iohandler& io = iohandler::get_global();
    io.debug("Type:       %02X\n", table.type);
    io.debug("ActLike:    %02X\n", table.actlike);
    io.debug("Tweak:      %02X, %02X, %02X, %02X, %02X, %02X\n", table.tweak[0], table.tweak[1], table.tweak[2],
             table.tweak[3], table.tweak[4], table.tweak[5]);

    // not needed for tweaks
    if (table.type) {
        io.debug("Extra:      %02X, %02X\n", table.extra[0], table.extra[1]);
        io.debug("ASM File:   %s\n", asm_file.c_str());
        io.debug("Byte Count: %d, %d\n", byte_count, extra_byte_count);
    }

    if (!map_data.empty()) {
        io.debug("Map16:\n");
        auto print_map16 = [&io](const map16& map) {
            io.debug("\t%02X, %02X, %02X, %02X, %02X, %02X, %02X, %02X\n", map.top_left.tile, map.top_left.prop,
                     map.bottom_left.tile, map.bottom_left.prop, map.top_right.tile, map.top_right.prop,
                     map.bottom_right.tile, map.bottom_right.prop);
        };
        for (const auto& m : map_data) {
            print_map16(m);
        }
    }

    if (!displays.empty()) {
        io.debug("Displays:\n");
        for (const auto& d : displays) {
            io.debug("\tX: %d, Y: %d, Extra-Bit: %s\n", d.x_or_index, d.y_or_value, BOOL_STR(d.extra_bit));
            io.debug("\tDescription: %s\n", d.description.c_str());
            for (const auto& t : d.tiles) {
                if (t.text.size())
                    io.debug("\t\t%d,%d,*%s*\n", t.x_offset, t.y_offset, t.text.c_str());
                else
                    io.debug("\t\t%d,%d,%X\n", t.x_offset, t.y_offset, t.tile_number);
            }
        }
    }

    if (!collections.empty()) {
        io.debug("Collections:\n");
        for (const auto& c : collections) {
            std::stringstream coll;
            coll << "\tExtra-Bit: " << BOOL_STR(c.extra_bit) << ", Property Bytes: ( ";
            for (int j = 0; j < (c.extra_bit ? extra_byte_count : byte_count); j++) {
                coll << std::hex << std::uppercase << std::setw(2) << std::setfill('0') << static_cast<int>(c.prop[j])
                     << " ";
            }
            coll << ") Name: " << c.name << std::endl;
            io.debug("%s", coll.str().c_str());
        }
    }
}
#define DEFAULT_PTR ((RTL_BANK << 16) | (RTL_HIGH << 8) | (RTL_LOW))
void sprite::clear() {
    line = 0;
    number = 0;
    level = 0x200;

    table.type = 0;
    table.actlike = 0;
    memset(table.tweak, 0, sizeof(table.tweak));
    table.init = DEFAULT_PTR;
    table.main = DEFAULT_PTR;
    memset(table.extra, 0, sizeof(table.extra));

    ptrs.carriable = DEFAULT_PTR;
    ptrs.carried = DEFAULT_PTR;
    ptrs.goal = DEFAULT_PTR;
    ptrs.kicked = DEFAULT_PTR;
    ptrs.mouth = DEFAULT_PTR;

    extended_cape_ptr = DEFAULT_PTR;
    byte_count = 0;
    extra_byte_count = 0;

    directory.clear();
    asm_file.clear();
    cfg_file.clear();

    map_data.clear();

    disp_type = display_type::XYPosition;
    displays.clear();

    collections.clear();

    sprite_type = ListType::Sprite;
}
