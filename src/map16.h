#ifndef MAP16_H
#define MAP16_H

#define MAP16_SIZE 0x1000

struct property {
   char tileset : 1;
   char palette : 3;
   char priority : 2;
   char x_flip : 1;
   char y_flip : 1;
}

struct map8x8 {
	char tile = 0;
	char prop = 0;
};

struct map16 {
	map8x8 top_left;
	map8x8 bottom_left;
	map8x8 top_right;
	map8x8 bottom_right;
};

/**Looks through the map16 array to find empty space the size defined through count
   and returns the index to it. If none is found, negative 1 is returned.
   The map16 is assumed to be the size of MAP16_SIZE.

   @param *map    Pointer to the map16 array which will be searched for free space
   @param count   How many consecutive map16 entries need to be empty
   @return        The index to the empty space
*/
int find_free_map(map16* map, int count);
/**Reads the content of the given file and writes the data to the map16 pointer.
   The file read should be exactly but must be no less than MAP16_SIZE * sizeof(map16) bytes long.

   @param *map    Pointer to the map16 which will be filled by the data.
   @param *file   Filename that will be read.
*/
void read_map16(map16* map, const char* file);

#endif