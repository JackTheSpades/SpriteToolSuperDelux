#include "paths.h"
#include <filesystem>
namespace fs = std::filesystem;

bool nameEndWithAsmExtension(std::string_view name) {
    return name.ends_with(".asm");
}

std::string cleanPathTrail(std::string path) {
    if (path.back() == '/' || path.back() == '\\')
        path.pop_back();
    return path;
}

void set_paths_relative_to(std::string& path, const char* arg0) {
    if (path.empty())
        return;
    fs::path filePath{path};
    fs::path arg0p{arg0};
#ifdef _WIN32
    // arg0p => either rom path or exe path (rom path in case of list.txt except when --exerel is passed and for
    // mwt/mw2/ssc/s16, exe path otherwise) filePath => path to make relative
    if (arg0p.has_root_name() && arg0p.is_absolute() && !filePath.is_absolute()) {
        fs::path cwd = fs::current_path();

        fs::path current_drive = cwd.root_name();
        fs::path arg_drive = arg0p.root_name();
        if (current_drive != arg_drive) {
            if (arg0p.has_filename()) {
                arg0p = arg0p.parent_path();
            }
            // if the cwd is on a different drive than arg0, std::filesystem::relative will return "" and subsequently
            // cause issues therefore the simplest solution is to ignore everything and just append the filepath to
            // arg0p.
            path = (arg0p / filePath).generic_string();
            return;
        }
    }
#endif

    fs::path absBasePath = fs::relative(arg0p);
    absBasePath.remove_filename();
#ifdef DEBUGMSG
    debug_print("Absolute base path: %s ", absBasePath.generic_string().c_str());
#endif
    std::string newPath{};
    if (filePath.is_relative()) {
        newPath = absBasePath.generic_string() + filePath.generic_string();
    } else {
        newPath = filePath.generic_string();
    }
#ifdef DEBUGMSG
    debug_print("%s\n", newPath.c_str());
#endif

    if (fs::is_directory(newPath) && newPath.back() != '/' && newPath.back() != '\\') {
        path = newPath + "/";
    } else {
        path = newPath;
    }
}

std::string append_to_dir(std::string_view src, std::string_view file) {
    auto unix_end = src.find_last_of('/');
    auto win_end = src.find_last_of('\\');
    constexpr auto npos = std::string_view::npos;
    auto end = npos;
    if (unix_end != npos && win_end != npos) {
        end = std::max(unix_end, win_end);
    } else if (unix_end != npos) {
        end = unix_end;
    } else if (win_end != npos) {
        end = win_end;
    }
    // fetches path of src and append it before
    size_t len = end == npos ? 0 : end + 1;
    std::string new_file{src.substr(0, len)};
    new_file += file;
    for (char& c : new_file) {
        if (c == '\\')
            c = '/';
    }
    return new_file;
}