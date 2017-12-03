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

#define EXTENDED 6
#define CLUSTER 7
#define OVERWORLD 8


#define TEMP_SPR_FILE "spr_temp.asm"
#define SPRITE_COUNT 0x80	//count for other sprites like cluster, ow, extended


//version 1.xx
const char VERSION = 0x02;
bool PER_LEVEL = true;
const char* ASM_DIR = nullptr;


void double_click_exit()
{
	getc(stdin); //Pause before exit
}



template <typename T>
T* from_table(T* table, int level, int number) {

   if(!PER_LEVEL)
      return table + number;

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

bool patch(const char* patch_name, ROM &rom) {
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
bool patch(const char* dir, const char* patch_name, ROM &rom) {   
   char* path = new char[strlen(dir) + strlen(patch_name) + 1];
   path[0] = 0;
   strcat(path, dir);
   strcat(path, patch_name);
   bool ret = patch(path, rom);
   delete[] path;
   return ret;
}

void patch_sprite(sprite* spr, ROM &rom, FILE* output) {
			
	FILE* sprite_patch = open(TEMP_SPR_FILE,"w");
	fprintf(sprite_patch, "incsrc \"%ssa1def.asm\"\n", ASM_DIR);
	fprintf(sprite_patch, "incsrc \"shared.asm\"\n");
	fprintf(sprite_patch, "incsrc \"%s_header.asm\"\n", spr->directory);
	fprintf(sprite_patch, "freecode cleaned\n");
	fprintf(sprite_patch, "\tincsrc \"%s\"", spr->asm_file);
	fclose(sprite_patch);
				
	patch(TEMP_SPR_FILE, rom);
		
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
			set_pointer(&spr->table.init, addr);
		else if(!strcmp(buf,"MAIN"))
			set_pointer(&spr->table.main, addr);
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
			spr->table.init.addr(), spr->table.main.addr());
	}	
}




void patch_sprites(sprite* sprite_list, int size, ROM &rom, FILE* output) {

	for(int i = 0; i < size; i++) {					
		sprite* spr = sprite_list + i;
		if(!spr->asm_file)
			continue;
			
		bool duplicate = false;
		for(int j = i - 1; j >= 0; j--) {
			if(sprite_list[j].asm_file) {
				if(!strcmp(spr->asm_file, sprite_list[j].asm_file)) {
					spr->table.init = sprite_list[j].table.init;
					spr->table.main = sprite_list[j].table.main;
					duplicate = true;
					break;
				}			
			}
		}
		
		if(duplicate)
			continue;
			
		patch_sprite(spr, rom, output);
	}
}


