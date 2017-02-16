#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <cctype>

#include "asar/asardll.h"
#include "cfg.h"
#include "structs.h"
#include "file_io.h"

#define ROUTINES 0
#define SPRITES 1
#define GENERATORS 2
#define SHOOTERS 3
#define LIST 4
#define ASM 5

#define TEMP_SPR_FILE "spr_temp.asm"

//version 1.xx
const char VERSION = 0x00;

void double_click_exit()
{
	getc(stdin); //Pause before exit
}



template <typename T>
T* from_table(T* table, int level, int number) {
	if(level > 0x200 || number > 0xFF)
		return nullptr;
	if(level == 0x200) {
		if(number < 0xB0)
			return table + (0x2000 + number);
		else if(number >= 0xB0 && number < 0xC0)
			return nullptr;
		else
			return table + (0x2000 + number - 0x10);
	}
	else if(number >= 0xB0 && number < 0xC0){
		return table + ((level * 0x10) + (number - 0xB0));
	}
	return nullptr;
}

bool patch(const char *patch_name, ROM &rom, const char *debug_name) {
	if(!asar_patch(patch_name, (char *)rom.real_data, MAX_ROM_SIZE, &rom.size)){
		int error_count;
		const errordata *errors = asar_geterrors(&error_count);
		printf("An error has been detected:\n");
		for(int i = 0; i < error_count; i++)
			printf("%s\n", errors[i].fullerrdata);
			exit(-1);
	}
	return true;
}


void patch_sprites(sprite* sprite_list, ROM &rom, FILE* output) {
		
	for(int i = 0; i < MAX_SPRITE_COUNT; i++) {
					
		sprite* spr = sprite_list + i;
		if(!spr->asm_file)
			continue;
			
		bool duplicate = false;
		for(int j = i - 1; j >= 0; j--) {
			if(sprite_list[j].asm_file) {
				if(!strcmp(spr->asm_file, sprite_list[j].asm_file)) {
					spr->table->init = sprite_list[j].table->init;
					spr->table->main = sprite_list[j].table->main;
					duplicate = true;
					break;
				}			
			}
		}
		
		if(duplicate)
			continue;
			
		FILE* sprite_patch = open(TEMP_SPR_FILE,"w");
		fprintf(sprite_patch, "incsrc \"asm/sa1def.asm\"\n");
		fprintf(sprite_patch, "incsrc \"shared.asm\"\n");
		fprintf(sprite_patch, "freecode cleaned\n");
		fprintf(sprite_patch, "\tincsrc \"%s\"", spr->asm_file);
		fclose(sprite_patch);
					
		patch(TEMP_SPR_FILE, rom, TEMP_SPR_FILE);
			
		int print_count = 0;
		const char * const * prints = asar_getprints(&print_count);
		int addr = 0xFFFFFF;
		char buf[5];
		
		if(output)
			fprintf(output, "%s\n", spr->asm_file);
		if(print_count > 2 && output)
			fprintf(output, "Prints:\n");
		
		for(int i = 0; i < print_count; i++) {
			sscanf(prints[i], "%4s%x", buf, &addr);			
			if(!strcmp(buf,"INIT"))
				set_pointer(&spr->table->init, addr);
			else if(!strcmp(buf,"MAIN"))
				set_pointer(&spr->table->main, addr);
			else if(!strcmp(buf,"VERG")) {
				if(VERSION < addr) {
					printf("Version Guard failed on %s.\n", spr->asm_file);
					exit(-1);
				}
			}
			else if(output)
				fprintf(output, "\t%s\n", prints[i]);
		}
		
		if(output) {
			fprintf(output,"\tINIT: $%06X\n\tMAIN: $%06X"
				"\n__________________________________\n",
				spr->table->init.addr(), spr->table->main.addr());
		}
	}
}

