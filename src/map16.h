#ifndef MAP16_H
#define MAP16_H
#include <cstddef>
#define MAP16_SIZE 0x3800

struct map16;

size_t find_free_map(const map16 *map, size_t map_size, size_t count);
void read_map16(map16 *map, const char *file);

#endif