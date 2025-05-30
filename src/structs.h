#ifndef STRUCTS_H
#define STRUCTS_H

#ifdef ASAR_USE_DLL
#include "asar/asardll.h"
#else
#include "asar/asar.h"
#endif
#include "config.h"
#include <cstring>
#include <memory>
#include <optional>
#include <span>
#include <sstream>
#include <string>
#include <vector>

#ifndef _SAL_VERSION
#define _In_z_
#define _Printf_format_string_
#endif

// use 16MB ROM size to avoid asar malloc/memcpy on 8MB of data per block.
constexpr auto MAX_ROM_SIZE = 16 * 1024 * 1024;

constexpr auto RTL_BANK = 0x01;
constexpr auto RTL_HIGH = 0x80;
constexpr auto RTL_LOW = 0x21;

// 0x10 per level, 0x200 level + 0x100 global
constexpr size_t MAX_SPRITE_COUNT = 0x2100;
constexpr size_t SPRITE_COUNT = 0x80; // count for other sprites like cluster, ow, extended
constexpr size_t LESS_SPRITE_COUNT = 0x3F;
constexpr size_t MINOR_SPRITE_COUNT = 0x1F;

class patchfile {
    std::string m_fs_path{};
    std::string m_path{};
    std::stringstream m_data_stream{};
    std::string m_data{};
    std::unique_ptr<memoryfile> m_vfile;
    bool m_from_meimei = false;
    bool m_binary = false;

    static bool s_meimei_keep;
    static bool s_pixi_keep;

    enum class placeholder {};

    constexpr static bool om_en = std::is_enum_v<std::ios::openmode>;
    using openmode_t =
        std::conditional_t<om_en, std::underlying_type_t<std::conditional_t<om_en, std::ios::openmode, placeholder>>,
                           std::ios::openmode>;

  public:
    enum class origin { pixi, meimei };
    enum class openflags : openmode_t {
        w = std::ios::out,
        b = std::ios::binary,
        wb = std::ios::out | std::ios::binary
    };
    static void set_keep(bool pixi, bool meimei);
    explicit patchfile(const std::string& path, openflags mode = openflags::w, origin origin = origin::pixi);
    patchfile(patchfile&&) noexcept;
    patchfile& operator=(patchfile&&) = delete;
    patchfile& operator=(const patchfile&) = delete;
    patchfile(const patchfile&) = delete;
    const auto& path() const {
        return m_path;
    }
    const memoryfile& vfile() const {
        return *m_vfile;
    }
    void fprintf(_In_z_ _Printf_format_string_ const char* const format, ...);
    void fwrite(const char* bindata, size_t size);
    void fwrite(const unsigned char* bindata, size_t size);
    void close();
    void clear();
    ~patchfile();
};

// forward declarations
struct ROM;
class romdata;
class pcaddress;
class snesaddress;
struct pointer;

class pcaddress {
    friend std::hash<pcaddress>;
    friend ROM;
    friend romdata;
    int value;

  public:
    constexpr pcaddress(int val) : value{val} {};
    pcaddress(pointer ptr, const ROM& rom);
    pcaddress(snesaddress addr, const ROM& rom);
    constexpr bool operator==(const pcaddress& other) const {
        return value == other.value;
    }
    constexpr bool operator==(int other) const {
        return value == other;
    }
    constexpr pcaddress operator+(pcaddress offset) const {
        return pcaddress{value + offset.value};
    }
    constexpr pcaddress operator+(int offset) const {
        return pcaddress{value + offset};
    }
    constexpr pcaddress operator-(pcaddress offset) const {
        return pcaddress{value - offset.value};
    }
    constexpr pcaddress operator-(int offset) const {
        return pcaddress{value - offset};
    }
    constexpr int raw_value() const {
        return value;
    }
};

class snesaddress {
    friend ROM;
    friend romdata;
    int value;

  public:
    constexpr snesaddress(int val) : value{val} {};
    constexpr snesaddress(unsigned int val) : value{static_cast<int>(val)} {};
    snesaddress(pointer ptr);
    snesaddress(pcaddress addr, const ROM& rom);
    constexpr bool operator==(const snesaddress& other) const {
        return value == other.value;
    }
    constexpr bool operator==(int other) const {
        return value == other;
    }
    constexpr snesaddress operator+(snesaddress offset) const {
        return snesaddress{value + offset.value};
    }
    constexpr snesaddress operator+(int offset) const {
        return snesaddress{value + offset};
    }
    constexpr snesaddress operator-(snesaddress offset) const {
        return snesaddress{value - offset.value};
    }
    constexpr snesaddress operator-(int offset) const {
        return snesaddress{value - offset};
    }
    constexpr int raw_value() const {
        return value;
    }
};

template <> struct std::hash<pcaddress> {
    constexpr static inline std::hash<int> hasher{};
    std::size_t operator()(const pcaddress& addr) const {
        return hasher(addr.value);
    }
};

struct pointer {
    unsigned char lowbyte = RTL_LOW;   // point to RTL
    unsigned char highbyte = RTL_HIGH; //
    unsigned char bankbyte = RTL_BANK; //

