#ifndef CFG_H
#define CFG_H

#include <stdio.h>
#include <string>
#include <algorithm>

struct sprite;

/**
	Reads the content of a CFG file into a sprite and writes some debug info into
	output

	@param spr is the sprite which's data will be filled with the information from the cfg file
	@param content of the actual cfg file
	@param dir -ectory of the asm file
	@param output to write the debug information into, leave as nullptr for no output to be used
*/

// trim from start (in place)
static inline void ltrim(std::string &s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](auto ch) {
        return !std::isspace(ch);
    }));
}

// trim from end (in place)
static inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](auto ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

// trim from both ends (in place)
static inline void trim(std::string &s) {
    ltrim(s);
    rtrim(s);
}

bool read_cfg_file(sprite* spr, FILE* output);

#endif