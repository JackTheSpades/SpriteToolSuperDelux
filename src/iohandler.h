#pragma once

#include "libconsole/libconsole.h"
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#ifndef _SAL_VERSION
#define _In_z_ 
#define _Printf_format_string_
#endif

template <typename... Args> std::string fstring(const char* format, Args&&... args) {
    int needed = snprintf(nullptr, 0, format, args...);
    std::string buffer{};
    buffer.resize(needed);
    snprintf(buffer.data(), needed + 1, format, args...);
    return buffer;
}

class iohandler {

    using con = libconsole::console;

    bool m_debug_enabled{};
    std::string m_last_error;
    std::vector<const char*> m_output_lines;

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

    template <typename... Args> void print_generic(const char* message, Args... args) {
        append_to_output(message, args...);
#ifdef PIXI_EXE_BUILD
        con::cprintf(message, args...);
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
    void enable_debug() {
        m_debug_enabled = true;
    }
    void error(const char* message) {
        // prints to stdout for backwards compatibility
        m_last_error += message;
        print_generic(message);
    }
    template <typename... Args> void error(_In_z_ _Printf_format_string_ const char* message, Args... args) {
        // prints to stdout for backwards compatibility
        m_last_error += fstring(message, args...);
        print_generic(message, args...);
    }
    void print(const char* message) {
        print_generic(message);
    }
    template <typename... Args> void print(_In_z_ _Printf_format_string_ const char* message, Args... args) {
        print_generic(message, args...);
    }
    void debug(const char* message) {
        if (m_debug_enabled)
            print_generic(message);
    }
    template <typename... Args> void debug(_In_z_ _Printf_format_string_ const char* message, Args... args) {
        if (m_debug_enabled) {
            print_generic(message, args...);
        }
    }
    int scanf(const char* fmt, ...);
    size_t read(char* buf, int size);
    char* readline(char* buf, int size);
    char getc();
    ~iohandler();
};
