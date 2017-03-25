#include <stdio.h>
#include "cfg.h"
#include "structs.h"


typedef void (*linehandler)(const char*, sprite*, int&);


void cfg_type(const char* line, sprite* spr, int& handle);
void cfg_actlike(const char* line, sprite* spr, int& handle);
void cfg_tweak(const char* line, sprite* spr, int& handle);
void cfg_prop(const char* line, sprite* spr, int& handle);
void cfg_asm(const char* line, sprite* spr, int& handle);
void cfg_extra(const char* line, sprite* spr, int& handle);

// void cfg_name(const char* line, sprite* spr, int& handle);
// void cfg_map16(const char* line, sprite* spr, int& handle);
// void cfg_ssc(const char* line, sprite* spr, int& handle);

void read_cfg_file(sprite* spr, const char* cfg, FILE* output) {

	const int handlelimit = 6;
	linehandler handlers[handlelimit];

	//functions that parse lines
	handlers[0] = &cfg_type;		//parse line 1 of cfg file
	handlers[1] = &cfg_actlike;	//parse line 2 etc...
	handlers[2] = &cfg_tweak;
	handlers[3] = &cfg_prop;
	handlers[4] = &cfg_asm;
	handlers[5] = &cfg_extra;
	
	// handlers[6] = nullptr;
	// handlers[7] = &cfg_name;
	// handlers[8] = &cfg_map16;
	// handlers[9] = &cfg_ssc;
	
	
	
	int bytes_read = 0;
	simple_string current_line;
	int line = 0;
				
	//int nummap16 = 0, numname = 0, numssc = 0;
				
	do{
		current_line = static_cast<simple_string &&>(get_line(cfg, bytes_read));
		bytes_read += current_line.length;
		if(!current_line.length || !trim(current_line.data)[0])
			continue;

		handlers[line](current_line.data, spr, line);
		
		if(line < 0)
			return;
		
	}while(current_line.length && line < handlelimit);
		
	
	if(output != nullptr){	
		fprintf(output, "\n%s:, %d lines parsed:\n",spr->cfg_file,line-1);
		if(spr->level < 0x200)
			fprintf(output, "Sprite: %02X, Level: %03X\n", spr->number, spr->level);
		else
			fprintf(output, "Sprite: %02X\n", spr->number);
		fprintf(output, "Type: %02X, ActLike: %02X\nTweaker: ",spr->table.type, spr->table.actlike);
		for(int i = 0; i < 6; i++)
			fprintf(output, "%02X, ",spr->table.tweak[i]);
		fprintf(output, "\n");

		//if sprite isn't a tweak, print extra prop and asm file too:
		if(spr->table.type) {
			fprintf(output, "Extra: ");
			for(int i = 0; i < 2; i++)
				fprintf(output, "%02X, ",spr->table.extra[i]);
			fprintf(output, "\nASM File: %s\n", spr->asm_file);			
		}
		fprintf(output,"\n--------------------------------------\n");
	}

	if(!spr->table.type) {
		set_pointer(&spr->table.init, (INIT_PTR + 2 * spr->number));
		set_pointer(&spr->table.main, (MAIN_PTR + 2 * spr->number));
	}
}

void cfg_type(const char* line, sprite* spr, int& handle) { sscanf(line, "%x", &spr->table.type); handle++; }
void cfg_actlike(const char* line, sprite* spr, int& handle) { sscanf(line, "%x", &spr->table.actlike); handle++; }
void cfg_tweak(const char* line, sprite* spr, int& handle) {
	sscanf(line, "%x %x %x %x %x %x",	
		&spr->table.tweak[0], &spr->table.tweak[1], &spr->table.tweak[2],
		&spr->table.tweak[3], &spr->table.tweak[4], &spr->table.tweak[5]);
	handle++; 
}
void cfg_prop(const char* line, sprite* spr, int& handle) {
	sscanf(line, "%x %x",	
		&spr->table.extra[0], &spr->table.extra[1]);
	handle++; 
}
void cfg_asm(const char* line, sprite* spr, int& handle) {	

	//fetches path of cfg file and appand it before asm path.	
	char* dic_end = strrchr(spr->cfg_file,'/');	//last '/' in string
	size_t len = 0;
	if(dic_end) len = dic_end - spr->cfg_file + 1;
		
	spr->asm_file = new char[len + strlen(line) + 1];     
	strncpy(spr->asm_file, spr->cfg_file, len);
	spr->asm_file[len] = 0;
	strcat(spr->asm_file, line); 
	
	handle++; 
}


void cfg_extra(const char* line, sprite* spr, int& handle){
	int num = 0;
	int num_ex = 0;
	char c = 'F';
	
	handle++;
	
	sscanf(line, "%d%c%d", &num, &c, &num_ex);
	if(c != ':');
		return;
	
	if(num > 4 || num_ex > 4) {
		handle = -1;
		return;
	}
	
	spr->byte_count = num;
	spr->extra_byte_count = num_ex;
}


// void cfg_assmbl(const char* line, sprite* spr, int& handle){
	// int numname = 0;
	// int nummap16 = 0xFF;
	// int numssc = 0xFF;
	
	// sscanf(line, "%d %d %d",
		// &numname,
		// &nummap16,
		// &numssc);
	
	// if(numname > 2)
		// return;			//somehow pass an error?
	
	// //return if not enough arguments => old cfg file.
	// if(nummap16 == 0xFF)
		// return;
	
	// spr->name_size = numname;
	
	// spr->map_data_size = nummap16;
	// spr->map_data = new map16[nummap16];
	
	// spr->ssc_size = numssc;
	// spr->ssc = new (unsigned char*)[numssc];
	
	// handle++;
// }

// void cfg_extra(const char* line, sprite* spr, int& handle) {
	// sscanf(line, "%d", spr->extra_byte);
	// handle++;
// }

// void cfg_name(const char* line, sprite* spr, int& handle) {
	// //if no more sprite names to read, continue with next handler and return
	// if(!spr->name_size) {
		// handle++;
		// return;
	// }
	
	// spr->name_size--;
	// char* name = new char[strlen(line) + 1];
	// memcpy(name, line, strlen(line) + 1);
	// spr->name[spr->name_size] = name;
// }

// void cfg_map16(const char* line, sprite* spr, int& handle) {
	// //if no more map16 to read, continue with next handler and return
	// if(!spr->map_data_size) {
		// handle++;
		// return;
	// }
	
	// spr->map_data_size--;	
	
	// unsigned char* data = (unsigned char*)(spr->map_data + spr->name_size);
	// sscanf(line, "%x %x %x %x %x %x %x %x",
		// &data[0], &data[1],
		// &data[2], &data[3],
		// &data[4], &data[5],
		// &data[6], &data[7]);		
// }

// void cfg_ssc(const char* line, sprite* spr, int& handle) {
	// //if no more map16 to read, continue with next handler and return
	// if(!spr->ssc_size) {
		// handle++;
		// return;
	// }
	// spr->ssc_size--;
	
	// char* ssc = new char[strlen(line) + 1];
	// memcpy(ssc, line, strlen(line) + 1);
	// spr->ssc[spr->ssc_size] = ssc;
// }


