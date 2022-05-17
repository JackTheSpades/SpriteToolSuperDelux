#include "libconsole.h"
#include <cstdio>
#include <type_traits>
#include <cstring>
#include <cstdint>
#include <cstdlib>
#ifdef ON_WINDOWS
#include <Windows.h>
#include <io.h>
#include <bit>
#endif

namespace libconsole {

template <typename Tp> struct tbuf {
    using Tpp = std::add_pointer_t<Tp>;
    Tp* buffer;
    size_t m_size;
    tbuf(size_t size) {
        m_size = size;
        buffer = new Tp[size];
    }
    tbuf(int size) {
        m_size = static_cast<size_t>(size);
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
HANDLE handle_from_file(FILE* ptr) {
    return std::bit_cast<HANDLE>(_get_osfhandle(_fileno(ptr)));
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
    return NULL;
}
#endif

bool init() {
#ifdef ON_WINDOWS
    AllocConsole();
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

#ifdef ON_WINDOWS
BOOL GenericRead(HANDLE hdl, wchar_t* wbuffer, DWORD wbufsize, char* buffer, DWORD bufsize, LPDWORD read) {
    // https://github.com/rust-lang/rust/blob/7355d971a954ed63293e4191f6677f60c1bc07d9/library/std/src/sys/windows/stdio.rs#L78
    DWORD mode = 0;
    BOOL res = GetConsoleMode(hdl, &mode);
    if (res)
        return ReadConsole(hdl, wbuffer, wbufsize, read, NULL);
    else {
        return ReadFile(hdl, buffer, bufsize, read, NULL);
    }
}
BOOL GenericWrite(HANDLE hdl, const wchar_t* wbuffer, DWORD wbufsize, const char* buffer, DWORD bufsize, LPDWORD written) {
    // https://github.com/rust-lang/rust/blob/7355d971a954ed63293e4191f6677f60c1bc07d9/library/std/src/sys/windows/stdio.rs#L78
    DWORD mode = 0;
    BOOL res = GetConsoleMode(hdl, &mode);
    if (res)
        return WriteConsole(hdl, wbuffer, wbufsize, written, NULL);
    else
        return WriteFile(hdl, buffer, bufsize, written, NULL);
}
#endif

bool read(char* buffer, int bufsize, handle hdl) {
#ifdef ON_WINDOWS
    wctbuf wstr{bufsize};
    DWORD read = 0; 
    HANDLE real_hdl = map_handle(hdl);
    if (BOOL ptr = GenericRead(real_hdl, wstr, bufsize, buffer, bufsize, &read); !ptr)
        return false;
    DWORD mode = 0;
    if (GetConsoleMode(real_hdl, &mode)) {
        int size = WideCharToMultiByte(CP_UTF8, 0, wstr, read, buffer, bufsize, NULL, NULL);
        buffer[size] = '\0';
    } else {
        buffer[read] = '\0';
    }
#else
    fgets(buffer, bufsize, map_handle(hdl));
#endif
    return true;
}

bool write(const char* buffer, int bufsize, handle hdl) {
#ifdef ON_WINDOWS 
    int convertResult = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, NULL, 0);
    if (convertResult <= 0) {
        return false;
    } else {
        wctbuf wstr{convertResult};
        DWORD written = 0;
        int conv = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, wstr, convertResult);
        if (auto ret = GenericWrite(map_handle(hdl), wstr, conv, buffer, bufsize, &written); !ret)
            return false;
        return conv == written;
    }
#else
    fwrite(buffer, 1, bufsize, map_handle(hdl));
    return true;
#endif
}

#ifdef ON_WINDOWS
bool write_handle(const char* buffer, int bufsize, FILE* fp) {
    int convertResult = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, NULL, 0);
    if (convertResult <= 0) {
        return false;
    } else {
        wctbuf wstr{convertResult};
        DWORD written = 0;
        int conv = MultiByteToWideChar(CP_UTF8, 0, buffer, bufsize, wstr, convertResult);
        if (auto ret = GenericWrite(handle_from_file(fp), wstr, conv, buffer, bufsize, &written); !ret)
            return false;
        return conv == written;
    }
}

bool write_args(const char* fmt, handle hdl, va_list list) {
    int needed = _vscprintf_l(fmt, nullptr, list);
    tbuf<char> buf{needed + 1}; 
    _vsprintf_l(buf, fmt, nullptr, list);
    return write(buf, needed + 1, hdl);
}

bool write_args_handle(const char* fmt, FILE* hdl, va_list list) {
    int needed = _vscprintf_l(fmt, nullptr, list);
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