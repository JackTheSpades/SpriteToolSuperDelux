#include "libconsole.h"
#include <cstdio>
#include <type_traits>
#include <cstring>
#include <cstdint>
#include <cstdlib>
#ifdef ON_WINDOWS
#include <Windows.h>
#endif
#include <clocale>

namespace libconsole {

template <typename Tp> struct tbuf {
    using Tpp = std::add_pointer_t<Tp>;
    Tp* buffer;
    size_t m_size;
    tbuf(size_t size) {
        m_size = size;
        buffer = new Tp[size];
    }
    operator Tpp() {
        return buffer;
    }
    size_t size() const {
        return m_size;
    }
    ~tbuf() {
        delete[] buffer;
    }
};

using wctbuf = tbuf<wchar_t>;

#ifdef ON_WINDOWS
HANDLE map_handle(handle hdl) {
    switch (hdl) {
    case handle::err:
        return GetStdHandle(STD_ERROR_HANDLE);
    case handle::out:
        return GetStdHandle(STD_OUTPUT_HANDLE);
    case handle::in:
        return GetStdHandle(STD_INPUT_HANDLE);
    }
    return NULL;
}
#else
FILE* map_handle(handle hdl) {
    switch (hdl) {
    case handle::err:
        return stderr;
    case handle::out:
        return stdout;
    case handle::in:
        return stdin;
    }
    return nullptr;
}
#endif

bool init() {
#ifdef ON_WINDOWS
    UINT codepage = GetConsoleCP();
    if (codepage != CP_UTF8) {
        if (!SetConsoleCP(CP_UTF8))
            return false;
        if (!SetConsoleOutputCP(CP_UTF8))
            return false;
    }
#endif
    return true;
}

bool read(char* buffer, size_t bufsize, handle hdl) {
#ifdef ON_WINDOWS
    wctbuf wstr{bufsize};

    DWORD read{};

    if (!ReadConsole(map_handle(hdl), wstr, bufsize, &read, NULL))
        return false;

    int size = WideCharToMultiByte(CP_UTF8, 0, wstr, read, buffer, bufsize, NULL, NULL);
    buffer[size] = 0;
#else
    fgets(buffer, bufsize, map_handle(hdl));
#endif
    return true;
}

bool write(const char* buffer, size_t bufsize, handle hdl) {
#ifdef ON_WINDOWS 
    int convertResult = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, NULL, 0);
    if (convertResult <= 0) {
        return false;
    } else {
        wctbuf wstr{static_cast<size_t>(convertResult)};
        int conv = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, wstr, convertResult);
        DWORD written{};
        if (!WriteConsole(map_handle(hdl), wstr, conv, &written, NULL))
            return false;
        return written == conv;
    }
#else
    fwrite(buffer, 1, bufsize, map_handle(hdl));
    return true;
#endif
}

#ifdef ON_WINDOWS
bool write_handle(const char* buffer, size_t bufsize, HANDLE hdl) {
    int convertResult = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, NULL, 0);
    if (convertResult <= 0) {
        return false;
    } else {
        wctbuf wstr{static_cast<size_t>(convertResult)};
        int conv = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, wstr, convertResult);
        DWORD written{};
        if (!WriteConsole(hdl, wstr, conv, &written, NULL))
            return false;
        return written == conv;
    }
}

bool write_args(const char* fmt, handle hdl, va_list list) {
    size_t needed = _vscprintf_l(fmt, nullptr, list);
    tbuf<char> buf{needed + 1}; 
    _vsprintf_l(buf, fmt, nullptr, list);
    return write(buf, needed + 1, hdl);
}

bool write_args_handle(const char* fmt, HANDLE hdl, va_list list) {
    size_t needed = _vscprintf_l(fmt, nullptr, list);
    tbuf<char> buf{needed + 1};
    _vsprintf_l(buf, fmt, nullptr, list);
    return write_handle(buf, needed + 1, hdl);
}
#else

bool write_handle(const char* buffer, size_t bufsize, FILE* hdl) {
    fwrite(buffer, 1, bufsize, hdl);
    return true;
}

bool write_args(const char* fmt, handle hdl, va_list list) {
    vfprintf(map_handle(hdl), fmt, list);
    return true;
}

bool write_args_handle(const char* fmt, FILE* hdl, va_list list) {
    vfprintf(hdl, fmt, list);
    return true;
}
#endif

size_t bytelen(const char* buffer) {
    return std::strlen(buffer);
}
bool isspace(const char ch) {
    return (ch == '\r' || ch == '\n' || ch == ' ' || ch == '\v' || ch == '\f');
}
} // namespace libconsole