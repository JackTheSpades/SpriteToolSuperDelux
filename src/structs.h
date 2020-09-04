#ifndef STRUCTS_H
#define STRUCTS_H

#include <string.h>
#include "file_io.h"


//use 16MB ROM size to avoid asar malloc/memcpy on 8MB of data per block. 
#define MAX_ROM_SIZE 16*1024*1024

#define RTL_BANK 0x01
#define RTL_HIGH 0x80
#define RTL_LOW 0x21

//10 per level, 200 level + 100 global
#define MAX_SPRITE_COUNT 0x2100

struct simple_string{
	int length = 0;
	char *data = nullptr;
	simple_string() = default;
	simple_string(const simple_string&) = default;
	
	simple_string &operator=(simple_string &&move)
	{
		delete []data;
		data = move.data;
		move.data = nullptr;
		length = move.length;
		return *this;
	}
	~simple_string()
	{
		delete []data;
	}
};


struct pointer {
    unsigned char lowbyte = RTL_LOW;	//point to RTL
	unsigned char highbyte = RTL_HIGH;	//
	unsigned char bankbyte = RTL_BANK;	//
	
	pointer() = default;
	pointer(int snes) {
		lowbyte = (unsigned char)(snes & 0xFF);
		highbyte = (unsigned char)((snes >> 8) & 0xFF);
		bankbyte = (unsigned char)((snes >> 16) & 0xFF);
	}	
	pointer(const pointer&) = default;
	~pointer() = default;
	
	bool is_empty() {
		return lowbyte == RTL_LOW && highbyte == RTL_HIGH && bankbyte == RTL_BANK;
	}
	
	int addr() {
		return (bankbyte << 16) + (highbyte << 8) + lowbyte;
	}
};


struct tile {
   int x_offset = 0;
   int y_offset = 0;
   int tile_number = 0;
   const char* text = nullptr;

   ~tile();
   
};

struct display {
   char* description = nullptr;
   int tile_count = 0;
   tile* tiles = nullptr;
   bool extra_bit = false;
   int x = 0;
   int y = 0;
   
   ~display();
};

struct collection {
   const char* name = nullptr;
   bool extra_bit = false;
   unsigned char prop[4];
   
   ~collection();
};

struct map8x8 {
	char tile = 0;
	char prop = 0;
};

struct map16 {
	map8x8 top_left;
	map8x8 bottom_left;
	map8x8 top_right;
	map8x8 bottom_right;
};

struct status_pointers {        // the order of these actually matters
    pointer carriable;
    pointer kicked;
    pointer carried;
    pointer mouth;
    pointer goal;
};

// 00: type {0=tweak,1=custom,3=generator/shooter}
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
	int byte_count = 0;
	int extra_byte_count = 0;
	
	const char* directory = nullptr;
	const char* asm_file = nullptr;
	const char* cfg_file = nullptr;
	
	int map_block_count = 0;
	map16* map_data = nullptr;
	
   int display_count = 0;
   display* displays = nullptr;
   
   int collection_count = 0;
   collection* collections = nullptr;
	
   int sprite_type = 0; // 0 = Normal custom sprite, 1 = Extended custom sprite, 2 = Cluster custom sprite, 3 = Overworld custom sprite
	~sprite();
   void print(FILE* stream);
};

int get_pointer(unsigned char *data, int address, int size = 3, int bank = 0x00);

struct ROM {
	unsigned char *data;
	unsigned char *real_data;
	char *name;
	int size;
	int header_size;
	
	void open(const char *n);	
	void close();
	
	int pc_to_snes(int address);
	int snes_to_pc(int address);
	
	pointer pointer_snes(int address, int size = 3, int bank = 0x00);
	pointer pointer_pc(int address, int size = 3, int bank = 0x00);
};


simple_string get_line(const char* text, int offset);
void set_pointer(pointer* p, int address);
bool is_empty_table(sprite* spr, int size);
char* trim(char *text);

#endif