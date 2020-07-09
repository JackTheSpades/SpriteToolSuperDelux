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
		text[i-1] = 0;
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

void sprite::print(FILE* stream) {
   fprintf(stream, "Type:       %02X\n", table.type);
   fprintf(stream, "ActLike:    %02X\n", table.actlike);
   fprintf(stream, "Tweak:      %02X, %02X, %02X, %02X, %02X, %02X\n",
      table.tweak[0], table.tweak[1], table.tweak[2], 
      table.tweak[3], table.tweak[4], table.tweak[5]);
      
   //not needed for tweaks
   if(table.type) {
      fprintf(stream, "Extra:      %02X, %02X\n", table.extra[0], table.extra[1]);
      fprintf(stream, "ASM File:   %s\n", asm_file);
      fprintf(stream, "Byte Count: %d, %d\n", byte_count, extra_byte_count);
   }
   
   if(map_block_count) {
      fprintf(stream, "Map16:\n");
      unsigned char* mapdata = (unsigned char*)map_data;
      for(int i = 0; i < map_block_count * 8; i++){
         if((i % 8) == 0)
            fprintf(stream, "\t");
         fprintf(stream, "%02X, ", (int)mapdata[i]);
         if((i % 8) == 7)
            fprintf(stream, "\n");
      }
   }
   
   #define BOOL_STR(b) ((b) ? "true" : "false")
   
   if(display_count) {
      fprintf(stream, "Displays:\n");
      for(int i = 0; i < display_count; i++){
         display* d = displays + i;
         fprintf(stream, "\tX: %d, Y: %d, Extra-Bit: %s\n", d->x, d->y, BOOL_STR(d->extra_bit));
         fprintf(stream, "\tDescription: %s\n", d->description);
         for(int j = 0; j < d->tile_count; j++) {
            tile* t = d->tiles + j;
            if(t->text)
               fprintf(stream, "\t\t%d,%d,*%s*\n", t->x_offset, t->y_offset, t->text);
            else
               fprintf(stream, "\t\t%d,%d,%X\n", t->x_offset, t->y_offset, t->tile_number);
         }
      }
   }
   
   if(display_count) {
      fprintf(stream, "Collections:\n");
      for(int i = 0; i < collection_count; i++){
         collection* c = collections + i;
         fprintf(stream, "\tExtra-Bit: %s, Property Bytes: (%02X %02X %02X %02X) Name: %s\n", BOOL_STR(c->extra_bit),
            c->prop[0], c->prop[1], c->prop[2], c->prop[3],
            c->name);
      }
   }
   
   #undef BOOL_STR
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
