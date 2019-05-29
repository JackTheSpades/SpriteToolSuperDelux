#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <cctype>

#include "asar/asardll.h"
#include "cfg.h"
#include "json.h"
#include "structs.h"
#include "file_io.h"
#include "map16.h"

#define PATH_ROUTINES 0
#define PATH_SPRITES 1
#define PATH_GENERATORS 2
#define PATH_SHOOTERS 3
#define PATH_LIST 4
#define PATH_ASM 5

#define PATH_EXTENDED 6
#define PATH_CLUSTER 7
#define PATH_OVERWORLD 8

#define EXT_SSC 0
#define EXT_MWT 1
#define EXT_MW2 2
#define EXT_S16 3
// #define EXT_SSCOV 4
// #define EXT_S16OV 5

#define INIT_PTR 0x01817D   //snes address of default init pointers
#define MAIN_PTR 0x0185CC   //guess what?

#define TEMP_SPR_FILE "spr_temp.asm"
#define TEMP_SHARE_FILE "__shared.asm"
#define TEMP_CLEAN_FILE "__cleanup.asm"

#define SPRITE_COUNT 0x80      //count for other sprites like cluster, extended


//version 1.xx
const char VERSION = 0x19;
bool PER_LEVEL = false;
const char* const * PATHS = nullptr;

void double_click_exit()
{
   getc(stdin); //Pause before exit
}