void clean_hack(ROM &rom){
	if(!strncmp((char*)rom.data + rom.snes_to_pc(0x02FFE2), "STSD", 4)){		//already installed load old tables				
		FILE* clean_patch = open("asm/cleanup.asm", "w");
		
		//remove per level sprites
		for(int bank = 0; bank < 4; bank++) {
			fprintf(clean_patch, ";Per Level sprites for levels %03X - %03X\n", (bank * 0x80), ((bank+1)*0x80)-1);
			int level_table_address = (rom.data[rom.snes_to_pc(0x02FFEA + bank)] << 16) + 0x8000;
			for(int table_offset = 11; table_offset < 0x8000; table_offset += 0x10)	{
				pointer main_pointer = rom.pointer_snes(level_table_address + table_offset);
				if(main_pointer.addr() == 0xFFFFFF) {
					fprintf(clean_patch, ";Encountered pointer to 0xFFFFFF, assuming there to be no sprites to clean!\n");
					break;
				}
				if(!main_pointer.is_empty()) {
					fprintf(clean_patch, "autoclean $%06X\n", main_pointer.addr());
				}				
			}
			fprintf(clean_patch, "\n");
		}
		
		//remove global sprites
		fprintf(clean_patch, ";Global sprites: \n");
		int global_table_address = rom.pointer_snes(0x02FFEE).addr();
		for(int table_offset = 11; table_offset < 0xF00; table_offset += 0x10)	{
			pointer main_pointer = rom.pointer_snes(global_table_address + table_offset);
			if(!main_pointer.is_empty()) {
				fprintf(clean_patch, "autoclean $%06X\n", main_pointer.addr());
			}				
		}
		
		fprintf(clean_patch, "\n\n;Routines:\n");
						
		//shared routines
		for(int i = 0; i < 100; i++){
			int routine_pointer = rom.pointer_snes(0x03E05C + i * 3).addr();
			if(routine_pointer != 0xFFFFFF){
				fprintf(clean_patch, "autoclean $%06X\n", routine_pointer);
				fprintf(clean_patch, "org $%06X\n", 0x03E05C + i * 3);
				fprintf(clean_patch, "dl $FFFFFF\n\n");
			}
		}
		
		//everything else is being cleaned by the main patch itself.
		fclose(clean_patch);
		patch("asm/cleanup.asm", rom, "asm/cleanup.asm");
		
	}else{ //check for old sprite_tool code. (this is annoying)
		
		//removes all STAR####MDK tags
		const char* mdk = "MDK";	//sprite tool added "MDK" after the rats tag to find it's insertions...
		int number_of_banks = rom.size / 0x8000;
		for (int i = 0x10; i < number_of_banks; ++i){ 
			char* bank = (char*)(rom.real_data + i * 0x8000);

			int bank_offset = 8;
			while(1){
				//look for data inserted on previous uses
				
				int offset = bank_offset;
				unsigned int j = 0;
				for(; offset < 0x8000; offset++) {
					if(bank[offset] != mdk[j++])
						j = 0;
					if(j == strlen(mdk)) {
						offset -= strlen(mdk) - 1;		//set pointer to start of mdk string
						break;
					}
				}
								
				if(offset >= 0x8000)
					break;		
				bank_offset = offset + strlen(mdk);
				if(strncmp((bank + offset - 8), "STAR", 4))	//check for "STAR"
					continue;
								
				//delete the amount that the RATS tag is protecting
				int size = ((unsigned char)bank[offset-3] << 8)
					+ (unsigned char)bank[offset-4] + 8;
				int inverted = ((unsigned char)bank[offset-1] << 8)
					+ (unsigned char)bank[offset-2];
		 
				if ((size - 8 + inverted) == 0x0FFFF)			// new tag
					size++;
					
				else if ((size - 8 + inverted) != 0x10000){	// (not old tag either =>) bad tag
					char answer;
					int pc = i * 0x8000 + offset - 8 + rom.header_size;
					printf("size: %04X, inverted: %04X\n", size - 8, inverted);
					printf("Bad sprite_tool RATS tag detected at $%06X / 0x%05X. Remove anyway (y/n) ",
						rom.pc_to_snes(pc), pc);
					scanf("%c",&answer);
					if(answer != 'Y' && answer != 'y')
						continue;
				}
				
				//printf("Clear %04X bytes from $%06X / 0x%05X.\n", size, rom.pc_to_snes(pc), pc);
				memset(bank + offset - 8, 0, size);
				bank_offset = offset - 8 + size;
			}
		}		
	}
}

