#include "cfg.h"
#include "paths.h"
#include "structs.h"
#include <cstdio>

#include <array>
#include <fstream>
#include <string>

void cfg_type(const std::string &line, sprite *spr);
void cfg_actlike(const std::string &line, sprite *spr);
void cfg_tweak(const std::string &line, sprite *spr);
void cfg_prop(const std::string &line, sprite *spr);
void cfg_asm(const std::string &line, sprite *spr);
void cfg_extra(const std::string &line, sprite *spr);

bool read_cfg_file(sprite *spr, FILE *output) {

    std::array handlers{cfg_type, cfg_actlike, cfg_tweak, cfg_prop, cfg_asm, cfg_extra};

    size_t line = 0;

    std::ifstream cfg_stream(spr->cfg_file);
    if (!cfg_stream) {
        error("Can't find CFG file %s, aborting insertion", spr->cfg_file);
    }
    std::string current_line;
    while (std::getline(cfg_stream, current_line) && line < handlers.size()) {
        trim(current_line);
        if (current_line.empty() || current_line.length() == 0)
            continue;

        handlers[line++](current_line.c_str(), spr);
    };

    if (output) {
        fprintf(output, "Parsed: %s, %zu lines\n", spr->cfg_file, line - 1);
    }

    return true;
}

void cfg_type(const std::string &line, sprite *spr) {
    sscanf(line.data(), "%hhx", &spr->table.type);
}
void cfg_actlike(const std::string &line, sprite *spr) {
    sscanf(line.data(), "%hhx", &spr->table.actlike);
}
void cfg_tweak(const std::string &line, sprite *spr) {
    sscanf(line.data(), "%hhx %hhx %hhx %hhx %hhx %hhx", &spr->table.tweak[0], &spr->table.tweak[1],
           &spr->table.tweak[2], &spr->table.tweak[3], &spr->table.tweak[4], &spr->table.tweak[5]);
}
void cfg_prop(const std::string &line, sprite *spr) {
    sscanf(line.data(), "%hhx %hhx", &spr->table.extra[0], &spr->table.extra[1]);
}
void cfg_asm(const std::string &line, sprite *spr) {

    spr->asm_file = append_to_dir(spr->cfg_file, line.data());
}

std::pair<int, int> read_byte_count(const std::string &line) {
    size_t pos = line.find(':');
    if (pos == std::string::npos) {
        // if there's no ':' it means that this cfg is old, because of backwards compat we just return 0 and ignore
        return {0, 0};
    }
    std::pair<int, int> values{};
    try {
        int first = std::stoi(line, nullptr, 16);
        int second = std::stoi(line.substr(pos + 1), nullptr, 16);
        values.first = first;
        values.second = second;
    } catch (...) {
        throw std::invalid_argument("Hex values for extra byte count in CFG file were wrongly formatted");
    }
    if (values.first > 12 || values.second > 12) {
        throw std::invalid_argument("Hex value for extra byte count in CFG file out of range, valid range is 00-0C");
    }
    return values;
}

void cfg_extra(const std::string &line, sprite *spr) {
    try {
        auto values = read_byte_count(line);
        spr->byte_count = values.first;
        spr->extra_byte_count = values.second;
    } catch (const std::invalid_argument &e) {
        error("Error in reading extra byte settings for file %s, error was \"%s\"\n", spr->cfg_file, e.what());
    }
}