template <typename ...A>
void debug_print(const char* msg, A... args) {
   #ifdef DEBUGMSG
      printf(msg, args...);
   #endif      
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

/**
   Applies an asar patch to the rom.
   @param patch_name    the path to the .asm patch   
   @param &rom          the rom struct the patch should be applied to
   @return              true if patched successfully.
*/
bool patch(const char* patch_name, ROM &rom) {
   
   
#if 0

   patchparams params;
   params.structsize = (int)sizeof(patchparams);
   
	params.patchloc = patch_name;
	params.romdata = (char *)rom.real_data;
	params.buflen = MAX_ROM_SIZE;
	params.romlen = &rom.size;
   
   params.numincludepaths = 0;
   params.memory_file_count = 0;
   params.warning_setting_count = 0;
   
   params.stddefinesfile = nullptr;
   params.stdincludesfile = nullptr;
   
   const char* defines = nullptr;
   
   int additional_define_count = 1;       //at least 1 for tool defines
   if(defines) {
      for(int i = 0; i < strlen(defines); t++)
         if(defines[i] == ';')
            additional_define_count++;
   }
      
   definedata additional_define* = new definedata[additional_define_count];   
   additional_define[0] = { "__TOOL", "\"PIXI\"" };
   
   const char* current_define = defines;
   for(int i = 1; i < additional_define_count; i++) {
            
      int split = strchr(current_define, '=');  // index of character where define name cuts of    
      char* name = new char[split + 1];         // also equals to the length + 1 because null terminator.
      strncpy(name, current_define, split);
      name[split] = 0;
      additional_define[i].name = name;
      current_define += (split + 1);            //set pointer to after '='
      
      split = strchr(current_define, ';');
      char* contents = new char[split + 1];
      strncpy(contents, current_define, split);
	  contents[split] = 0;
      additional_define[i].contents = contents;
      current_define += (split + 1);            //set pointer to after ';' (ready for next iteration)
   }
   
   params.additional_defines = additional_define;
   params.additional_define_count = additional_define;
   
   params.should_reset = true;


   for (int i = 0; i < additional_define_count; i++) {
	   debug_print("\t!%s = %s", additional_define[i].name, additional_define[i].content);
   }
   
   bool result = asar_patch_ex(&params);

   for (int i = 1; i < additional_define_count; i++) {
	   delete[] additional_define[i].name;
	   delete[] additional_define[i].content;
   }
   delete[] additional_define;



   if(!result) {
	   debug_print("Failure. Try fetch errors:\n");
	   int error_count;
	   const errordata *errors = asar_geterrors(&error_count);
	   printf("An error has been detected:\n");
	   for (int i = 0; i < error_count; i++)
		   printf("%s\n", errors[i].fullerrdata);
   }


   
#endif
   
   
   if(!asar_patch(patch_name, (char *)rom.real_data, MAX_ROM_SIZE, &rom.size)){
      debug_print("Failure. Try fetch errors:\n");
      int error_count;
      const errordata *errors = asar_geterrors(&error_count);
      printf("An error has been detected:\n");
      for(int i = 0; i < error_count; i++)
         printf("%s\n", errors[i].fullerrdata);
      exit(-1);
   }
   debug_print("Success in patching %s\n", patch_name);
   return true;
}
/**
   Applies an asar patch to the rom.
   @param dir           directory containing the patch (must include trailing /)
   @param patch_name    the filename of the .asm patch  
   @param &rom          the rom struct the patch should be applied to
   @return              true if patched successfully.
*/
bool patch(const char* dir, const char* patch_name, ROM &rom) {   
   char* path = new char[strlen(dir) + strlen(patch_name) + 1];
   path[0] = 0;
   strcat(path, dir);
   strcat(path, patch_name);
   bool ret = patch(path, rom);
   delete[] path;
   return ret;
}

/**
   Patches a sprite to the rom. Prerequires the existance of the files:
      {PATH_ASM_DIR}/sa1def.asm
      shared.asm (see create_shared_patch(const char*))
      {spr->directory}/_header.asm
      {spr->asm_file}
   It extracts the main [and init] pointers and applies them to the spr->table values.
   
   @param *spr          pointer to the sprite struct to be patched to the rom
   @param &rom          the rom struct the sprite should be patched to
   @param *output       optional output stream.
*/
void patch_sprite(sprite* spr, ROM &rom, FILE* output) {
         
   FILE* sprite_patch = open(TEMP_SPR_FILE,"w");
   
   fprintf(sprite_patch, "namespace nested on\n");
   fprintf(sprite_patch, "incsrc \"%ssa1def.asm\"\n", PATHS[PATH_ASM]);
   fprintf(sprite_patch, "incsrc \"%s\"\n", TEMP_SHARE_FILE);
   fprintf(sprite_patch, "SPRITE_ENTRY_%d:\n", spr->number);
   fprintf(sprite_patch, "incsrc \"%s_header.asm\"\n", spr->directory);
   fprintf(sprite_patch, "freecode cleaned\n");
   fprintf(sprite_patch, "\tincsrc \"%s\"", spr->asm_file);
   fprintf(sprite_patch, "\nnamespace nested off\n");
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
   
   if(spr->table.main.is_empty())
      error("Sprite %s needs to contain a MAIN print.", spr->asm_file);
   
   if(output) {
      fprintf(output,"\tINIT: $%06X\n\tMAIN: $%06X"
         "\n__________________________________\n",
         spr->table.init.addr(), spr->table.main.addr());
   }   
}

/**
   Patches a list of sprites to the rom. Prerequires the existance of the files:
      {PATH_ASM_DIR}/sa1def.asm
      shared.asm (see create_shared_patch(const char*))
      {spr->directory}/_header.asm
      {spr->asm_file}
   It extracts the main [and init] pointers and applies them to the spr->table values.
   Where spr is the iterator of the sprite array and the files need to exist for every item in the array
   
   Function prevents from two sprites with identical spr->asm_file to be patched twice. Instead the init
   and main pointers are copied over.
   
   @param *sprite_list  pointer to the sprite struct array to be patched to the rom
   @param size          size of the sprite struct array
   @param &rom          the rom struct the sprites should be patched to
   @param *output       optional output stream.
*/
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
   if(!strncmp((char*)rom.data + rom.snes_to_pc(0x02FFE2), "STSD", 4)){      //already installed load old tables

      FILE* clean_patch = open(TEMP_CLEAN_FILE, "w");
      
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
            for(int table_offset = 11; table_offset < 0x8000; table_offset += 0x10)   {
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
      for(int table_offset = 11; table_offset < limit; table_offset += 0x10)   {
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
         fprintf(clean_patch, "\n\n;Overworld:\n");
         int ow_table = rom.pointer_snes(0x04F677).addr();
         if(ow_table != 0x0CA2AB)   //check with default/uninserted address
            for(int i = 0; i < SPRITE_COUNT; i++) {
               pointer ow_pointer = rom.pointer_snes(ow_table + 3 * i);
               if(!ow_pointer.is_empty())
                  fprintf(clean_patch, "autoclean $%06X\n", ow_pointer.addr());
            }
      }
      
      //everything else is being cleaned by the main patch itself.
      fclose(clean_patch);
      patch(TEMP_CLEAN_FILE, rom);
      
   }else{ //check for old sprite_tool code. (this is annoying)
      
      //removes all STAR####MDK tags
      const char* mdk = "MDK";   //sprite tool added "MDK" after the rats tag to find it's insertions...
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
                  offset -= strlen(mdk) - 1;      //set pointer to start of mdk string
                  break;
               }
            }
                        
            if(offset >= 0x8000)
               break;      
            bank_offset = offset + strlen(mdk);
            if(strncmp((bank + offset - 8), "STAR", 4))   //check for "STAR"
               continue;
                        
            //delete the amount that the RATS tag is protecting
            int size = ((unsigned char)bank[offset-3] << 8)
               + (unsigned char)bank[offset-4] + 8;
            int inverted = ((unsigned char)bank[offset-1] << 8)
               + (unsigned char)bank[offset-2];
       
            if ((size - 8 + inverted) == 0x0FFFF)         // new tag
               size++;
               
            else if ((size - 8 + inverted) != 0x10000){   // (not old tag either =>) bad tag
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

void create_shared_patch(const char *routine_path) {
   FILE *shared_patch = open(TEMP_SHARE_FILE, "w");
   fprintf(shared_patch,    "macro include_once(target, base, offset)\n"
            "   if !<base> != 1\n"
            "      !<base> = 1\n"
            "      pushpc\n"
            "      if read3(<offset>+$03E05C) != $FFFFFF\n"
            "         <base> = read3(<offset>+$03E05C)\n"
            "      else\n"
            "         freecode cleaned\n"
            "            #<base>:\n"
            "            print \"    Routine: <base> inserted at $\",pc\n"
            "            namespace <base>\n"
            "            incsrc \"<target>\"\n"
            "               namespace off\n"
            "         ORG <offset>+$03E05C\n"
            "            dl <base>\n"            
            "      endif\n"
            "      pullpc\n"
            "   endif\n"
            "endmacro\n");
   
   //get the routines directory so that we can iterate over all the *.asm files in there
   DIR *routine_directory = opendir(routine_path);
   dirent *routine_file = nullptr;
   if(!routine_directory){
      fclose(shared_patch);
      error("Unable to open the routine directory \"%s\"\n", routine_path);
   }
   
   int routine_count = 0;
   while((routine_file = readdir(routine_directory)) != NULL){
      char *name = routine_file->d_name;
      //only include file if it has .asm extension and does not start with a period as filename
      if((!strcmp(".asm", name + strlen(name) - 4)) && (name[0] != '.')){
         if(routine_count > 100){
            fclose(shared_patch);
            closedir(routine_directory);
            error("More than 100 routines located.  Please remove some.\n", "");
         }
         name[strlen(name) - 4] = 0;
         fprintf(shared_patch,    "!%s = 0\n"
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
      if(list_data[i - 1] == '\r')   //adjust for windows line end.
         i++;
      line_number++;
      if(!current_line.length || !trim(current_line.data)[0])
         continue;
      
      //context switching (also goes back to beginning of loop)
      if(!strcmp(current_line.data, "SPRITE:"))
         SETTYPE(Sprite)
      if(!strcmp(current_line.data, "EXTENDED:"))
         SETTYPE(Extended)
      if(!strcmp(current_line.data, "CLUSTER:"))
         SETTYPE(Cluster)
      if(!strcmp(current_line.data, "OW:"))
         SETTYPE(Overworld)
                  
      //read sprite number
      if(!sscanf(current_line.data, "%x%n", &sprite_id, &bytes_read))
         ERROR("Error on line %d: Invalid line start.\n");
         
      //get sprite pointer
      sprite* spr = nullptr;      
      if(type == Sprite) {
         if(current_line.data[bytes_read] == ':')
            sscanf(current_line.data, "%x%*c%hx%n", &level, &sprite_id, &bytes_read);
         
         if(level != 0x200 && !PER_LEVEL)
            ERROR("Error on line %d: Trying to insert per level sprites without the -pl flag");

         spr = from_table<sprite>(sprite_list, level, sprite_id);
         //verify sprite pointer and determine cause if invalid
         if(!spr) {
            if(sprite_id >= 0x100)
            {
               ERROR("Error on line %d: Sprite number must be less than 0x100");
            }
            if(level == 0x200 && sprite_id >= 0xB0 && sprite_id < 0xC0)
            {
               ERROR("Error on line %d: Sprite B0-BF must be assigned a level. Eg. 105:B0");
            }
            if(level > 0x200) {
               ERROR("Error on line %d: Level must range from 000-1FF");
            }
            if(sprite_id < 0xB0 || sprite_id >= 0xC0)
            {
               ERROR("Error on line %d: Only sprite B0-BF must be assigned a level.");
            }
         }
      } else if (type == Overworld) {
         if(sprite_id >= SPRITE_COUNT || sprite_id == 0)
            ERROR("Error on line %d: Sprite number must be less than 0x80 and not be 0 for OW sprites.");
         sprite_id--;
         spr = sprite_list + sprite_id;
      } else {
         if(sprite_id >= SPRITE_COUNT)
            ERROR("Error on line %d: Sprite number must be less than 0x80");
         spr = sprite_list + sprite_id;
      }
               
      //check sprite pointer already in use.
      if(spr->line)
         ERROR("Error on line %d: Sprite number already used.");
      
      //initialize some.
      spr->line = line_number;
      spr->level = level;
      spr->number = sprite_id;
      
      //set the directory for the desired type
      if(type != Sprite)
         dir = paths[PATH_EXTENDED - 1 + type];
      else {
         if(sprite_id < 0xC0)
            dir = paths[PATH_SPRITES];
         else if(sprite_id < 0xD0)
            dir = paths[PATH_SHOOTERS];
         else
            dir = paths[PATH_GENERATORS];
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
      
      //set filename to either cfg/json or asm file, depending on type.
      
      // if(type == Overworld) {
         // spr->cfg_file = file_name;
         // if(!dot || (strcmp(dot, ".json")))
            // ERROR("Error on line %d: Not an json file.");
            // if(!read_json_file(spr, output))
               // ERROR("Error on line %d: Cannot parse JSON file.");
      // }
      if(type != Sprite) {      
         if(!dot || (strcmp(dot, ".asm") && strcmp(dot, ".PATH_ASM")))
            ERROR("Error on line %d: Not an asm file.");
         spr->asm_file = file_name;
      }
      else {
         spr->cfg_file = file_name;
         if(!dot) {
            ERROR("Error on line %d: No file extension.");
         } else if(!strcmp(dot, ".cfg") || !strcmp(dot, ".CFG")) {
            if(!read_cfg_file(spr, output))
               ERROR("Error on line %d: Cannot parse CFG file.");
         } else if(!strcmp(dot, ".json")) {
            if(!read_json_file(spr, output))
               ERROR("Error on line %d: Cannot parse JSON file.");
         } else
            ERROR("Error on line %d: Unknown filetype");
      }
      
      //
      if(output) {
         fprintf(output, "Read from line %d\n", spr->line);
         if(spr->level != 0x200)
            fprintf(output, "Number %02X for level %03X\n", spr->number, spr->level);
         else
            fprintf(output, "Number %02X\n", spr->number);
         spr->print(output);
         fprintf(output, "\n--------------------------------------\n");
      }

      //if sprite is tweak, set init and main pointer to contents of ROM pointer table.
      if(!spr->table.type) {
         set_pointer(&spr->table.init, (INIT_PTR + 2 * spr->number));
         set_pointer(&spr->table.main, (MAIN_PTR + 2 * spr->number));
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

FILE* open_subfile(ROM &rom, const char* ext, const char* mode) {
   char* name = new char[strlen(rom.name) - 4 + strlen(ext) + 1];
   strcpy(name, rom.name);
   char* dot = strrchr(name, '.');
   strcpy(dot + 1, ext);
   debug_print("\ttry opening %s mode %s\n", name, mode);
   FILE* r = open(name, mode);   
   delete[] name;
   return r;
}

void set_paths_relative_to(const char** path, const char* arg0) {
   
   if(*path == nullptr)
      return;
   
   int count = 0;
   char* pos = strrchr(arg0, '\\');
   if(pos == nullptr)
      pos = strrchr(arg0, '/');
   if(pos != nullptr)
      count = (pos - arg0) + 1;

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


int main(int argc, char* argv[]) {
               
   ROM rom;
   
   //individual lists containing the sprites for the specific sections
   sprite sprite_list[MAX_SPRITE_COUNT];   
   sprite cluster_list[SPRITE_COUNT];
   sprite extended_list[SPRITE_COUNT];
   sprite ow_list[SPRITE_COUNT];
   
   //the list containing the lists...
   sprite* sprites_list_list[4];   
   sprites_list_list[Sprite] = sprite_list;
   sprites_list_list[Extended] = extended_list;
   sprites_list_list[Cluster] = cluster_list;
   sprites_list_list[Overworld] = ow_list;
   
   FILE* output = nullptr;
   bool keep_temp = false;
   bool do_poison = false;
      
   //first is version 1.xx, others are preserved
   unsigned char versionflag[4] = { VERSION, 0x00, 0x00, 0x00 };
   
   const char* paths[9];
   paths[PATH_LIST] = "list.txt";
   paths[PATH_SPRITES] = "sprites/";
   paths[PATH_SHOOTERS] = "shooters/";
   paths[PATH_GENERATORS] = "generators/";
   paths[PATH_ROUTINES] = "routines/";
   paths[PATH_ASM] = "asm/";   
   paths[PATH_EXTENDED] = "extended/";
   paths[PATH_CLUSTER] = "cluster/";
   paths[PATH_OVERWORLD] = "overworld/";
   
   //list of strings containing the files to be used as base for <romname.xxx>
   //all nullptr by default
   const char* extensions[6] = {0};
   
   //map16 for sprite displays
   map16 map[MAP16_SIZE];
   // map16 map_ov[MAP16_SIZE];
   
   if(argc < 2){
      atexit(double_click_exit);
   }

   if(!asar_init()){
      error("Error: Asar library is missing or couldn't be initialized, please redownload the tool or add the dll.\n", "");
   }
   
   //------------------------------------------------------------------------------------------
   // handle arguments passed to tool
   //------------------------------------------------------------------------------------------
         
   for(int i = 1; i < argc; i++){
   
      #define SET_PATH(str, str2, index) else if((!strcmp(argv[i], str) || !strcmp(argv[i], str2)) && i < argc - 2) { paths[index] = argv[i+1]; i++; }
      #define SET_EXT(str, index) else if(!strcmp(argv[i], str) && i < argc - 2) { extensions[index] = argv[i+1]; i++; }
   
      if(!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help") ){
         printf("Version 1.%02d\n", VERSION);
         printf("Usage: pixi <options> <ROM>\nOptions are:\n");
         printf("-d  | --debug            Enable debug output\n");
         printf("-k  | --keep             Keep debug files\n");
         printf("-l  | --list <listpath>  Specify a custom list file (Default: %s)\n", paths[PATH_LIST]);
         printf("-pl | --per-level        Per level sprites - will insert perlevel sprite code\n");
         printf("-npl                     Default, no sprite per level, only for compatibility reasons\n");
         printf("-p  | --poison           Inserts the poison muchroom and adds it to the ssc/s16/mtw/mw2 files\n");
         printf("\n");
         
         printf("-a  | --asm <asm>               Specify a custom asm directory (Default %s)\n", paths[PATH_ASM]);
         printf("-sp | --sprites <sprites>       Specify a custom sprites directory (Default %s)\n", paths[PATH_SPRITES]);
         printf("-sh | --shooters <shooters>     Specify a custom shooters directory (Default %s)\n", paths[PATH_SHOOTERS]);
         printf("-g  | --generators <generators> Specify a custom generators directory (Default %s)\n", paths[PATH_GENERATORS]);
         printf("-e  | --extended <extended>     Specify a custom extended sprites directory (Default %s)\n", paths[PATH_EXTENDED]);
         printf("-c  | --clusters <cluster>      Specify a custom cluster sprites directory (Default %s)\n", paths[PATH_CLUSTER]);         
         printf("-ow | --overworld <overworld>   Specify a custom overworld sprites directory (Default %s)\n", paths[PATH_OVERWORLD]);
         printf("-r  | --routines <routines>     Specify a shared routine directory (Default %s)\n", paths[PATH_ROUTINES]);
         printf("\n");
         
         printf("-ssc <append ssc>     Specify ssc file to be copied into <romname>.ssc\n");
         printf("-mwt <append mwt>     Specify mwt file to be copied into <romname>.mwt\n");
         printf("-mw2 <append mw2>     Specify mw2 file to be copied into <romname>.mw2\n");
         printf("                        Note that the first and last byte will not be copied\n");
         printf("-s16 <base s16>       Specify s16 file to be used as a base for <romname>.s16\n");
         // printf("-sscov <base sscov>   Specify sscov file to be used as a base for <romname>.sscov\n");
         // printf("-s16ov <base s16ov>   Specify s16ov file to be used as a base for <romname>.s16ov\n");
         printf("     Do not use <romname>.xxx as an argument as the file will be overwriten!\n");
         
         exit(0);
      } else if(!strcmp(argv[i], "-d") || !strcmp(argv[i], "--debug")) {
         output = stdout;
      } else if(!strcmp(argv[i], "-k") || !strcmp(argv[i], "--keep")) {
         keep_temp = true;
      } else if(!strcmp(argv[i], "-p") || !strcmp(argv[i], "--poison")) {
         do_poison = true;
      } else if(!strcmp(argv[i], "-pl") || !strcmp(argv[i], "--per-level")) {
         PER_LEVEL = true;
      } else if(!strcmp(argv[i], "-npl")){
         PER_LEVEL = false;
      }
      
      SET_PATH("-r", "--routines", PATH_ROUTINES)
      SET_PATH("-a", "--asm", PATH_ASM)
      SET_PATH("-sp", "--sprites", PATH_SPRITES)
      SET_PATH("-sh", "--shooters", PATH_SHOOTERS)
      SET_PATH("-g", "--generators", PATH_GENERATORS)
      SET_PATH("-l", "--list", PATH_LIST)
      SET_PATH("-e", "--extended", PATH_EXTENDED)
      SET_PATH("-c", "--clusters", PATH_CLUSTER)
      
      SET_EXT("-ssc", EXT_SSC)
      SET_EXT("-mwt", EXT_MWT)
      SET_EXT("-mw2", EXT_MW2)
      SET_EXT("-s16", EXT_S16)
      // SET_EXT("-sscov", EXT_SSCOV)
      // SET_EXT("-s16ov", EXT_S16OV)
      else{
         if(i == argc-1){
            break;
         }
         error("ERROR: Invalid command line option \"%s\".\n", argv[i]);
      }
      
      #undef SET_PATH
      #undef SET_EXT
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
   
   //------------------------------------------------------------------------------------------
   // Check if a newer version has been used before.
   //------------------------------------------------------------------------------------------
   
   char version = *((char*)rom.data + rom.snes_to_pc(0x02FFE2 + 4));
   if(version > VERSION && version != 0xFF) {   
      printf("The ROM has been patched with a newer version of PIXI (1.%02d) already.\n", version);
      printf("This is version 1.%02d\n", VERSION);
      printf("Please get a newer version.");
      rom.close();
      asar_close();
      exit(-1);
   }
   
     
   //------------------------------------------------------------------------------------------
   // set path for directories relative to pixi or rom, not working dir.
   //------------------------------------------------------------------------------------------
   
   for(int i = 0; i < 9; i++) {
      if(i == PATH_LIST)
         set_paths_relative_to(paths + i, rom.name);  //list file is located relative to rom
      else
         set_paths_relative_to(paths + i, argv[0]);   //all sprite folders are relative to program
      debug_print("paths[%d] = %s\n", i, paths[i]);
   }
   PATHS = paths;
   
   //all of the Lunar Magic extension files used as basis for our own generated extension files
   //are also relative to the roms location... go figure.
   for(int i = 0; i < 6; i++) {
      set_paths_relative_to(extensions + i, rom.name);
      debug_print("extensions[%d] = %s\n", i, extensions[i]);
   }
   
   //------------------------------------------------------------------------------------------
   // regular stuff
   //------------------------------------------------------------------------------------------
   
   populate_sprite_list(paths, sprites_list_list, (char *)read_all(paths[PATH_LIST], true), output);
   
   //creates cleanup.asm file and patches it to the rom. Uses asar's autoclean function and readsome
   //the pointers to the previously inserted sprite files to do just that :D
   clean_hack(rom);
      
   create_shared_patch(paths[PATH_ROUTINES]);
   
   int size = PER_LEVEL ? MAX_SPRITE_COUNT : 0x100;
   patch_sprites(sprite_list, size, rom, output);
   patch_sprites(cluster_list, SPRITE_COUNT, rom, output);
   patch_sprites(extended_list, SPRITE_COUNT, rom, output);
   patch_sprites(ow_list, SPRITE_COUNT, rom, output);
   
   debug_print("Sprites successfully patched.\n");
   
   //------------------------------------------------------------------------------------------
   // create binary files
   //------------------------------------------------------------------------------------------   
   
   //sprites
   debug_print("Try create binary tables.\n");
   write_all(versionflag, paths[PATH_ASM], "_versionflag.bin", 4);
   if(PER_LEVEL) {
      write_long_table(sprite_list + 0x0000, paths[PATH_ASM], "_PerLevelT1.bin");
      write_long_table(sprite_list + 0x0800, paths[PATH_ASM], "_PerLevelT2.bin");
      write_long_table(sprite_list + 0x1000, paths[PATH_ASM], "_PerLevelT3.bin");
      write_long_table(sprite_list + 0x1800, paths[PATH_ASM], "_PerLevelT4.bin");
      write_long_table(sprite_list + 0x2000, paths[PATH_ASM], "_DefaultTables.bin", 0xF0);
   } else {
      write_long_table(sprite_list, paths[PATH_ASM], "_DefaultTables.bin", 0x100);
   }
      
   
   //bin file buffer (cluster/extended/overworld need 0x80*3)
   unsigned char file[0x80 * 3];
   
   //cluster
   for(int i = 0; i < SPRITE_COUNT; i++)
      memcpy(file + (i * 3), &cluster_list[i].table.main, 3);
   write_all(file, paths[PATH_ASM], "_ClusterPtr.bin", SPRITE_COUNT * 3);
   
   //extended
   for(int i = 0; i < SPRITE_COUNT; i++)
      memcpy(file + (i * 3), &extended_list[i].table.main, 3);
   write_all(file, paths[PATH_ASM], "_ExtendedPtr.bin", SPRITE_COUNT * 3);
      
   //overworld
   for(int i = 0; i < SPRITE_COUNT; i++)
      memcpy(file + (i * 3), &ow_list[i].table.main, 3);
   write_all(file, paths[PATH_ASM], "_OverworldMainPtr.bin", SPRITE_COUNT * 3);
   for(int i = 0; i < SPRITE_COUNT; i++)
      memcpy(file + (i * 3), &ow_list[i].table.init, 3);
   write_all(file, paths[PATH_ASM], "_OverworldInitPtr.bin", SPRITE_COUNT * 3);
      
   //more?
   debug_print("Binary tables created.\n");
      
   
   //------------------------------------------------------------------------------------------
   // create custom size table (extra property byte count)
   // and <romname>.xxx files.
   // (and any other stuff that can be done from looping over all 0x100 regular sprites
   //------------------------------------------------------------------------------------------   
      
   //extra byte size file
   //plus data for .ssc, .mwt, .mw2 files
   unsigned char extra_bytes[0x200];
   
   debug_print("Try create romname files.\n");
   FILE* s16 = open_subfile(rom, "s16", "wb");
   FILE* ssc = open_subfile(rom, "ssc", "w");
   FILE* mwt = open_subfile(rom, "mwt", "w");
   FILE* mw2 = open_subfile(rom, "mw2", "wb");
   // FILE* s16ov = open_subfile(rom, "s16ov", "wb");
   // FILE* sscov = open_subfile(rom, "sscov", "w");
   debug_print("Romname files opened.\n");
   
   fputc(0x00, mw2); //binary data starts with 0x00
      
   //copy data from existing files if specified!
   if(extensions[EXT_S16])
      read_map16(map, extensions[EXT_S16]);
   // if(extensions[EXT_S16OV])
      // read_map16(map_ov, extensions[EXT_S16OV]);
   if(extensions[EXT_SSC])
      copy_to(ssc, extensions[EXT_SSC], true);
   // if(extensions[EXT_SSCOV])
      // copy_to(sscov, extensions[EXT_SSCOV], true);
   if(extensions[EXT_MWT])
      copy_to(mwt, extensions[EXT_MWT], true);
   if(extensions[EXT_MW2])
      copy_to(mw2, extensions[EXT_MW2], false, 1, 1);
   
   
   
   //------------------------------------------------------------
   // handle Poison Mushroom
   //------------------------------------------------------------
   if(do_poison) {
      
      patch(PATHS[PATH_ASM], "Poison.asm", rom);
      int poison_print_count = 0;
      const char * const * poison_prints = asar_getprints(&poison_print_count);
      
      debug_print("Poison.asm prints:\n");
      for(int i = 0; i < poison_print_count; i++)
         debug_print("\t%s\n", poison_prints[i]);
      
      unsigned char poison_map16_data[8];
	  int poison_map16_tile = 0x400;

      if(poison_print_count > 0)
         fprintf(ssc, "%s\n", poison_prints[0]);
      if(poison_print_count > 2) {
         sscanf(poison_prints[2], "%hhx %hhx %hhx %hhx %hhx %hhx %hhx %hhx",
            &poison_map16_data[0], &poison_map16_data[1], &poison_map16_data[2], &poison_map16_data[3],
            &poison_map16_data[4], &poison_map16_data[5], &poison_map16_data[6], &poison_map16_data[7]);
            #pragma GCC diagnostic push
            #pragma GCC diagnostic ignored "-Wstrict-aliasing"
		 if (*(unsigned long*)poison_map16_data != 0xDEADBEEF) {
			 poison_map16_tile = find_free_map(map, 1);
			 memcpy(map + poison_map16_tile, poison_map16_data, 8);
			 fprintf(ssc, "%X\n", poison_map16_tile);
		 }
            #pragma GCC diagnostic pop
      }
	  if (poison_print_count > 1) {
		  fprintf(ssc, poison_prints[1], poison_map16_tile);
		  fprintf(ssc, "\n");
	  }
      if(poison_print_count > 3)
         fprintf(mwt, "%s\n", poison_prints[3]);
      if(poison_print_count > 4) {
         sscanf(poison_prints[4], "%hhx %hhx %hhx",
            &poison_map16_data[0], &poison_map16_data[1], &poison_map16_data[2]);   //repurpose map16 char array
         fwrite(poison_map16_data, 1, 3, mw2);
      }
   }   
   
   
   for(int i = 0; i < 0x100; i++) {
      sprite* spr = from_table<sprite>(sprite_list, 0x200, i);
      
      //sprite pointer being null indicates per-level sprite
      if(!spr) {
         extra_bytes[i] = 7;
         extra_bytes[i + 0x100] = 7;
      }
      else {
      
         //line number within the list file indicates we've got a filled out sprite
         if(spr->line) {
            extra_bytes[i] = 3 + spr->byte_count;
            extra_bytes[i + 0x100] = 3 + spr->extra_byte_count;
            
            //----- s16 / map16 -------------------------------------------------
            
            int map16_tile = find_free_map(map, spr->map_block_count);
            memcpy(map + map16_tile, spr->map_data, spr->map_block_count * sizeof(map16));
            
            //----- ssc / display -----------------------------------------------
            for(int j = 0; j < spr->display_count; j++) {
               display* d = spr->displays + j;
            
               //4 digit hex value. First is Y pos (0-F) then X (0-F) then custom/extra bit combination
               //here custom bit is always set (because why the fuck not?)
               int ref = d->y * 0x1000 +
                  d->x * 0x100 + 
                  0x20 +
                  (d->extra_bit ? 0x10 : 0);
               
               //if no description (or empty) just asm filename instead.
               if(d->description && strlen(d->description))
                  fprintf(ssc, "%02X %04X %s\n", i, ref, d->description);
               else
                  fprintf(ssc, "%02X %04X %s\n", i, ref, spr->asm_file);
                  
               //loop over tiles and append them into the output.
               fprintf(ssc, "%02X %04X", i, ref + 2);
               for(int k = 0; k < d->tile_count; k++) {
                  tile* t = d->tiles + k;
                  if(t->text) {
                     fprintf(ssc, " 0,0,*%s*", t->text);
                     break;
                  } else {
                     //tile numbers > 0x300 indicates it's a "custom" map16 tile, so we add the offset we got earlier
                     //+0x100 because in LM these start at 0x400.
                     int tile_num = t->tile_number;
                     if(tile_num >= 0x300)
                        tile_num += 0x100 + map16_tile;
                     //note we're using %d because x/y are signed integers here
                     fprintf(ssc, " %d,%d,%X", t->x_offset, t->y_offset, tile_num);
                  }
               }
               fprintf(ssc, "\n");
            }
            
            //----- mwt,mw2 / collection ------------------------------------------          
            for(int j = 0; j < spr->collection_count; j++) {
               collection* c = spr->collections + j;
               
               //mw2
               //build 3 byte level format
               char c1 = 0x79 + (c->extra_bit ? 0x04 : 0);
               fputc(c1, mw2); fputc(0x70, mw2); fputc(spr->number, mw2);               
               //add the extra property bytes
               int byte_count = (c->extra_bit ? spr->extra_byte_count : spr->byte_count);
               fwrite(c->prop, 1, byte_count, mw2);
               
               //mwt
               //first one prints sprite number as well, all others just their name.
               if(j == 0)
                  fprintf(mwt, "%02X\t%s\n", spr->number, c->name);
               else
                  fprintf(mwt, "\t%s\n", c->name);
            }
            
         //no line means unused sprite, so just set to default 3.
         } else  {
            extra_bytes[i] = 3;
            extra_bytes[i + 0x100] = 3;
         }
      }
   }
   fputc(0xFF, mw2); //binary data ends with 0xFF (see SMW level data format)
   
   
   //loop over OW sprites to fill out sscov and s16ov files.
   // for(int i = 0; i < SPRITE_COUNT; i++) {
      // sprite* spr = ow_list + i;
      
      // //----- s16ov / Overworld map16 -------------------------------------------------
      
      // int map16_tile = find_free_map(map_ov, spr->map_block_count);
      // memcpy(map_ov + map16_tile, spr->map_data, spr->map_block_count * sizeof(map16));
      
      // //----- sscov / Overworld display -----------------------------------------------
      // for(int j = 0; j < spr->display_count; j++) {
         // display* d = spr->displays + j;
      
         // //overworld doesn't support custom display based on x/y position.
         // if(d->y != 0 || d->x != 0)
            // continue;
      
         // //4 digit hex value. First is Y pos (0-F) then X (0-F) then custom/extra bit combination
         // //here custom bit is always set (because why the fuck not?)
         // int ref = 0x20 + (d->extra_bit ? 0x10 : 0);
         
         // //if no description (or empty) just asm filename instead.
         // if(d->description && strlen(d->description))
            // fprintf(sscov, "%02X %04X %s\n", i, ref, d->description);
         // else
            // fprintf(sscov, "%02X %04X %s\n", i, ref, spr->asm_file);
            
         // //loop over tiles and append them into the output.
         // fprintf(sscov, "%02X %04X", i, ref + 2);
         // for(int k = 0; k < d->tile_count; k++) {
            // tile* t = d->tiles + k;
            // if(t->text) {
               // fprintf(sscov, " 0,0,*%s*", t->text);
               // break;
            // } else {
               // //tile numbers > 0x300 indicates it's a "custom" map16 tile, so we add the offset we got earlier
               // //+0x100 because in LM these start at 0x400.
               // int tile_num = t->tile_number;
               // if(tile_num >= 0x300)
                  // tile_num += 0x100 + map16_tile;
               // //note we're using %d because x/y are signed integers here
               // fprintf(sscov, " %d,%d,%X", t->x_offset, t->y_offset, tile_num);
            // }
         // }
         // fprintf(sscov, "\n");
      // }
   // }   
   
   write_all(extra_bytes, paths[PATH_ASM], "_CustomSize.bin", 0x200);
   fwrite(map, sizeof(map16), MAP16_SIZE, s16);
   // fwrite(map_ov, sizeof(map16), MAP16_SIZE, s16ov);
   
   //close all the files.
   fclose(s16); fclose(ssc); fclose(mwt); fclose(mw2);
   // fclose(s16ov); fclose(sscov);
   
   //apply the actual patches
   if(PER_LEVEL)
      patch(paths[PATH_ASM], "main.asm" , rom);
   else
      patch(paths[PATH_ASM], "main_npl.asm" , rom);
   patch(paths[PATH_ASM], "cluster.asm", rom);
   patch(paths[PATH_ASM], "extended.asm", rom);
   patch(paths[PATH_ASM], "overworld.asm", rom);
   
   //------------------------------------------------------------------------------------------
   // clean up (if necessary)
   //------------------------------------------------------------------------------------------      
   
   if(!keep_temp){   
      remove(paths[PATH_ASM], "_versionflag.bin");
      
      remove(paths[PATH_ASM], "_DefaultTables.bin");
      if(PER_LEVEL) {
         remove(paths[PATH_ASM], "_PerLevelT1.bin");
         remove(paths[PATH_ASM], "_PerLevelT2.bin");
         remove(paths[PATH_ASM], "_PerLevelT3.bin");
         remove(paths[PATH_ASM], "_PerLevelT4.bin");
      }
      
      remove(paths[PATH_ASM], "_ClusterPtr.bin");
      remove(paths[PATH_ASM], "_ExtendedPtr.bin");      
      // remove(paths[PATH_ASM], "_OverworldMainPtr.bin");
      // remove(paths[PATH_ASM], "_OverworldInitPtr.bin");
      
      remove(paths[PATH_ASM], "_CustomSize.bin");
      remove("shared.asm");
      remove(TEMP_SPR_FILE);
	  remove(TEMP_CLEAN_FILE);
   }
   
   rom.close();
   asar_close();
   printf("\nAll sprites applied successfully!\n");
   
   for(int i = 0; i < 9; i++) {
      delete[] paths[i];
   }
   
   return 0;
}
