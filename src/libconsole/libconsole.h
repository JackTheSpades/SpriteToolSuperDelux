#pragma once
#include <cstdarg>
#include <cstddef>
#include <cstdio>
#ifdef ON_WINDOWS
#include <io.h>
#endif

namespace libconsole {

enum class handle { in, out, err };
bool init();
bool read(char* buffer, size_t bufsize, handle);
bool write(const char* buffer, size_t bufsize, handle);
bool write_args(const char* fmt, handle, va_list argptr);
#ifdef ON_WINDOWS 
bool write_handle(const char* buffer, size_t bufsize, void* hdl);
bool write_args_handle(const char* fmt, void* hdl, va_list list);
#else
bool write_handle(const char* buffer, size_t bufsize, FILE* hdl);
bool write_args_handle(const char* fmt, FILE* hdl, va_list list);
#endif
size_t bytelen(const char* buffer);
bool isspace(const char ch);

} // namespace libconsole

inline int cprintf(const char* fmt, ...) {
    va_list list;
    va_start(list, fmt);
    libconsole::write_args(fmt, libconsole::handle::out, list);
    va_end(list);
    return 0;
}

inline int cfprintf(FILE* stream, const char* fmt, ...) {
    va_list list;
    va_start(list, fmt);
#ifdef ON_WINDOWS
    libconsole::write_args_handle(fmt, (void*)_get_osfhandle(_fileno(stream)), list);
#else
    libconsole::write_args_handle(fmt, stream, list);
#endif
    va_end(list);
    return 0;
}