#ifndef MAP16_H
#define MAP16_H

#define MAP16_SIZE 0x3800

struct map16;

int find_free_map(map16 *map, int count);
void read_map16(map16 *map, const char *file);

#endif