#include "cfg.h"
#include "paths.h"
#include "structs.h"
#include <stdio.h>

#include <fstream>
#include <iostream>
#include <string>

typedef void (*linehandler)(const char *, sprite *, int &, void *);

void cfg_type(const char *line, sprite *spr, int &handle, void *);
void cfg_actlike(const char *line, sprite *spr, int &handle, void *);
void cfg_tweak(const char *line, sprite *spr, int &handle, void *);
void cfg_prop(const char *line, sprite *spr, int &handle, void *);
void cfg_asm(const char *line, sprite *spr, int &handle, void *);
void cfg_extra(const char *line, sprite *spr, int &handle, void *);

bool read_cfg_file(sprite *spr, FILE *output) {

    const int handlelimit = 6;
    linehandler handlers[handlelimit];

    // functions that parse lines
    handlers[0] = &cfg_type;    // parse line 1 of cfg file
    handlers[1] = &cfg_actlike; // parse line 2 etc...
    handlers[2] = &cfg_tweak;
    handlers[3] = &cfg_prop;
    handlers[4] = &cfg_asm;
    handlers[5] = &cfg_extra;

    int line = 0;

    int count = 0;
    const char *cfg = (char *)read_all(spr->cfg_file, true);
    std::ifstream cfg_stream(spr->cfg_file);
    std::string current_line;
    while (std::getline(cfg_stream, current_line) && line < handlelimit) {
        trim(current_line);
        if (current_line.empty() || current_line.length() == 0)
            continue;

        handlers[line](current_line.c_str(), spr, line, &count);

        if (line < 0) {
            delete[] cfg;
            return false;
        }
    };

    if (output) {
        fprintf(output, "Parsed: %s, %d lines\n", spr->cfg_file, line - 1);
    }

    delete[] cfg;
    return true;
}

void cfg_type(const char *line, sprite *spr, int &handle, void *) {
    sscanf(line, "%hhx", &spr->table.type);
    handle++;
}
void cfg_actlike(const char *line, sprite *spr, int &handle, void *) {
    sscanf(line, "%hhx", &spr->table.actlike);
    handle++;
}
void cfg_tweak(const char *line, sprite *spr, int &handle, void *) {
    sscanf(line, "%hhx %hhx %hhx %hhx %hhx %hhx", &spr->table.tweak[0], &spr->table.tweak[1], &spr->table.tweak[2],
           &spr->table.tweak[3], &spr->table.tweak[4], &spr->table.tweak[5]);
    handle++;
}
void cfg_prop(const char *line, sprite *spr, int &handle, void *) {
    sscanf(line, "%hhx %hhx", &spr->table.extra[0], &spr->table.extra[1]);
    handle++;
}
void cfg_asm(const char *line, sprite *spr, int &handle, void *) {

    spr->asm_file = append_to_dir(spr->cfg_file, line);
    handle++;
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
        throw std::invalid_argument("Hex values for extra byte count in CFG file where wrongly formatted");
    }
    if (values.first > 12 || values.second > 12) {
        throw std::invalid_argument("Hex value for extra byte count in CFG file out of range, valid range is 00-0C");
    }
    return values;
}

void cfg_extra(const char *line, sprite *spr, int &handle, void *) {
    handle++;

    std::string thisLine(line);
    try {
        auto values = read_byte_count(thisLine);
        spr->byte_count = values.first;
        spr->extra_byte_count = values.second;
    } catch (const std::invalid_argument &e) {
        printf("%s\n", e.what());
        handle = -1;
    }
    return;
}
