#ifndef MAP16_H
#define MAP16_H

#define MAP16_SIZE 0x1000

struct map8x8 {
	char tile = 0;
	char prop = 0;	//could do a bitfield, but no real need is there?
}

struct map16 {
	map8x8 top_left;
	map8x8 bottom_left;
	map8x8 top_right;
	map8x8 bottom_right;
}

map16 map = map16[MAP16_SIZE];

static const char zero[8];
int find_free_map(map16* map);

void save_map16(const char* file);
void open_map16(const char* file);

#endif MAP16_H