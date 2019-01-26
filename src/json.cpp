#include "json.h"
#include "json/json.hpp"
#include "json/base64.h"
#include "json_const.h"
#include "structs.h"
#include "file_io.h"

#include <string.h>
#include <fstream>

using json = nlohmann::json;

//string clone.
//takes a c-string and returns a point to a new one. Needs to be deleted manually.
char* strcln(const char* str) {
   char* ret = new char[strlen(str) + 1];
   strcpy(ret, str);
   return ret;
}
char* strcln(std::string const& str) {
   return strcln(str.c_str());
}

bool read_json_file(sprite* spr, FILE* output) {

   json j;
   try {
	   std::ifstream instr(spr->cfg_file);
	   instr >> j;
   }
   catch (const std::exception &e) {
	   if (output)
		   fprintf(output, "Error, cannot open JSON file %s\n", spr->cfg_file);
	   return false;
   }

   #define CAP(x,y) x = (x < (y) ? x : (y))
   
   try {
      
      spr->table.actlike = j.at("ActLike");
      spr->table.type = j.at("Type");
      
      //values will only be filled for non-tweak sprites.
      if(spr->table.type) {
         std::string asm_file = j.at("AsmFile");
         spr->asm_file = append_to_dir(spr->cfg_file, asm_file.c_str());
         
         spr->table.extra[0] = j.at("Extra Property Byte 1");
         spr->table.extra[1] = j.at("Extra Property Byte 2");
         
         spr->byte_count = j.at("Additional Byte Count (extra bit clear)");
         spr->extra_byte_count = j.at("Additional Byte Count (extra bit set)");
         CAP(spr->byte_count, 4);
         CAP(spr->extra_byte_count, 4);
      }
      
      unsigned char tmp = 0;
      #define SET(TWEAK, J) {\
            tmp = 0;\
            J(tmp, j);\
            spr->table.tweak[TWEAK] = tmp;\
         }
         
      SET(0, J1656)
      SET(1, J1662)
      SET(2, J166E)
      SET(3, J167A)
      SET(4, J1686)
      SET(5, J190F)
         
      #undef SET
      
      std::string decoded = base64_decode(j.at("Map16"));
      spr->map_block_count = decoded.size() / 8;
      spr->map_data = (map16*)strcln(decoded);
      
      //displays
      spr->display_count = j.at("Displays").size();
      spr->displays = new display[spr->display_count];
      int counter = 0;
      for(auto jdisplay : j.at("Displays")) {
         display* dis = spr->displays + counter;
         
         dis->description = strcln(jdisplay.at("Description"));
         
         dis->x = jdisplay.at("X");
         dis->y = jdisplay.at("Y");
         CAP(dis->x, 0x0F);
         CAP(dis->y, 0x0F);         
         dis->extra_bit = jdisplay.at("ExtraBit");
         
         if(jdisplay.at("UseText")) {
            dis->tile_count = 1;
            dis->tiles = new tile[1];
            dis->tiles->text = strcln(jdisplay.at("DisplayText"));
         }
         else {
            dis->tile_count = jdisplay.at("Tiles").size();
            dis->tiles = new tile[dis->tile_count];
            int counter2 = 0;
            for(auto jtile : jdisplay.at("Tiles")) {
               tile* til = dis->tiles + counter2;
               til->x_offset = jtile.at("X offset");
               til->y_offset = jtile.at("Y offset");
               til->tile_number = jtile.at("map16 tile");
               counter2++;
            }         
         }      
         counter++;
      }
      
      //collections
      counter = 0;
      spr->collection_count = j.at("Collection").size();
      spr->collections = new collection[spr->collection_count];
      for(auto jCollection : j.at("Collection")) {
         collection* col = spr->collections + counter;
         col->name = strcln(jCollection.at("Name"));
         col->extra_bit = jCollection.at("ExtraBit");
         col->prop[0] = jCollection.at("Extra Property Byte 1");
         col->prop[1] = jCollection.at("Extra Property Byte 2");
         col->prop[2] = jCollection.at("Extra Property Byte 3");
         col->prop[3] = jCollection.at("Extra Property Byte 4");
         counter++;
      }
      
      if(output){	
         fprintf(output, "Parsed %s\n", spr->cfg_file);
      }
      
      return true;
   } catch( const std::domain_error& e) {
      if(output)
         fprintf(output, "Error when parsing json: %s\n", e.what());
      return false;
   } catch( const std::out_of_range& e ) {
      if(output)
         fprintf(output, "Error when parsing json: %s\n", e.what());
      return false;
   }   
   
   #undef CAP
}
