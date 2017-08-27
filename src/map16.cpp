#include "map16.h"
#include "file_io.h"
#include "structs.h"

int find_free_map(map16* map, int count) {
   if(count == 0)
      return 0;

   char* zero = new char[count * 8];
   memset(zero, 0, count * 8);
   
	for(int i = 0; i < MAP16_SIZE; i+= 8) {
		if(!memcmp(zero, (char*)(map + i), 8)) {
         delete[] zero;
			return i;
      }
	}
   delete[] zero;
	return -1;
}

void open_map16(map16** map, const char* file) {
	(*map) = (map16*)read_all(file);
}
