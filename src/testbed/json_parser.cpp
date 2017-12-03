#include "../json.h"
#include "../structs.h"
#include <stdio.h>

int main(int argc, char** argv)
{
   if(argc < 2) {
      printf("Needs a json file as argument\n");
      return -1;
   }

   sprite spr;
   spr.cfg_file = argv[1];

   printf("Try parsing: %s\n", spr.cfg_file);
   if(!read_json_file(&spr, nullptr)) {
      printf("Parse Failed\n");
      return -1;
   }
   
   printf("Type:       %2X\n", spr.table.type);
   printf("ActLike:    %2X\n", spr.table.actlike);
   printf("Tweak:      %2X, %2X, %2X, %2X, %2X, %2X\n",
      spr.table.tweak[0], spr.table.tweak[1], spr.table.tweak[2], 
      spr.table.tweak[3], spr.table.tweak[4], spr.table.tweak[5]);
   printf("Extra:      %2X, %2X\n", spr.table.extra[0], spr.table.extra[1]);
   printf("ASM File:   %s\n", spr.asm_file);
   
   printf("Byte Count: %d,%d\n", spr.byte_count, spr.extra_byte_count);
   
   printf("\nMap16: ");
   unsigned char* mapdata = (unsigned char*)spr.map_data;
   for(int i = 0; i < spr.map_block_count * 8; i++){
      printf("%2X, ", (int)mapdata[i]);
   }
   printf("\n\n");
   
   
   for(int i = 0; i < spr.display_count; i++){
      display* d = spr.displays + i;
      printf("X: %d, Y: %d, E:%d\n", d->x, d->y, d->extra_bit);
      printf("Description: %s\n", d->description);
      for(int j = 0; j < d->tile_count; j++) {
         tile* t = d->tiles + j;
         if(t->text)
            printf("\t%d,%d,*%s*\n", t->x_offset, t->y_offset, t->text);
         else
            printf("\t%d,%d,%X\n", t->x_offset, t->y_offset, t->tile_number);
      }
   }
   printf("\n");
   
   for(int i = 0; i < spr.collection_count; i++){
      collection* c = spr.collections + i;
      printf("%d (%2X %2X %2X %2X) %s\n", c->extra_bit,
         c->prop1, c->prop2, c->prop3, c->prop4,
         c->name);
   }   
}