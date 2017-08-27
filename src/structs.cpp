#include <string.h>
#include <cctype>
#include "structs.h"

void ROM::open(const char *n)
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

void ROM::close()
{
	write_all(data, name, size + header_size);
	delete []data;
	delete []name;
}

int ROM::pc_to_snes(int address)
{
	address -= header_size;
	return ((((address << 1) & 0x7F0000) | (address&0x7FFF)) | 0x8000);
}

int ROM::snes_to_pc(int address)
{
	return ((address & 0x7F0000) >> 1 | (address & 0x7FFF)) + header_size;
}

pointer ROM::pointer_snes(int address, int size, int bank)
{
	return pointer(::get_pointer(data, snes_to_pc(address), size, bank));
}
pointer ROM::pointer_pc(int address, int size, int bank)
{
	return pointer(::get_pointer(data, address, size, bank));
}



void set_pointer(pointer* p, int address) {
	p->lowbyte = (char)(address & 0xFF);
	p->highbyte = (char)((address >> 8) & 0xFF);
	p->bankbyte = (char)((address >> 16) & 0xFF);
}

simple_string get_line(const char *text, int offset){
	simple_string string;
	if(!text[offset]){
		return string;
	}
	string.length = strcspn(text+offset, "\r\n")+1;	
	string.data = new char[string.length]();
	strncpy(string.data, text+offset, string.length-1);
	return string;
}

bool is_empty_table(sprite* spr, int size) {
	for(int i = 0; i < size; i++) {
		if(!spr[i].table.init.is_empty() || !spr[i].table.main.is_empty())
			return false;
	}
	return true;
}

int get_pointer(unsigned char *data, int address, int size, int bank) {
	address = (data[address])
		| (data[address + 1] << 8)
		| ((data[address + 2] << 16) * (size-2));
	return address | (bank << 16);
}

char* trim(char *text) {
	while(isspace(*text)){		//trim front
		text++;
	}
	for(int i = strlen(text); isspace(text[i-1]); i--){	//trim back
		text[i] = 0;
	}
	return text; 
}

sprite::~sprite() {
   if(asm_file)
      delete[] asm_file;
   if(cfg_file)
      delete[] cfg_file;
   if(map_data)
      delete[] map_data;
   if(displays)
      delete[] displays;
   if(collections)
      delete[] collections;
}

tile::~tile() {
   if(text)
      delete[] text;
}

display::~display() {
   if(description)
      delete[] description;
   if(tiles)
      delete[] tiles;
}

collection::~collection() {
   if(name)
      delete[] name;
}