void clean_hack(ROM &rom){
	if(!strncmp((char*)rom.data + rom.snes_to_pc(0x02FFE2), "STSD", 4)){		//already installed load old tables

      char* path = new char[strlen(ASM_DIR) + strlen("_cleanup.asm") + 1];
      path[0] = 0;
      strcat(path, ASM_DIR);
      strcat(path, "_cleanup.asm");	
		FILE* clean_patch = open(path, "w");
		
		int version = rom.data[rom.snes_to_pc(0x02FFE6)];
      int flags = rom.data[rom.snes_to_pc(0x02FFE7)];
      
      bool per_level_sprites_inserted = ((flags & 0x01) == 1) || (version < 2);
      
      // bit 0 = per level sprites inserted
      if(per_level_sprites_inserted) {      
         //remove per level sprites
         for(int bank = 0; bank < 4; bank++) {
            int level_table_address = (rom.data[rom.snes_to_pc(0x02FFEA + bank)] << 16) + 0x8000;
            if(level_table_address == 0xFF8000)
               continue;
            fprintf(clean_patch, ";Per Level sprites for levels %03X - %03X\n", (bank * 0x80), ((bank+1)*0x80)-1);
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
      }
      
      //if per level sprites are inserted, we only have 0xF00 bytes of normal sprites
      //due to 10 bytes per sprite and B0-BF not being in the table.
      const int limit = per_level_sprites_inserted ? 0xF00 : 0x1000;
		
		//remove global sprites
		fprintf(clean_patch, ";Global sprites: \n");
		int global_table_address = rom.pointer_snes(0x02FFEE).addr();
		for(int table_offset = 11; table_offset < limit; table_offset += 0x10)	{
			pointer main_pointer = rom.pointer_snes(global_table_address + table_offset);
			if(!main_pointer.is_empty()) {
				fprintf(clean_patch, "autoclean $%06X\n", main_pointer.addr());
			}				
		}
								
		//shared routines
		fprintf(clean_patch, "\n\n;Routines:\n");
		for(int i = 0; i < 100; i++){
			int routine_pointer = rom.pointer_snes(0x03E05C + i * 3).addr();
			if(routine_pointer != 0xFFFFFF){
				fprintf(clean_patch, "autoclean $%06X\n", routine_pointer);
				fprintf(clean_patch, "\torg $%06X\n", 0x03E05C + i * 3);
				fprintf(clean_patch, "\tdl $FFFFFF\n");
			}
		}
		
		
		//Version 1.01 stuff:		
		if(version >= 1) {		
		
			//remove cluster sprites
			fprintf(clean_patch, "\n\n;Cluster:\n");
			int cluster_table = rom.pointer_snes(0x00A68A).addr();
         if(cluster_table != 0x9C1498)   //check with default/uninserted address
            for(int i = 0; i < SPRITE_COUNT; i++) {
               pointer cluster_pointer = rom.pointer_snes(cluster_table + 3 * i);
               if(!cluster_pointer.is_empty())
                  fprintf(clean_patch, "autoclean $%06X\n", cluster_pointer.addr());
            }
			
			//remove extended sprites
			fprintf(clean_patch, "\n\n;Extended:\n");
			int extended_table = rom.pointer_snes(0x029B1F).addr();         
         if(extended_table != 0x176FBC)   //check with default/uninserted address
            for(int i = 0; i < SPRITE_COUNT; i++) {
               pointer extended_pointer = rom.pointer_snes(extended_table + 3 * i);
               if(!extended_pointer.is_empty())
                  fprintf(clean_patch, "autoclean $%06X\n", extended_pointer.addr());
            }
			
			//remove overworld sprites
			// fprintf(clean_patch, "\n\n;Overworld:\n");
			// int ow_table = rom.pointer_snes(0x048633).addr();
			// for(int i = 0; i < SPRITE_COUNT; i++) {
				// pointer ow_pointer = rom.pointer_snes(ow_table + 3 * i);
				// if(!ow_pointer.is_empty())
					// fprintf(clean_patch, "autoclean $%06X\n", ow_pointer.addr());
			// }
		}
		
		//everything else is being cleaned by the main patch itself.
		fclose(clean_patch);
		patch(path, rom);
      delete[] path;
		
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
				"				incsrc \"<target>\"\n"
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
		if((!strcmp(".asm", name + strlen(name) - 4)) && (name[0] != '.')){
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

//needs same order as defines at the top...
enum ListType { Sprite = 0, Extended = 1, Cluster = 2, Overworld = 3 };

bool populate_sprite_list(const char** paths, sprite** sprite_lists, const char *list_data, FILE* output) {
	int line_number = 0, i = 0, bytes_read, sprite_id, level;
	simple_string current_line;
	
	ListType type = Sprite;
	const char* dir = nullptr;
	sprite* sprite_list = nullptr;
	
	#define ERROR(S) { delete []list_data; error(S, line_number); }
	#define SETTYPE(T) { type = (T); continue; }
	
	do{
		level = 0x200;
		sprite_list = sprite_lists[type];
		
		//read line from list_data
		current_line = static_cast<simple_string &&>(get_line(list_data, i));
		i += current_line.length;
		if(list_data[i - 1] == '\r')	//adjust for windows line end.
			i++;
		line_number++;
		if(!current_line.length || !trim(current_line.data)[0])
			continue;
		
		//context switching
		if(!strcmp(current_line.data, "SPRITE:"))
			SETTYPE(Sprite)
		if(!strcmp(current_line.data, "EXTENDED:"))
			SETTYPE(Extended)
		if(!strcmp(current_line.data, "CLUSTER:"))
			SETTYPE(Cluster)
		//if(!strcmp(current_line.data, "OW:"))
		//	SETTYPE(Overworld)
						
		//read sprite number
		if(!sscanf(current_line.data, "%x%n", &sprite_id, &bytes_read))
			ERROR("Error on line %d: Invalid line start.\n");
			
		//get sprite pointer
		sprite* spr = nullptr;		
		if(type == Sprite) {
			if(current_line.data[bytes_read] == ':')
				sscanf(current_line.data, "%x%*c%hx%n", &level, &sprite_id, &bytes_read);
			
         if(level != 0x200 && !PER_LEVEL)
            ERROR("Error on line %d: Trying to insert per level sprites with per level mode disabled (-npl)");
         
			spr = from_table<sprite>(sprite_list, level, sprite_id);
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
      } else {
			if(sprite_id > SPRITE_COUNT)
				ERROR("Error on line %d: Sprite number must be less than 0x80");
			spr = sprite_list + sprite_id;
		}
					
		
		if(spr->line)
			ERROR("Error on line %d: Sprite number already used.");
		
		
		spr->line = line_number;
		spr->level = level;
		spr->number = sprite_id;
		
		//set the directory for the desired type
		if(type != Sprite)
			dir = paths[EXTENDED - 1 + type];
		else {
			if(sprite_id < 0xC0)
				dir = paths[SPRITES];
			else if(sprite_id < 0xD0)
				dir = paths[SHOOTERS];
			else
				dir = paths[GENERATORS];
		}		
		spr->directory = dir;
		
		//get the filename from the list file
		char* file_name = nullptr;
		if(isspace(current_line.data[bytes_read])){
			char *trimmed = trim(current_line.data + bytes_read);
			file_name = new char[strlen(dir) + strlen(trimmed) + 1];
			strcpy(file_name, dir);
			strcat(file_name, trimmed);
			if(!file_name[0]) {
				delete[] file_name;
				ERROR("Error on line %d: Missing filename.\n");
			}
		} else
			ERROR("Error on line %d: Missing space or level seperator.\n");
		
		char* dot = strrchr(file_name, '.');
		
		//set filename to either cfg or asm file, depending on type.
		if(type != Sprite) {		
		   if(!dot || (strcmp(dot, ".asm") && strcmp(dot, ".ASM")))
			   ERROR("Error on line %d: Not an asm file.");
			
			spr->asm_file = file_name;
			if(output)
				fprintf(output, "%s\n\n--------------------------------------\n", file_name);
		}
		else {
		   if(!dot || (strcmp(dot, ".cfg") && strcmp(dot, ".CFG")))
			   ERROR("Error on line %d: Not a cfg file.");
			spr->cfg_file = file_name;
			if(!read_cfg_file(spr, (char *)read_all(spr->cfg_file, true), output))
            ERROR("Error on line %d: Cannot parse CFG file.");
		}		
	}while(current_line.length);
	
	#undef ERROR
	#undef SETTYPE

	delete[] list_data;
	return true;
}


// spr      = sprite array
// filename = duh
// size     = number of sprites to loop over
void write_long_table(sprite* spr, const char* dir, const char* filename, int size = 0x800) {
	unsigned char dummy[0x10] = 
		{ 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF };
	unsigned char file[size * 0x10];
		
	if(is_empty_table(spr, size))
		write_all(dummy, dir, filename, 0x10);
	else {
		
		for(int i = 0; i < size; i++)
			memcpy(file + (i * 0x10), &spr[i].table, 0x10);	
		write_all(file, dir, filename, size * 0x10);
	}
}


void set_paths_relative_to(const char** path, const char* arg0) {
   
   int count = 0;
   char* pos = strrchr(arg0, '\\');
   if(pos == nullptr)
      pos = strrchr(arg0, '/');
   if(pos != nullptr)
      count = (pos - arg0) + 1;
      
   //printf("count = %d\n", count);
            
   int len = count + strlen(*path) + 1;
   if(count == 0) //if there is no path in arg0, we add "./"
      len += 2;
   
   char* str = new char[len];
   memset(str, 0, len);
   
   if(count != 0)
      strncat(str, arg0, count);
   else
      strcat(str, "./");
   strcat(str, *path);
   
   //win path seperator replace.
   //not really a problem iirc but keeps things uniform.
   for(int j = 0; j < count; j++)
      if(str[j] == '\\')
         str[j] = '/';
   
   *path = str;
}

void remove(const char* dir, const char* file) {
   char* path = new char[strlen(dir) + strlen(file) + 1];
   path[0] = 0;
   strcat(path, dir);
   strcat(path, file);
   remove(path);
   delete[] path;
}


int main(int argc, char* argv[]) {
					
	ROM rom;
	
	sprite sprite_list[MAX_SPRITE_COUNT];	
	sprite cluster_list[SPRITE_COUNT];
	sprite extended_list[SPRITE_COUNT];
	sprite ow_list[SPRITE_COUNT];
	
	sprite* sprites_list_list[4];	
	sprites_list_list[Sprite] = sprite_list;
	sprites_list_list[Extended] = extended_list;
	sprites_list_list[Cluster] = cluster_list;
	sprites_list_list[Overworld] = ow_list;
	
	FILE* output = nullptr;
	bool keep_temp = false;
		
	//first is version 1.xx, others are preserved
	unsigned char versionflag[4] = { VERSION, 0x00, 0x00, 0x00 };
	
	const char* paths[9];
	paths[LIST] = "list.txt";
	paths[SPRITES] = "sprites/";
	paths[SHOOTERS] = "shooters/";
	paths[GENERATORS] = "generators/";
	paths[ROUTINES] = "routines/";
   paths[ASM] = "asm/";   
	paths[EXTENDED] = "extended/";
	paths[CLUSTER] = "cluster/";
	paths[OVERWORLD] = "overworld/";
	
	if(argc < 2){
        atexit(double_click_exit);
   }

	if(!asar_init()){
		error("Error: Asar library is missing, please redownload the tool or add the dll.\n", "");
	}
	
	//------------------------------------------------------------------------------------------
	// handle arguments passed to tool
	//------------------------------------------------------------------------------------------
   
   printf("%s\n", argv[0]);
		
	for(int i = 1; i < argc; i++){
		if(!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help") ){
			printf("Version 1.%02d\n", VERSION);
			printf("Usage: pixi <options> <ROM>\nOptions are:\n");
			printf("-d\t\tEnable debug output\n");
			printf("-k\t\tKeep debug files\n");
			printf("-l  <listpath>\tSpecify a custom list file (Default: %s)\n", paths[LIST]);
         printf("-npl\t\tNo per level sprites. Run like normal sprite_tool\n");
			printf("\n");
			
         printf("-a  <asm>\tSpecify a custom asm directory (Default %s)\n", paths[ASM]);
			printf("-sp <sprites>\tSpecify a custom sprites directory (Default %s)\n", paths[SPRITES]);
			printf("-sh <shooters>\tSpecify a custom shooters directory (Default %s)\n", paths[SHOOTERS]);
			printf("-g  <generators>\tSpecify a custom generators directory (Default %s)\n", paths[GENERATORS]);
			printf("-e  <extended>\tSpecify a custom extended sprites directory (Default %s)\n", paths[EXTENDED]);
			printf("-c  <cluster>\tSpecify a custom cluster sprites directory (Default %s)\n", paths[CLUSTER]);			
			//printf("-ow <cluster>\tSpecify a custom overworld sprites directory (Default %s)\n", paths[OVERWORLD]);
			printf("\n");
			
			printf("-r  <sharedpath>\tSpecify a shared routine directory (Default %s)\n", paths[ROUTINES]);
			exit(0);
		}else if(!strcmp(argv[i], "-d") || !strcmp(argv[i], "--debug")){
			output = stdout;
		}else if(!strcmp(argv[i], "-k")){
			keep_temp = true;
		}else if(!strcmp(argv[i], "-npl")){
			PER_LEVEL = false;
		}else if(!strcmp(argv[i], "-r") && i < argc - 2){
			paths[ROUTINES] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-a") && i < argc - 2){
			paths[ASM] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-sp") && i < argc - 2){
			paths[SPRITES] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-sh") && i < argc - 2){
			paths[SHOOTERS] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-g") && i < argc - 2){
			paths[GENERATORS] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-l") && i < argc - 2){
			paths[LIST] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-e") && i < argc - 2){
			paths[EXTENDED] = argv[i+1];
			i++;
		}else if(!strcmp(argv[i], "-c") && i < argc - 2){
			paths[CLUSTER] = argv[i+1];
			i++;
		}else{
			if(i == argc-1){
				break;
			}
			error("ERROR: Invalid command line option \"%s\".\n", argv[i]);
		}
	}
      
   versionflag[1] = (PER_LEVEL ? 1 : 0);
   
	//------------------------------------------------------------------------------------------
	// Get ROM name if none has been passed yet.
	//------------------------------------------------------------------------------------------

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
		printf("The ROM has been patched with a newer version of PIXI (1.%02d) already.\n", version);
		printf("This is version 1.%02d\n", VERSION);
		printf("Please get a newer version.");
      rom.close();
      asar_close();
		exit(-1);
	}
   
     
   //set path for directories relative to pixi, not working dir.
   for(int i = 0; i < 9; i++) {
      if(i == LIST)
         set_paths_relative_to(paths + i, rom.name);
      else
         set_paths_relative_to(paths + i, argv[0]);
      printf("paths[%d] = %s\n", i, paths[i]);
   }
   ASM_DIR = paths[ASM];
	
	//------------------------------------------------------------------------------------------
	// regular stuff
	//------------------------------------------------------------------------------------------
	
	populate_sprite_list(paths, sprites_list_list, (char *)read_all(paths[LIST], true), output);
	
	clean_hack(rom);
		
	create_shared_patch(paths[ROUTINES], rom);
	
   int size = PER_LEVEL ? MAX_SPRITE_COUNT : 0x100;
	patch_sprites(sprite_list, size, rom, output);
	patch_sprites(cluster_list, SPRITE_COUNT, rom, output);
	patch_sprites(extended_list, SPRITE_COUNT, rom, output);
	//patch_sprites(ow_list, SPRITE_COUNT, rom, output);
	
	//------------------------------------------------------------------------------------------
	// create binary files
	//------------------------------------------------------------------------------------------	
	
	//sprites
	write_all(versionflag, paths[ASM], "_versionflag.bin", 4);
   if(PER_LEVEL) {
      write_long_table(sprite_list + 0x0000, paths[ASM], "_PerLevelT1.bin");
      write_long_table(sprite_list + 0x0800, paths[ASM], "_PerLevelT2.bin");
      write_long_table(sprite_list + 0x1000, paths[ASM], "_PerLevelT3.bin");
      write_long_table(sprite_list + 0x1800, paths[ASM], "_PerLevelT4.bin");
      write_long_table(sprite_list + 0x2000, paths[ASM], "_DefaultTables.bin", 0xF0);
   } else {
      write_long_table(sprite_list, paths[ASM], "_DefaultTables.bin", 0x100);
   }
      
	
	//cluster
	unsigned char file[SPRITE_COUNT * 3];	
	for(int i = 0; i < SPRITE_COUNT; i++)
		memcpy(file + (i * 3), &cluster_list[i].table.main, 3);
	write_all(file, paths[ASM], "_ClusterPtr.bin", SPRITE_COUNT * 3);
	
	//extended
	for(int i = 0; i < SPRITE_COUNT; i++)
		memcpy(file + (i * 3), &extended_list[i].table.main, 3);
	write_all(file, paths[ASM], "_ExtendedPtr.bin", SPRITE_COUNT * 3);
		
	//overworld
	// for(int i = 0; i < SPRITE_COUNT; i++)
		// memcpy(file + (i * 3), &ow_list[i].table.main, 3);
	// write_all(file, paths[ASM], "_OverworldMainPtr.bin", SPRITE_COUNT * 3);
	// for(int i = 0; i < SPRITE_COUNT; i++)
		// memcpy(file + (i * 3), &ow_list[i].table.init, 3);
	// write_all(file, paths[ASM], "_OverworldInitPtr.bin", SPRITE_COUNT * 3);
		
	//more?
		
	
		
	//extra byte size file
	unsigned char extra_bytes[0x200];
	for(int i = 0; i < 0x100; i++) {
	
		sprite* spr = from_table<sprite>(sprite_list, 0x200, i);	
		
		if(!spr) {
			extra_bytes[i] = 7;
			extra_bytes[i + 0x100] = 7;
		}
		else {
			if(spr->asm_file) {
				extra_bytes[i] = 3 + spr->byte_count;
				extra_bytes[i + 0x100] = 3 + spr->extra_byte_count;
			} else  {
				extra_bytes[i] = 3;
				extra_bytes[i + 0x100] = 3;
			}
		}
	}
	write_all(extra_bytes, paths[ASM], "_CustomSize.bin", 0x200);
	
	//apply the actual patches
	patch(paths[ASM], "main.asm" , rom);
	patch(paths[ASM], "cluster.asm", rom);
	patch(paths[ASM], "extended.asm", rom);
	//patch(paths[ASM], "asm/overworld.asm", rom);
	
	
	
	if(!keep_temp){	
		remove(paths[ASM], "_versionflag.bin");
		
		remove(paths[ASM], "_DefaultTables.bin");
      if(PER_LEVEL) {
         remove(paths[ASM], "_PerLevelT1.bin");
         remove(paths[ASM], "_PerLevelT2.bin");
         remove(paths[ASM], "_PerLevelT3.bin");
         remove(paths[ASM], "_PerLevelT4.bin");
      }
		
		remove(paths[ASM], "_ClusterPtr.bin");
		remove(paths[ASM], "_ExtendedPtr.bin");		
		//remove("asm/_OverworldMainPtr.bin");	
		//remove("asm/_OverworldInitPtr.bin");	
		
		remove(paths[ASM], "_CustomSize.bin");
		remove("shared.asm");
		remove(TEMP_SPR_FILE);
		
		remove(paths[ASM], "_cleanup.asm");
	}
	
	rom.close();
	asar_close();
	printf("\nAll sprites applied successfully!\n");
   
   for(int i = 0; i < 9; i++) {
      delete[] paths[i];
   }
   
	return 0;
}
