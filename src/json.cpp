#include "json.h"
#include "json/json.hpp"
#include "json/base64.h"
#include "json_const.h"
#include "structs.h"
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
   std::ifstream instr(spr->cfg_file);
   instr >> j;
   

   spr->asm_file = strcln(j["AsmFile"]);
   spr->table.actlike = j["ActLike"];
   spr->table.type = j["Type"];
   
   spr->table.extra[0] = j["Extra Property Byte 1"];
   spr->table.extra[1] = j["Extra Property Byte 2"];
   
   spr->byte_count = j["Additional Byte Count (extra bit clear)"];
   spr->extra_byte_count = j["Additional Byte Count (extra bit set)"];
   
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
   
   std::string decoded = base64_decode(j["Map16"]);
   spr->map_block_count = decoded.size() / 8;
   spr->map_data = (map16*)strcln(decoded);
   
   //displays
   spr->display_count = j["Displays"].size();
   spr->displays = new display[spr->display_count];
   int counter = 0;
   for(auto jdisplay : j["Displays"]) {
      display* dis = spr->displays + counter;
      
      dis->description = strcln(jdisplay["Description"]);
      
      dis->x = jdisplay["X"];
      dis->y = jdisplay["Y"];
      dis->extra_bit = jdisplay["ExtraBit"];
      if(jdisplay["UseText"]) {
         dis->tile_count = 1;
         dis->tiles = new tile[1];
         dis->tiles->text = strcln(jdisplay["DisplayText"]);
      }
      else {
         dis->tile_count = jdisplay["Tiles"].size();
         dis->tiles = new tile[dis->tile_count];
         int counter2 = 0;
         for(auto jtile : jdisplay["Tiles"]) {
            tile* til = dis->tiles + counter2;
            til->x_offset = jtile["X offset"];
            til->y_offset = jtile["Y offset"];
            til->tile_number = jtile["map16 tile"];
            counter2++;
         }         
      }      
      counter++;
   }
   
   //collections
   counter = 0;
   spr->collection_count = j["Collection"].size();
   spr->collections = new collection[spr->collection_count];
   for(auto jCollection : j["Collection"]) {
      collection* col = spr->collections + counter;
      col->name = strcln(jCollection["Name"]);
      col->extra_bit = jCollection["ExtraBit"];
      col->prop1 = jCollection["Extra Property Byte 1"];
      col->prop2 = jCollection["Extra Property Byte 2"];
      col->prop3 = jCollection["Extra Property Byte 3"];
      col->prop4 = jCollection["Extra Property Byte 4"];
      counter++;
   }
   
   return true;
   
}