void create_shared_patch(const char *routine_path, ROM &rom) {
	FILE *shared_patch = open("shared.asm", "w");
	fprintf(shared_patch, 	"macro include_once(target, base, offset)\n"
				"	if !<base> != 1\n"
				"		!<base> = 1\n"
				"		pushpc\n"
				"		if read3(<offset>+$03E05C) != $FFFFFF\n"
				"			<base> = read3(<offset>+$03E05C)\n"
				"		else\n"
				"			freecode cleaned\n"
				"				<base>:\n"
				"				print \"    Routine: <base> inserted at $\",pc\n"
				"				incsrc <target>\n"
				"			ORG <offset>+$03E05C\n"
				"				dl <base>\n"				
				"		endif\n"
				"		pullpc\n"
				"	endif\n"
				"endmacro\n");
	DIR *routine_directory = opendir(routine_path);
	dirent *routine_file = nullptr;
	if(!routine_directory){
		error("Unable to open the routine directory \"%s\"\n", routine_path);
	}
	int routine_count = 0;
	while((routine_file = readdir(routine_directory)) != NULL){
		char *name = routine_file->d_name;
		if(!strcmp(".asm", name + strlen(name) - 4)){
			if(routine_count > 100){
				closedir(routine_directory);
				error("More than 100 routines located.  Please remove some.\n", "");
			}
			name[strlen(name) - 4] = 0;
			fprintf(shared_patch, 	"!%s = 0\n"
						"macro %s()\n"
						"\t%%include_once(\"%s%s.asm\", %s, $%.2X)\n"
						"\tJSL %s\n"
						"endmacro\n", 
						name, name, routine_path, 
						name, name, routine_count*3, name);
			routine_count++;
		}
	}
	closedir(routine_directory);
	printf("%d Shared routines registered in \"%s\"\n", routine_count, routine_path);
	fclose(shared_patch);
}

bool populate_sprite_list(const char** paths, sprite* sprite_list, sprite_table* sprite_tables, const char *list_data, FILE* output) {
	int line_number = 0, i = 0, bytes_read, sprite_id, level;
	const char* dir = nullptr;
	simple_string current_line;
	#define ERROR(S) { delete []list_data; error(S, line_number); }
	do{
		level = 0x200;
		current_line = static_cast<simple_string &&>(get_line(list_data, i));
		i += current_line.length;
		if(list_data[i - 1] == '\r')
			i++;
		line_number++;
		if(!current_line.length || !trim(current_line.data)[0]){
			continue;
		}
		else if(!sscanf(current_line.data, "%x%n", &sprite_id, &bytes_read)){
			ERROR("Error on line %d: Invalid line start.\n");
		}
		if(current_line.data[bytes_read] == ':'){
			sscanf(current_line.data, "%x%*c%hx%n", &level, &sprite_id, &bytes_read);
		}
		
		sprite* spr = from_table<sprite>(sprite_list, level, sprite_id);
		if(!spr) {
			if(sprite_id >= 0x100)
				ERROR("Error on line %d: Sprite number must be less than 0x100");
			if(level == 0x200 && sprite_id >= 0xB0 && sprite_id < 0xC0)
				ERROR("Error on line %d: Sprite B0-BF must be assigned a level. Eg. 105:B0");
			if(level > 0x200)
				ERROR("Error on line %d: Level must range from 000-1FF");
			if(sprite_id >= 0xB0 && sprite_id < 0xC0)
				ERROR("Error on line %d: Only sprite B0-BF must be assigned a level.");
		}
					
		if(spr->line)
				ERROR("Error on line %d: Sprite number already used.");
				
		spr->line = line_number;
		spr->level = level;
		spr->number = sprite_id;
		spr->table = from_table<sprite_table>(sprite_tables, level, sprite_id);
		
		if(sprite_id < 0xC0)
			dir = paths[SPRITES];
		else if(sprite_id < 0xD0)
			dir = paths[SHOOTERS];
		else
			dir = paths[GENERATORS];
		
		if(isspace(current_line.data[bytes_read])){
			char *file_name = trim(current_line.data + bytes_read);
			spr->cfg_file = new char[strlen(dir) + strlen(file_name) + 1];
			strcpy(spr->cfg_file, dir);
			strcat(spr->cfg_file, file_name);
			if(!spr->cfg_file[0]){
				ERROR("Error on line %d: Missing filename.\n");
			}
		}else{
			ERROR("Error on line %d: Missing space or level seperator.\n");
		}
		
		read_cfg_file(spr, (char *)read_all(spr->cfg_file, true), output);
		
		
		
		// printf("Read Sprite on line %d:\n"
			// "\tNumber: %02X, Level: %02X\n"
			// "\tCFG File: %s\n",
			// spr->line, spr->number, spr->level, spr->cfg_file);
		
	}while(current_line.length);
	#undef ERROR

	delete []list_data;
	return true;
}


void write_long_table(sprite_table* ptr, const char* filename) {
	unsigned char dummy[0x10] = 
		{ 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF };
		
	if(is_empty_table(ptr, 0x800))
		write_all(dummy, filename, 0x10);
	else
		write_all((unsigned char*)ptr, filename, 0x8000);
}


