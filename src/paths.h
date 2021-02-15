#include <cstring>
#include <filesystem>
#include <string>

#ifdef DEBUGMSG
template <typename... A> void debug_print(const char *msg, A... args) {
    printf(msg, args...);
}
#endif

bool nameEndWithAsmExtension(const char *name);
bool nameEndWithAsmExtension(std::string_view name);
std::string cleanPathTrailFromString(std::string path);
void set_paths_relative_to(const char **path, const char *arg0);
// combines the path of src and file
// if src is a file itself, it will backtrace to the containing directory
// if src is a direcotry, it needs to have a trailing /
// the returned char* is new and needs to be cleaned.
char *append_to_dir(const char *src, const char *file);