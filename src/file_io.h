#ifndef FILES_IO_H
#define FILES_IO_H

#include <cstdio>
#include <cstdlib>
#include <string_view>
#include "structs.h"

FILE *open(const char *name, const char *mode);
size_t file_size(FILE *file);
[[nodiscard]] unsigned char *read_all(const char *file_name, bool text_mode = false, unsigned int minimum_size = 0u);
[[nodiscard]] patchfile write_all(unsigned char *data, std::string_view file_name, unsigned int size);
[[nodiscard]] patchfile write_all(unsigned char* data, std::string_view dir, std::string_view file_name,
                                  unsigned int size);

#endif