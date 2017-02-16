#include <string.h>
#include <cctype>
#include "structs.h"

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

bool is_empty_table(sprite_table* ptr, int size) {
	for(int i = 0; i < size; i++)
		if(!ptr[i].init.is_empty() || !ptr[i].init.is_empty())
			return false;
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
