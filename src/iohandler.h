#pragma once

#include "libconsole/libconsole.h"
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

template <typename... Args> std::string fstring(const char* format, Args&&... args) {
    int needed = snprintf(nullptr, 0, format, args...);
    std::string buffer{};
    buffer.resize(needed);
    snprintf(buffer.data(), needed + 1, format, args...);
    return buffer;
}

class iohandler {

    using con = libconsole::console;
    enum iotype { in = 0, out = 1, debug_ = out };

    FILE* m_handles[2]{};
    bool m_replaced[2]{};
    bool m_debug_enabled{};
    std::string m_last_error;
    std::vector<const char*> m_output_lines;

    void set(iotype tp, FILE* newhandle);

    template <typename... Args> void append_to_output(const char* format, Args... args) {
        int needed = snprintf(nullptr, 0, format, args...);
        char* buffer = new char[needed + 1];
        snprintf(buffer, needed + 1, format, args...);
        m_output_lines.push_back(buffer);
    }

    void append_to_output(const char* message) {
        char* buffer = new char[strlen(message) + 1];
        strcpy(buffer, message);
        m_output_lines.push_back(buffer);
    }

    template <typename... Args> void print_generic([[maybe_unused]] iotype tp, const char* message, Args... args) {
        append_to_output(message, args...);
#ifdef PIXI_EXE_BUILD
        if (m_replaced[tp]) {
            con::cfprintf(m_handles[tp], message, args...);
        } else {
            con::cprintf(message, args...);
        }
#endif
    }

  public:
    static void init();
    static iohandler& get_global();
    iohandler();
    const auto& last_error() const {
        return m_last_error;
    }
    const auto& output_lines() const {
        return m_output_lines;
    }
    FILE* get_out() {
        return m_handles[out];
    }
    FILE* get_debug() {
        return m_handles[debug_];
    }
    FILE* get_in() {
        return m_handles[in];
    }
    void set_out(FILE* newhandle) {
        set(out, newhandle);
    }
    void set_in(FILE* newhandle) {
        set(in, newhandle);
    }
    void set_debug(FILE* newhandle) {
        set(debug_, newhandle);
    }
    void enable_debug() {
        m_debug_enabled = true;
    }
    void error(const char* message) {
        // prints to stdout for backwards compatibility
        m_last_error += message;
        print_generic(out, message);
    }
    template <typename... Args> void error(const char* message, Args... args) {
        // prints to stdout for backwards compatibility
        m_last_error += fstring(message, args...);
        print_generic(out, message, args...);
    }
    void print(const char* message) {
        print_generic(out, message);
    }
    template <typename... Args> void print(const char* message, Args... args) {
        print_generic(out, message, args...);
    }
    void debug(const char* message) {
        if (m_debug_enabled)
            print_generic(debug_, message);
    }
    template <typename... Args> void debug(const char* message, Args... args) {
        if (m_debug_enabled) {
            print_generic(debug_, message, args...);
        }
    }
    int scanf(const char* fmt, ...);
    size_t read(char* buf, int size);
    char* readline(char* buf, int size);
    char getc();
    ~iohandler();
};
