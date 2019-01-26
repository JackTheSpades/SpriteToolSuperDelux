#ifndef FILES_IO_H
#define FILES_IO_H

#include <stdlib.h>
#include <stdio.h>

template <typename ...A>
void error(const char *message, A... args) {
	printf(message, args...);
	exit(-1);
}

FILE *open(const char *name, const char *mode);
int file_size(FILE *file);
unsigned char* read_all(const char *file_name, bool text_mode = false, unsigned int minimum_size = 0u);
void write_all(unsigned char *data, const char *file_name, unsigned int size);
void write_all(unsigned char *data, const char* dir, const char *file_name, unsigned int size);

/**

   @param destination      The stream to which the data will be written
   @param source_file      The filename from which data will be read and then copied to {destination}
   @param text_mode        True if {source_file} is a plain text file and not a binary.
   @param skip_beginning   How many bytes should be skipped at the beginning of {source_file}
   @param skip_end         How many bytes should be skipped at the end of {source_file}
*/
void copy_to(FILE* destination, const char* source_file, bool text_mode = false, int skip_beginning = 0, int skip_end = 0);


/**
   @param *dir
   @param *file
*/
void remove(const char* dir, const char* file);

/**combines the path of src and file
// if src is a file itself, it will backtrace to the containing directory
// if src is a direcotry, it needs to have a trailing /
// the returned char* is new and needs to be cleaned.
*/
char* append_to_dir(const char* src, const char* file);

#endif