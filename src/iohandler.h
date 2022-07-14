#pragma once

#include "libconsole/libconsole.h"
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <string>
#include <cstring>

class iohandler {

    using con = libconsole::console;
    enum iotype { in = 0, out = 1, err = 2, debug_ = 3 };

    FILE* m_handles[4]{};
    bool m_replaced[4]{};
    std::string m_last_error;
	
    void set(iotype tp, FILE* newhandle);

    template <typename... Args> void print_generic(iotype tp, const char* message, Args... args) {
        if (m_replaced[tp]) {
            con::cfprintf(m_handles[tp], message, args...);
        } else {
            con::cprintf(message, args...);
        }
    }

  public:
    static iohandler& get_global();
    iohandler();
    const auto& last_error() const {
        return m_last_error;
    }
    FILE* get_out() {
        return m_handles[out];
    }
    FILE* get_err() {
        return m_handles[err];
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
    void set_err(FILE* newhandle) {
        set(err, newhandle);
    }
    void set_debug(FILE* newhandle) {
        set(debug_, newhandle);
    }
    void error(const char* message) {
        // prints to stdout for backwards compatibility
        m_last_error = message;
        print_generic(out, message);
    }
    template <typename... Args> void error(const char* message, Args... args) {
        // prints to stdout for backwards compatibility
        int needed = snprintf(nullptr, 0, message, args...);
        m_last_error.resize(needed, '\0');
        snprintf(m_last_error.data(), needed + 1, message, args...);
        print_generic(out, message, args...);
    }
    void print(const char* message) {
        print_generic(out, message);
    }
    template <typename... Args> void print(const char* message, Args... args) {
        print_generic(out, message, args...);
    }
    void debug(const char* message) {
        if (m_handles[debug_] != nullptr)
            print_generic(debug_, message);
    }
    template <typename... Args> void debug(const char* message, Args... args) {
        if (m_handles[debug_] != nullptr) {
            print_generic(debug_, message, args...);
        }
    }
    int scanf(const char* fmt, ...);
    size_t read(char* buf, int size);
    char* readline(char* buf, int size);
    char getc();
    ~iohandler();
};