int main(int argc, char* argv[]) {
					
	ROM rom;
	sprite_data data;
	sprite sprite_list[MAX_SPRITE_COUNT];
	FILE* output = nullptr;
	bool keep_temp = false;
		
	//first is version 1.xx, others are preserved
	unsigned char versionflag[4] = { VERSION, 0x00, 0x00, 0x00 };
	
	const char* paths[6];
	paths[ROUTINES] = "routines/";
	paths[SPRITES] = "sprites/";
	paths[SHOOTERS] = "shooters/";
	paths[GENERATORS] = "generators/";
	paths[LIST] = "list.txt";
	paths[ASM] = "asm/";
	
	if(argc < 2){
        atexit(double_click_exit);
    }

	if(!asar_init()){
		error("Error: Asar library is missing, please redownload the tool or add the dll.\n", "");
	}
		
	for(int i = 1; i < argc; i++){
		if(!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help") ){
			printf("Version 1.%02d\n", VERSION);
			printf("Usage: pixi <options> <ROM>\nOptions are:\n");
			printf("-d\t\tEnable debug output\n");
			printf("-k\t\tKeep debug files\n");
			printf("-l <listpath>\tSpecify a custom list file (Default: list.txt)\n");
			
			printf("-p <sprites>\tSpecify a custom generators directory (Default sprites/)\n");
			printf("-o <shooters>\tSpecify a custom generators directory (Default shooters/)\n");
			printf("-g <generators>\tSpecify a custom generators directory (Default generators/)\n");
			
			printf("-s <sharedpath>\tSpecify a shared routine directory (Default routines/)\n");
			exit(0);
		}else if(!strcmp(argv[i], "-d") || !strcmp(argv[i], "--debug")){
			output = stdout;
		}else if(!strcmp(argv[i], "-k")){
			keep_temp = true;
		}else if(!strcmp(argv[i], "-s") && i < argc - 2){
			paths[ROUTINES] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-p") && i < argc - 2){
			paths[SPRITES] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-o") && i < argc - 2){
			paths[SHOOTERS] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-g") && i < argc - 2){
			paths[GENERATORS] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-l") && i < argc - 2){
			paths[LIST] = argv[i+1];
			i++;
		}else{
			if(i == argc-1){
				break;
			}
			error("ERROR: Invalid command line option \"%s\".\n", argv[i]);
		}
	}

	if(argc < 2){
		printf("Enter a ROM file name, or drag and drop the ROM here: ");
		char ROM_name[FILENAME_MAX];
		if(fgets(ROM_name, FILENAME_MAX, stdin)){
			int length = strlen(ROM_name)-1;
			ROM_name[length] = 0;
			if((ROM_name[0] == '"' && ROM_name[length - 1] == '"') ||
			   (ROM_name[0] == '\'' && ROM_name[length - 1] == '\'')){
				ROM_name[length -1] = 0;
				for(int i = 0; ROM_name[i]; i++){
					ROM_name[i] = ROM_name[i+1]; //no buffer overflow there are two null chars.
				}
			}
		}
		rom.open(ROM_name);
	}else{
		rom.open(argv[argc-1]);
	}
	
	char version = *((char*)rom.data + rom.snes_to_pc(0x02FFE2 + 4));
	if(version > VERSION && version != 0xFF) {	
		printf("The ROM has been patched with a newer version of STSD (1.%02d) already.\n", version);
		printf("This is version 1.%02d\n", VERSION);
		printf("Please get a newer version.");
		exit(-1);
	}
	
	
	
	populate_sprite_list(paths, sprite_list, data.full_table, (char *)read_all(paths[LIST], true), output);
		
	clean_hack(rom);
		
	create_shared_patch(paths[ROUTINES], rom);
	
	patch_sprites(sprite_list, rom, output);
		
	write_all(versionflag, "asm/_versionflag.bin", 4);	
	write_all((unsigned char*)data.default_table, "asm/_DefaultTables.bin", 0xF00);
	write_long_table(data.level_table_t1, "asm/_PerLevelT1.bin");
	write_long_table(data.level_table_t2, "asm/_PerLevelT2.bin");
	write_long_table(data.level_table_t3, "asm/_PerLevelT3.bin");
	write_long_table(data.level_table_t4, "asm/_PerLevelT4.bin");
		
	patch("asm/main.asm", rom, "asm/main.asm");	
	
	if(!keep_temp){	
		remove("asm/_versionflag.bin");
		remove("asm/_DefaultTables.bin");
		remove("asm/_PerLevelT1.bin");
		remove("asm/_PerLevelT2.bin");
		remove("asm/_PerLevelT3.bin");
		remove("asm/_PerLevelT4.bin");
		remove("shared.asm");
	}
	
	rom.close();
	asar_close();
	printf("\nAll sprites applied successfully!\n");
	return 0;
}