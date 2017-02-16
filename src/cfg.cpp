#include <stdio.h>
#include "cfg.h"
#include "structs.h"

void cfg_type(const char* line, sprite* spr, const void*);
void cfg_actlike(const char* line, sprite* spr, const void*);
void cfg_tweak(const char* line, sprite* spr, const void*);
void cfg_prop(const char* line, sprite* spr, const void*);
void cfg_asm(const char* line, sprite* spr, const void*);
void cfg_assmbl(const char* line, sprite* spr, const void*);

void read_cfg_file(sprite* spr, const char* cfg, FILE* output) {

	const int linelimit = 6;
	linehandler handlers[linelimit];

	//functions that parse lines
	handlers[0] = &cfg_type;		//parse line 1 of cfg file
	handlers[1] = &cfg_actlike;	//parse line 2 etc...
	handlers[2] = &cfg_tweak;
	handlers[3] = &cfg_prop;
	handlers[4] = &cfg_asm;
	handlers[5] = &cfg_assmbl;
	
	int bytes_read = 0;
	simple_string current_line;
	int line = 0;
				
	do{
		current_line = static_cast<simple_string &&>(get_line(cfg, bytes_read));
		bytes_read += current_line.length;
		if(!current_line.length || !trim(current_line.data)[0]){
			continue;
		}

		handlers[line](current_line.data, spr, nullptr);
		line++;
		
	}while(current_line.length && line < linelimit);
		
	
	if(output != nullptr){	
		fprintf(output, "\n%s:, %d lines parsed:\n",spr->cfg_file,line-1);
		if(spr->level < 0x200)
			fprintf(output, "Sprite: %02X, Level: %03X\n", spr->number, spr->level);
		else
			fprintf(output, "Sprite: %02X\n", spr->number);
		fprintf(output, "Type: %02X, ActLike: %02X\nTweaker: ",spr->table->type, spr->table->actlike);
		for(int i = 0; i < 6; i++)
			fprintf(output, "%02X, ",spr->table->tweak[i]);
		fprintf(output, "\n");

		//if sprite isn't a tweak, print extra prop and asm file too:
		if(spr->table->type) {
			fprintf(output, "Extra: ");
			for(int i = 0; i < 2; i++)
				fprintf(output, "%02X, ",spr->table->extra[i]);
			fprintf(output, "\nASM File: %s\n", spr->asm_file);			
		}
		fprintf(output,"\n--------------------------------------\n");
	}

	if(!spr->table->type) {
		set_pointer(&spr->table->init, (INIT_PTR + 2 * spr->number));
		set_pointer(&spr->table->main, (MAIN_PTR + 2 * spr->number));
	}
}

void cfg_type(const char* line, sprite* spr, const void*) { sscanf(line, "%x", &spr->table->type); }
void cfg_actlike(const char* line, sprite* spr, const void*) { sscanf(line, "%x", &spr->table->actlike); }
void cfg_tweak(const char* line, sprite* spr, const void*) {
	sscanf(line, "%x %x %x %x %x %x",	
		&spr->table->tweak[0], &spr->table->tweak[1], &spr->table->tweak[2],
		&spr->table->tweak[3], &spr->table->tweak[4], &spr->table->tweak[5]);
}
void cfg_prop(const char* line, sprite* spr, const void*) {
	sscanf(line, "%x %x",	
		&spr->table->extra[0], &spr->table->extra[1]);
}
void cfg_asm(const char* line, sprite* spr, const void* arg) {	

	char* dic_end = strrchr(spr->cfg_file,'/');	//last '/' in string
	size_t len = 0;
	if(dic_end) len = dic_end - spr->cfg_file + 1;
		
	spr->asm_file = new char[len + strlen(line) + 1];     
	strncpy(spr->asm_file, spr->cfg_file, len);
	spr->asm_file[len] = 0;
	strcat(spr->asm_file, line); 
}
void cfg_assmbl(const char* line, sprite* spr, const void*){
	
}



