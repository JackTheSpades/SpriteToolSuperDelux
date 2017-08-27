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
   spr->map_data = (map16*)strcln(decoded.c_str());
   
   spr->display_count = j["displays"].size();
   spr->displays = new display[spr->display_count];
   int counter = 0;
   for(auto jdisplay : j["displays"]) {
      display* dis = spr->displays + counter;
      counter++;
   }
   
   return false;
   
}
