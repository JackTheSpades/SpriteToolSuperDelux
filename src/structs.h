#ifndef STRUCTS_H
#define STRUCTS_H

#include <string.h>
#include "file_io.h"


//use 16MB ROM size to avoid asar malloc/memcpy on 8MB of data per block. 
#define MAX_ROM_SIZE 16*1024*1024

#define RTL_BANK 0x01
#define RTL_HIGH 0x80
#define RTL_LOW 0x21

//10 per leve, 200 level + F0 global
#define MAX_SPRITE_COUNT 0x20F0

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
	unsigned char lowbyte = RTL_LOW;		//point to RTL
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
	
	int byte_count = 0;
	int extra_byte_count = 0;
	
	char* asm_file = nullptr;
	char* cfg_file = nullptr;
	
	// int map_data_size = 0;
	// map16* map_data = nullptr;
	
	// int name_size = 0;
	// unsigned char* name[2];
	
	// int ssc_size = 0;
	// unsigned char** ssc;
	
		
	~sprite() {
		if(asm_file)
			delete[] asm_file;
		if(cfg_file)
			delete[] cfg_file;
		// if(map_data)
			// delete[] map_data;
			
		// if(name[0])
			// delete[] name[0];
		// if(name[1])
			// delete[] name[1];
	}
};

int get_pointer(unsigned char *data, int address, int size = 3, int bank = 0x00);

struct ROM {
	unsigned char *data;
	unsigned char *real_data;
	char *name;
	int size;
	int header_size;
	
	void open(const char *n)
	{
		name = new char[strlen(n)+1]();
		strcpy(name, n);
		FILE *file = ::open(name, "r+b");	//call global open
		size = file_size(file);
		header_size = size & 0x7FFF;
		size -= header_size;
		data = read_all(name, false, MAX_ROM_SIZE + header_size);
		fclose(file);
		real_data = data + header_size;
	}
	
	void close()
	{
		write_all(data, name, size + header_size);
		delete []data;
		delete []name;
	}
	
	int pc_to_snes(int address)
	{
		address -= header_size;
		return ((((address << 1) & 0x7F0000) | (address&0x7FFF)) | 0x8000);
	}

	int snes_to_pc(int address)
	{
		return ((address & 0x7F0000) >> 1 | (address & 0x7FFF)) + header_size;
	}
	
	pointer pointer_snes(int address, int size = 3, int bank = 0x00)
	{
		return pointer(::get_pointer(data, snes_to_pc(address), size, bank));
	}
	pointer pointer_pc(int address, int size = 3, int bank = 0x00)
	{
		return pointer(::get_pointer(data, address, size, bank));
	}
};


simple_string get_line(const char* text, int offset);
void set_pointer(pointer* p, int address);
bool is_empty_table(sprite* spr, int size);
char* trim(char *text);

#endif