#include "file_io.h"
#include "iohandler.h"
#include "paths.h"
#include <cerrno>
#include <cstdio>
#include <cstring>

FILE* open(const char* name, const char* mode) {
    FILE* file = fopen(name, mode);
    if (!file) {
        iohandler::get_global().error("Could not open \"%s\": %s\n", name, strerror(errno));
        return nullptr;
    }
    return file;
}

size_t file_size(FILE *file) {
    long off = ftell(file);
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    fseek(file, off, SEEK_SET);
    return size;
}

unsigned char *read_all(const char *file_name, bool text_mode, unsigned int minimum_size) {
    FILE *file = open(file_name, "rb");
    if (file == nullptr) {
        return nullptr;
    }
    size_t size = file_size(file);
    unsigned char *file_data = new unsigned char[(size < minimum_size ? minimum_size : size) + (text_mode * 2)];
    if (fread(file_data, 1, size, file) != size) {
        iohandler::get_global().error("%s could not be fully read.  Please check file permissions.", file_name);
        delete[] file_data;
        return nullptr;
    }
    fclose(file);
    return file_data;
}

patchfile write_all(unsigned char* data, std::string_view file_name, unsigned int size) {
    patchfile file{std::string{file_name}, static_cast<patchfile::openflags>(std::ios::out | std::ios::binary)};
    file.fwrite(data, size);
    file.close();
    return file;
}

patchfile write_all(unsigned char* data, std::string_view dir, std::string_view file_name, unsigned int size) {
    std::string fullpath{dir};
	fullpath += file_name;
    return write_all(data, fullpath, size);
}
