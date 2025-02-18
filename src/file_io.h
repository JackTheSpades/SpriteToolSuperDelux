#ifndef FILES_IO_H
#define FILES_IO_H

#include "structs.h"
#include <cstdio>
#include <cstdlib>
#include <string_view>

FILE* open(const char* name, const char* mode);
size_t file_size(FILE* file);
[[nodiscard]] unsigned char* read_all(const char* file_name, bool text_mode = false, unsigned int minimum_size = 0u);
[[nodiscard]] patchfile write_all(const unsigned char* data, std::string_view file_name, unsigned int size);
[[nodiscard]] patchfile write_all(const unsigned char* data, std::string_view dir, std::string_view file_name,
                                  unsigned int size);
template <size_t N>
[[nodiscard]] patchfile write_all(const unsigned char (&data)[N], std::string_view dir, std::string_view file_name) {
    return write_all(data, dir, file_name, N);
}
template <size_t N> [[nodiscard]] patchfile write_all(const unsigned char (&data)[N], std::string_view file_name) {
    return write_all(data, file_name, N);
}
#endif