    constexpr pointer() = default;
    explicit constexpr pointer(int snes) {
        lowbyte = (unsigned char)(snes & 0xFF);
        highbyte = (unsigned char)((snes >> 8) & 0xFF);
        bankbyte = (unsigned char)((snes >> 16) & 0xFF);
    }
    constexpr pointer(const pointer&) = default;
    constexpr pointer& operator=(int snes) {
        lowbyte = (unsigned char)(snes & 0xFF);
        highbyte = (unsigned char)((snes >> 8) & 0xFF);
        bankbyte = (unsigned char)((snes >> 16) & 0xFF);
        return *this;
    }
    ~pointer() = default;
    [[nodiscard]] constexpr bool is_empty() const {
        return lowbyte == RTL_LOW && highbyte == RTL_HIGH && bankbyte == RTL_BANK;
    }

    [[nodiscard]] constexpr snesaddress addr() const {
        return (bankbyte << 16) + (highbyte << 8) + lowbyte;
    }
    [[nodiscard]] constexpr int raw() const {
        return (bankbyte << 16) + (highbyte << 8) + lowbyte;
    }
};

struct tile {
    int x_offset = 0;
    int y_offset = 0;
    int tile_number = 0;
    std::string text{};
};

struct sprite;
struct list_result {
    bool success = false;
    std::vector<sprite*> sprite_arrays[FromEnum(ListType::__SIZE__)];
};

struct gfx_info {
    struct {
        uint32_t gfx_num = 0x7F;
        bool sep = false;

        uint32_t value() const {
            return sep ? gfx_num | 0x8000 : gfx_num;
        }
    } gfx_files[4] = {};
    bool has_value() const {
        return std::any_of(std::begin(gfx_files), std::end(gfx_files),
                           [](const auto& gfx) { return gfx.gfx_num != 0x7F; });
    }
};

enum class display_type : bool { XYPosition, ExtensionByte };

struct display {
    std::string description{};
    std::vector<tile> tiles{};
    bool extra_bit = false;
    uint8_t x_or_index = 0;
    uint8_t y_or_value = 0;
    gfx_info gfx_files{};
};

struct collection {
    std::string name{};
    bool extra_bit = false;
    unsigned char prop[12] = {0}; // why was this 4 again?
};

struct map8x8 {
    char tile = 0;
    char prop = 0;
    constexpr bool empty() const {
        return tile == 0 && prop == 0;
    }
};

struct map16 {
    map8x8 top_left;
    map8x8 bottom_left;
    map8x8 top_right;
    map8x8 bottom_right;
    constexpr bool empty() const {
        return top_left.empty() && bottom_left.empty() && top_right.empty() && bottom_right.empty();
    }
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
    uint8_t byte_count = 0;
    uint8_t extra_byte_count = 0;

    std::string directory{};
    std::string asm_file{};
    std::string cfg_file{};
    std::vector<map16> map_data{};

    display_type disp_type = display_type::XYPosition;
    std::vector<display> displays{};

    std::vector<collection> collections{};

    bool displays_in_lm{false};

    ListType sprite_type = ListType::Sprite;
    bool has_empty_table() const;
    void clear();
    void print();
};

enum class MapperType { lorom, sa1rom, fullsa1rom };

class romdata {
    ROM& m_rom;

  public:
    romdata(ROM& rom);
    unsigned char& operator[](pcaddress index);
    const unsigned char& operator[](pcaddress index) const;
    unsigned char& operator[](snesaddress index);
    const unsigned char& operator[](snesaddress index) const;
    unsigned char* operator+(pcaddress index);
    const unsigned char* operator+(pcaddress index) const;
    unsigned char* operator+(snesaddress index);
    const unsigned char* operator+(snesaddress index) const;
};

struct ROM {
    friend romdata;
    inline static const int sa1banks[8] = {0 << 20, 1 << 20, -1, -1, 2 << 20, 3 << 20, -1, -1};

  private:
    unsigned char* m_data = nullptr;

  public:
    romdata data{*this};
    unsigned char* unheadered_data() {
        return m_data + header_size;
    }
    std::string name;
    int size{0};
    int header_size{0};
    MapperType mapper{MapperType::lorom};

    [[nodiscard]] bool open(std::string n);
    [[nodiscard]] bool open();
    void close();

    snesaddress pc_to_snes(pcaddress address) const;
    pcaddress snes_to_pc(snesaddress address) const;

    pointer pointer_snes(snesaddress address, int bank = 0x00) const;
    unsigned char read_byte(pcaddress addr) const;
    unsigned short read_word(pcaddress addr) const;
    unsigned int read_long(pcaddress addr) const;
    void read_data(unsigned char* dst, size_t size, pcaddress addr) const;
    int get_lm_version() const;
    bool is_exlevel() const;
    std::optional<uint16_t> get_rats_size(pcaddress addr) const;
    template <typename T> T read_struct(pcaddress addr = 0) const {
        T t{};
        memcpy(&t, data + addr, sizeof(T));
        return t;
    }
    ~ROM();
};

bool is_empty_table(std::span<sprite> sprites);
[[nodiscard]] bool populate_sprite_list(const Paths& paths,
                                        const std::array<sprite*, FromEnum(ListType::__SIZE__)>& sprite_lists,
                                        std::string_view listPath, const ROM* rom);
#endif
