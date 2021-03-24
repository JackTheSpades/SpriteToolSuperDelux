#include "paths.h"

bool nameEndWithAsmExtension(const char *name) {
    return !strcmp(".asm", name + strlen(name) - 4) && name[0] != '.';
}

bool nameEndWithAsmExtension(std::string_view name) {
    return nameEndWithAsmExtension(name.data());
}

std::string cleanPathTrail(std::string path) {
    if (path.back() == '/' || path.back() == '\\')
        path.pop_back();
    return path;
}

void set_paths_relative_to(std::string& path, const char *arg0) {

    if (path.empty())
        return;

    std::filesystem::path absBasePath(std::filesystem::absolute(arg0));
    absBasePath.remove_filename();
#ifdef DEBUGMSG
    debug_print("Absolute base path: %s ", absBasePath.generic_string().c_str());
#endif
    std::filesystem::path filePath(path);
    std::string newPath{};
    if (filePath.is_relative()) {
        newPath = absBasePath.generic_string() + filePath.generic_string();
    } else {
        newPath = filePath.generic_string();
    }
#ifdef DEBUGMSG
    debug_print("%s\n", newPath.c_str());
#endif

    if (std::filesystem::is_directory(newPath) && newPath.back() != '/') {
        path = newPath + "/";
    } else {
        path = newPath;
    }
}

char *append_to_dir(const char *src, const char *file) {
    std::string source(src);
    auto unix_end = source.find_last_of('/');
    auto win_end = source.find_last_of('\\');
    auto end = std::string::npos;
    if (unix_end != std::string::npos && win_end != std::string::npos) {
        end = std::max(unix_end, win_end);
    } else if (unix_end != std::string::npos) {
        end = unix_end;
    } else if (win_end != std::string::npos) {
        end = win_end;
    }
    // fetches path of src and append it before
    size_t len = end == std::string::npos ? 0 : end + 1;
    char *new_file = new char[len + strlen(file) + 1];
    strncpy(new_file, src, len);
    new_file[len] = 0;
    strcat(new_file, file);
    for (char *ptr = new_file; *ptr != '\0'; ptr++)
        if (*ptr == '\\')
            *ptr = '/';
    return new_file;
}