#ifndef JSON_H
#define JSON_H

#include <cstdio>
#include <string>
#include <vector>

extern std::vector<std::string> warnings;
struct sprite;

/**
    Reads the content of a JSON file into a sprite and writes some debug info into
    output

    @param spr is the sprite which's data will be filled with the information from the cfg file
    @param output to write the debug information into, leave as nullptr for no output to be used
*/
bool read_json_file(sprite *spr);

#endif