#include <stdio.h>
#include <string.h>
#include "file_io.h"

FILE *open(const char *name, const char *mode) {
	FILE *file = fopen(name, mode);
	if(!file){
		error("Could not open \"%s\"\n", name);
	}
	return file;
}

int file_size(FILE *file) {
	fseek(file, 0, SEEK_END);
	int size = ftell(file);
	fseek(file, 0, SEEK_SET);
	return size;
}

void remove(const char* dir, const char* file) {   
   int strlen_dir = strlen(dir);
   bool has_trailing = dir[strlen_dir - 1] == '/' || dir[strlen_dir - 1] == '\\';
   
   char* path = new char[strlen_dir + strlen(file) + (has_trailing ? 1 : 2)];
   path[0] = 0;
   strcat(path, dir);
   if(!has_trailing)
      strcat(path, "/");
   strcat(path, file);
   remove(path);
   delete[] path;
}

unsigned char* read_all(const char *file_name, bool text_mode, unsigned int minimum_size) {
	FILE *file = open(file_name, "rb");
	unsigned int size = file_size(file);
	unsigned char *file_data = new unsigned char[(size < minimum_size ? minimum_size : size) + (text_mode * 2)]();
	if(fread(file_data, 1, size, file) != size){
		error("%s could not be fully read.  Please check file permissions.", file_name);
	}
	fclose(file);
	return file_data;
}

void write_all(unsigned char* data, const char* file_name, unsigned int size)
{
	FILE *file = open(file_name, "wb");
	if(fwrite(data, 1, size, file) != size){
		error("%s could not be fully written.  Please check file permissions.", file_name);
	}
	fclose(file);
}

char* append_to_dir(const char* src, const char* file) {
   
	//fetches path of src and appand it before
	char* dic_end = strrchr(src,'/');	//last '/' in string
	size_t len = 0;
	if(dic_end) len = dic_end - src + 1;
		
   char* new_file = new char[len + strlen(file) + 1];     
	strncpy(new_file, src, len);
	new_file[len] = 0;
	strcat(new_file, file); 
   
   return new_file;
}
void write_all(unsigned char* data, const char* dir, const char* file_name, unsigned int size)
{
   char* path = new char[strlen(dir) + strlen(file_name) + 1];
   path[0] = 0;
   strcat(path, dir);
   strcat(path, file_name);
   write_all(data, path, size);
   delete[] path;
}