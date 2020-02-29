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
unsigned char* read_all(const char *file_name, bool text_mode = false, unsigned int minimum_size = 0u, FILE *output = nullptr);
void write_all(unsigned char *data, const char *file_name, unsigned int size);
void write_all(unsigned char *data, const char* dir, const char *file_name, unsigned int size);


// combines the path of src and file
// if src is a file itself, it will backtrace to the containing directory
// if src is a direcotry, it needs to have a trailing /
// the returned char* is new and needs to be cleaned.
char* append_to_dir(const char* src, const char* file);

#endif