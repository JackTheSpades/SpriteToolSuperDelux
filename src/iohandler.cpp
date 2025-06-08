#include "iohandler.h"

void iohandler::init() {
    iohandler& handler = get_global();

    handler.m_debug_enabled = false;

    for (const auto* ptr : handler.m_output_lines) {
        delete[] ptr;
    }
    handler.m_output_lines.clear();
    handler.m_last_error.clear();
}

iohandler& iohandler::get_global() {
    static iohandler global_handler{};
    return global_handler;
}

iohandler::iohandler() : m_debug_enabled{false} {
}
char iohandler::getc() {
    return static_cast<char>(fgetc(stdin));
}

iohandler::~iohandler() {
    for (const auto* ptr : m_output_lines) {
        delete[] ptr;
    }
}

int iohandler::scanf(const char* fmt, ...) {
    va_list list{};
    va_start(list, fmt);
    int ret = vfscanf(stdin, fmt, list);
    va_end(list);
    return ret;
}

size_t iohandler::read(char* buf, int size) {
    return fread(buf, sizeof(char), size, stdin);
}
char* iohandler::readline(char* buf, int size) {
    return fgets(buf, size, stdin);
}