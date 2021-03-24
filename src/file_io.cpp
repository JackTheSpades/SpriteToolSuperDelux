#include "file_io.h"
#include "paths.h"
#include <cstdio>
#include <cstring>

FILE *open(const char *name, const char *mode) {
    FILE *file = fopen(name, mode);
    if (!file) {
        error("Could not open \"%s\"\n", name);
    }
    return file;
}

size_t file_size(FILE *file) {
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    fseek(file, 0, SEEK_SET);
    return size;
}

unsigned char *read_all(const char *file_name, bool text_mode, unsigned int minimum_size) {
    FILE *file = open(file_name, "rb");
    unsigned int size = file_size(file);
    unsigned char *file_data = new unsigned char[(size < minimum_size ? minimum_size : size) + (text_mode * 2)]();
    if (fread(file_data, 1, size, file) != size) {
        error("%s could not be fully read.  Please check file permissions.", file_name);
    }
    fclose(file);
    return file_data;
}

void write_all(unsigned char *data, const char *file_name, unsigned int size) {
    FILE *file = open(file_name, "wb");
    if (fwrite(data, 1, size, file) != size) {
        error("%s could not be fully written.  Please check file permissions.", file_name);
    }
    fclose(file);
}

void write_all(unsigned char *data, const char *dir, const char *file_name, unsigned int size) {
    char *path = new char[strlen(dir) + strlen(file_name) + 1];
    path[0] = 0;
    strcat(path, dir);
    strcat(path, file_name);
    write_all(data, path, size);
    delete[] path;
}

void write_all(unsigned char *data, std::string_view file_name, unsigned int size) {
    write_all(data, file_name.data(), size);
}

void write_all(unsigned char *data, std::string_view dir, std::string_view file_name, unsigned int size) {
    write_all(data, dir.data(), file_name.data(), size);
}
