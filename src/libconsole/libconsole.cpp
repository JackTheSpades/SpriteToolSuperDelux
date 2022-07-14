#include "libconsole.h"
#include <concepts>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <type_traits>
#ifdef ON_WINDOWS
#include <Windows.h>
#include <bit>
#include <io.h>
#endif

template <typename Tp> struct tbuf {
    using Tpp = std::add_pointer_t<Tp>;
    Tp* buffer;
    size_t m_size;
    tbuf() {
        buffer = nullptr;
        m_size = 0;
    }
    tbuf(size_t size) {
        m_size = size;
        buffer = new Tp[size];
    }
    tbuf(int size) {
        m_size = static_cast<size_t>(size);
        buffer = new Tp[size];
    }
    tbuf(tbuf&& other) noexcept : buffer(other.buffer), m_size(other.m_size) {
        other.buffer = nullptr;
        other.m_size = 0;
    }
    tbuf& operator=(tbuf&& other) {
        if (buffer != nullptr && m_size > 0)
            delete[] buffer;
        buffer = other.buffer;
        m_size = other.m_size;
        other.buffer = nullptr;
        other.m_size = 0;
        return *this;
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
using ctbuf = tbuf<char>;

#ifdef ON_WINDOWS
namespace winutil {
struct ConversionResult {
    wctbuf buf;
    bool success;
};
HANDLE handle_from_file(FILE* ptr) {
    return std::bit_cast<HANDLE>(_get_osfhandle(_fileno(ptr)));
}
bool WideToUTF8(const wchar_t* from, const int from_size, char* to, const int to_max) {
    int required_size = WideCharToMultiByte(CP_UTF8, 0, from, from_size, NULL, 0, NULL, NULL);
    if (to_max < required_size)
        return false;
    int size = WideCharToMultiByte(CP_UTF8, 0, from, from_size, to, to_max, NULL, NULL);
    to[size] = '\0';
    return true;
}
ConversionResult UTF8ToWide(const char* from, const int from_size, DWORD& conv) {
    int convertResult = MultiByteToWideChar(CP_UTF8, 0, from, from_size, NULL, 0);
    if (convertResult <= 0) {
        return {{}, false};
    } else {
        wctbuf wstr{convertResult};
        conv = MultiByteToWideChar(CP_UTF8, 0, from, from_size, wstr, convertResult);
        return {std::move(wstr), true};
    }
}
bool HasConsole(HANDLE hdl) {
    // https://github.com/rust-lang/rust/blob/7355d971a954ed63293e4191f6677f60c1bc07d9/library/std/src/sys/windows/stdio.rs#L78
    DWORD mode = 0;
    BOOL res = GetConsoleMode(hdl, &mode);
    return res;
}
} // namespace winutil
#endif

namespace libconsole {

#ifdef ON_WINDOWS
HANDLE map_handle(handle hdl) {
    static struct {
        HANDLE err = GetStdHandle(STD_ERROR_HANDLE);
        HANDLE out = GetStdHandle(STD_OUTPUT_HANDLE);
        HANDLE in = GetStdHandle(STD_INPUT_HANDLE);
    } cached_handles;
    switch (hdl) {
    case handle::err:
        return cached_handles.err;
    case handle::out:
        return cached_handles.out;
    case handle::in:
        return cached_handles.in;
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
    return NULL;
}
#endif

#ifdef ON_WINDOWS
BOOL GenericRead(HANDLE hdl, wchar_t* wbuffer, DWORD wbufsize, char* buffer, DWORD bufsize, LPDWORD read) {
    if (winutil::HasConsole(hdl))
        return ReadConsole(hdl, wbuffer, wbufsize, read, NULL);
    else
        return ReadFile(hdl, buffer, bufsize, read, NULL);
}

BOOL GenericWrite(HANDLE hdl, const char* buffer, DWORD bufsize) {
    BOOL ret = FALSE;
    DWORD written = 0;
    if (hdl == NULL) {
        if (IsDebuggerPresent()) {
            OutputDebugStringA(buffer);
        }
        return TRUE;
    } else if (winutil::HasConsole(hdl)) {
        DWORD conv = 0;
        auto&& [wstr, res] = winutil::UTF8ToWide(buffer, bufsize, conv);
        if (!res)
            return false;
        ret = WriteConsole(hdl, wstr, static_cast<DWORD>(wstr.size()), &written, NULL) && (written == conv);

    } else {
        ret = WriteFile(hdl, buffer, bufsize, &written, NULL);
    }
    return ret;
}
#endif

bool read(char* buffer, int bufsize, handle hdl) {
#ifdef ON_WINDOWS
    wctbuf wstr{bufsize};
    DWORD read = 0;
    HANDLE real_hdl = map_handle(hdl);
    if (BOOL ptr = GenericRead(real_hdl, wstr, bufsize, buffer, bufsize, &read); !ptr)
        return false;
    if (winutil::HasConsole(real_hdl)) {
        return winutil::WideToUTF8(wstr, read, buffer, bufsize);
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
    return GenericWrite(map_handle(hdl), buffer, bufsize);
#else
    fwrite(buffer, 1, bufsize, map_handle(hdl));
    return true;
#endif
}

#ifdef ON_WINDOWS
bool write_handle(const char* buffer, int bufsize, FILE* fp) {
    return GenericWrite(winutil::handle_from_file(fp), buffer, bufsize);
}

bool write_args(const char* fmt, handle hdl, va_list list) {
    int needed = _vscprintf_l(fmt, nullptr, list);
    tbuf<char> buf{needed + 1};
    int written = _vsprintf_l(buf, fmt, nullptr, list);
    return write(buf, written, hdl);
}

bool write_args_handle(const char* fmt, FILE* hdl, va_list list) {
    int needed = _vscprintf_l(fmt, nullptr, list);
    tbuf<char> buf{needed + 1};
    int written = _vsprintf_l(buf, fmt, nullptr, list);
    return write_handle(buf, written, hdl);
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
    return (ch == '\r' || ch == '\n' || ch == ' ' || ch == '\v' || ch == '\f' || ch == '\t');
}
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
int console::cprintf(const char* fmt, ...) {
    va_list list;
    va_start(list, fmt);
    libconsole::write_args(fmt, libconsole::handle::out, list);
    va_end(list);
    return 0;
}

int console::cfprintf(FILE* stream, const char* fmt, ...) {
    va_list list;
    va_start(list, fmt);
    libconsole::write_args_handle(fmt, stream, list);
    va_end(list);
    return 0;
}
} // namespace libconsole
