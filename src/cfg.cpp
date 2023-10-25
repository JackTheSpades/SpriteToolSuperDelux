#include "cfg.h"
#include "iohandler.h"
#include "paths.h"
#include "structs.h"
#include <cstdio>

#include <array>
#include <filesystem>
#include <fstream>
#include <string>

/*
Supported CFG File format

<type>
<sprite num>
<tweak 0> <tweak 1> <tweak 2> <tweak 3> <tweak 4> <tweak 5>
<prop 0> <prop 1>
<asm file>
<ex. byte count>:<ex. byte count with extra bit>

alternatively the last line can be a single number
in this case pixi will still accept the cfg file
but will just set both ex. byte counts to 0.
*/

constexpr size_t handler_limit = 6;
using cfg_handler = bool (*)(const std::string&, sprite*);

bool cfg_type(const std::string& line, sprite* spr);
bool cfg_actlike(const std::string& line, sprite* spr);
bool cfg_tweak(const std::string& line, sprite* spr);
bool cfg_prop(const std::string& line, sprite* spr);
bool cfg_asm(const std::string& line, sprite* spr);
bool cfg_extra(const std::string& line, sprite* spr);

namespace fs = std::filesystem;

bool read_cfg_file(sprite* spr) {
    iohandler& io = iohandler::get_global();

    std::array<cfg_handler, handler_limit> handlers{cfg_type, cfg_actlike, cfg_tweak, cfg_prop, cfg_asm, cfg_extra};

    size_t line = 0;

    std::ifstream cfg_stream(spr->cfg_file);
    if (!cfg_stream) {
        io.error("Can't find CFG file %s, aborting insertion", spr->cfg_file.c_str());
        return false;
    }
    std::string current_line;
    while (std::getline(cfg_stream, current_line) && line < handlers.size()) {
        trim(current_line);
        if (current_line.empty() || current_line.length() == 0)
            continue;

        if (!handlers[line++](current_line, spr))
            return false;
    };

    std::string sprite_name = fs::path{spr->cfg_file}.filename().replace_extension("").generic_string();

    spr->collections.push_back(collection{.name = sprite_name + " (extra bit clear)", .extra_bit = false, .prop = {}});
    spr->collections.push_back(collection{.name = sprite_name + " (extra bit set)", .extra_bit = true, .prop = {}});
    spr->displays.push_back(
        display{.description = sprite_name + " (extra bit clear)", .tiles = {tile{}}, .extra_bit = false});
    spr->displays.push_back(
        display{.description = sprite_name + " (extra bit set)", .tiles = {tile{}}, .extra_bit = true});

    io.debug("Parsed: %s, %zu lines\n", spr->cfg_file.c_str(), line - 1);

    return true;
}

bool cfg_type(const std::string& line, sprite* spr) {
    if (sscanf(line.data(), "%hhx", &spr->table.type) != 1)
        return false;
    return true;
}
bool cfg_actlike(const std::string& line, sprite* spr) {
    if (sscanf(line.data(), "%hhx", &spr->table.actlike) != 1)
        return false;
    return true;
}
bool cfg_tweak(const std::string& line, sprite* spr) {
    int nfields = sscanf(line.data(), "%hhx %hhx %hhx %hhx %hhx %hhx", &spr->table.tweak[0], &spr->table.tweak[1],
                         &spr->table.tweak[2], &spr->table.tweak[3], &spr->table.tweak[4], &spr->table.tweak[5]);
    if (nfields != 6)
        return false;
    return true;
}
bool cfg_prop(const std::string& line, sprite* spr) {
    if (sscanf(line.data(), "%hhx %hhx", &spr->table.extra[0], &spr->table.extra[1]) != 2)
        return false;
    return true;
}
bool cfg_asm(const std::string& line, sprite* spr) {
    spr->asm_file = append_to_dir(spr->cfg_file, line);
    return true;
}

std::pair<uint8_t, uint8_t> read_byte_count(const std::string& line) {
    size_t pos = line.find(':');
    if (pos == std::string::npos) {
        // if there's no ':' it means that this cfg is old, because of backwards compat we just return 0 and ignore
        return {uint8_t{0}, uint8_t{0}};
    }
    std::pair<uint8_t, uint8_t> values{};
    try {
        int first = std::stoi(line, nullptr, 16);
        int second = std::stoi(line.substr(pos + 1), nullptr, 16);
        values.first = static_cast<uint8_t>(first);
        values.second = static_cast<uint8_t>(second);
    } catch (const std::invalid_argument&) {
        throw std::invalid_argument("Hex values for extra byte count in CFG file were not valid base 16 integers");
    } catch (const std::out_of_range&) {
        throw std::invalid_argument("Hex values for extra byte count in CFG file were out of range of a valid integer");
    }
    if (values.first > 12 || values.second > 12) {
        throw std::invalid_argument("Hex value for extra byte count in CFG file out of range, valid range is 00-0C");
    }
    return values;
}

bool cfg_extra(const std::string& line, sprite* spr) {
    try {
        auto [bc, ebc] = read_byte_count(line);
        spr->byte_count = bc;
        spr->extra_byte_count = ebc;
    } catch (const std::invalid_argument &e) {
        iohandler::get_global().error("Error in reading extra byte settings for file %s, error was \"%s\"\n",
                                      spr->cfg_file.c_str(), e.what());
        return false;
    }
    return true;
}
