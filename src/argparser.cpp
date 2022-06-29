#include "argparser.h"

#include <charconv>
#include <filesystem>
#include <iostream>
#include <sstream>
#ifdef _WIN32
#include <Windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#include <limits.h>
#else
#include <unistd.h>
#include <limits.h>
#endif

static std::string GetExecutableName() {
#ifdef _WIN32
    WCHAR moduleNameW[MAX_PATH]{};
    if (DWORD sz = GetModuleFileName(NULL, moduleNameW, MAX_PATH); sz == 0) {
        return {};
    } else {
        return std::filesystem::path{moduleNameW}.filename().string();
    }
#elif defined(__APPLE__)
    char exeName[PATH_MAX]{};
    uint32_t size = 0;
    if (auto sz = _NSGetExecutablePath(exeName, &size); sz == -1) {
        return {};
    } else {
        exeName[size] = '\0';
        return std::filesystem::path{exeName}.filename().string();
    }
#else
    char exeName[PATH_MAX]{};
    if (auto sz = readlink("/proc/self/exe", exeName, PATH_MAX); sz == -1) {
        return {};
    } else {
        exeName[sz] = '\0';
        return std::filesystem::path{exeName}.filename().string();
    }
#endif
}

bool argparser::init(const nlohmann::json& args) {
    m_program_name = GetExecutableName();
    if (m_program_name.empty())
        return false;
    if (args.is_object()) {
        for (const auto& [key, val] : args.items()) {
            if (val.is_boolean()) {
                if (val.get<bool>())
                    m_arguments.push_back(key);
            } else if (val.is_number()) {
                m_arguments.push_back(key);
                m_arguments.push_back(std::to_string(val.get<int>()));
            } else if (val.is_string()) {
                m_arguments.push_back(key);
                m_arguments.push_back(val);
            } else {
                return false;
            }
        }
        return true;
    } else {
        return false;
    }
}

bool argparser::init(int argc, const char** argv) {
    size_t argcs = static_cast<size_t>(argc);
    m_arguments.reserve(argcs - 1);
    m_program_name = GetExecutableName();
    for (size_t i = 1; i < argcs; i++) {
        m_arguments.push_back(argv[i]);
    }
    return true;
}

void argparser::add_version(uint8_t version_partial, uint8_t version_edition) {
    m_version_partial = version_partial;
    m_version_edition = version_edition;
}

void argparser::allow_unmatched(size_t quantity) {
    m_leftover_args_needed = quantity;
}

void argparser::add_usage_string(std::string_view usage_string) {
    m_usage_string = usage_string;
}

bool argparser::parse() {
    auto help_it =
        std::find_if(m_arguments.begin(), m_arguments.end(), [](const auto& v) { return v == "-h" || v == "--help"; });
    if (help_it != m_arguments.end()) {
        m_help_requested = true;
        m_arguments.erase(help_it);
        return true;
    }
    for (auto& [name, opt] : m_options) {
        auto it = std::find(m_arguments.begin(), m_arguments.end(), name);
        if (it != m_arguments.end()) {
            if (opt.found) {
                std::cout << "Argument parsing error: option " << std::quoted(name) << " was specified twice\n";
                return false;
            }
            opt.found = true;
            it = m_arguments.erase(it);
            if (opt.requires_value()) {
                if (it == m_arguments.end()) {
                    std::cout << "Argument parsing error: option " << std::quoted(name) << " requires an argument "
                              << std::quoted(opt.value_name) << " but it wasn't given any\n";
                    return false;
                }
                if (opt.type == option::Type::String) {
                    if (!opt.assign(*it)) {
                        std::cout
                            << "Internal argument parser error, report this to the developer along with the command "
                               "line you were using!\n";
                        return false;
                    }
                } else if (opt.type == option::Type::Int) {
                    int value = std::get<int_ref>(opt.value);
                    const auto& strval = *it;
                    auto ec = std::from_chars(strval.data(), strval.data() + strval.size(), value);
                    if (ec.ec != std::errc{}) {
                        std::cout << "Argument parsing error: option " << std::quoted(name)
                                  << " was expecting a number but received " << strval;
                    }
                    if (!opt.assign(value)) {
                        std::cout
                            << "Internal argument parser error, report this to the developer along with the command "
                               "line you were using!\n";
                        return false;
                    }
                }
                m_arguments.erase(it);
            } else if (opt.type == option::Type::Bool) {
                if (!opt.assign(true)) {
                    std::cout << "Internal argument parser error, report this to the developer along with the command "
                                 "line you were using!\n";
                    return false;
                }
            }
        }
    }
    m_unmatched_arguments.reserve(m_arguments.size());
    m_unmatched_arguments.insert(m_unmatched_arguments.end(), m_arguments.begin(), m_arguments.end());
    if (m_unmatched_arguments.size() > m_leftover_args_needed) {
        std::cout << "Argument parsing error: Unrecognized options found: ";
        for (const auto& unm : m_unmatched_arguments) {
            std::cout << std::quoted(unm) << ", ";
        }
        std::cout << '\n';
        return false;
    }
    return true;
}

bool argparser::help_requested() const {
    return m_help_requested;
}

argparser& argparser::add_option(std::string_view opt_name, std::string_view value_name, std::string_view description,
                                 std::string& value_ref) {
    m_options.push_back(opt_t{opt_name, option{description, value_name, string_ref{value_ref}}});
    return *this;
}

argparser& argparser::add_option(std::string_view opt_name, std::string_view description, bool& value_ref) {
    m_options.push_back(opt_t{opt_name, option{description, std::string_view{}, bool_ref{value_ref}}});
    return *this;
}

argparser& argparser::add_option(std::string_view opt_name, std::string_view description, no_value_tag) {
    m_options.push_back(opt_t{opt_name, option{description, std::string_view{}, no_value_tag{}}});
    return *this;
}

argparser& argparser::add_option(std::string_view opt_name, std::string_view value_name, std::string_view description,
                                 int& value_ref) {
    m_options.push_back(opt_t{opt_name, option{description, value_name, int_ref{value_ref}}});
    return *this;
}

void argparser::print_help() const {
    std::ostringstream builder{};
    builder << m_program_name << ", Version: " << (int)m_version_edition << "." << (int)m_version_partial << '\n';
    if (m_usage_string.empty()) {
        builder << "Usage: " << m_program_name << " <options> ";
        if (m_leftover_args_needed > 0) {
            builder << " [required " << m_leftover_args_needed << " arguments]";
        };
        builder << '\n';
    } else {
        builder << m_usage_string << '\n';
    }
    builder << "Options:\n";
    std::vector<std::string> name_value_list{};
    name_value_list.reserve(m_options.size());

    for (const auto& [name, opt] : m_options) {
        if (!opt.value_name.empty()) {
            name_value_list.push_back(std::string{name} + " <" + std::string{opt.value_name} + ">");
        } else {
            name_value_list.emplace_back(name);
        }
    }
    size_t needed_width =
        std::max_element(name_value_list.begin(), name_value_list.end(),
                         [](const std::string& lhs, const std::string& rhs) { return lhs.size() < rhs.size(); })
            ->size() +
        2;
    size_t idx = 0;
    for (const auto& [name, opt] : m_options) {
        builder << '\t';
        auto f{builder.flags()};
        builder << std::setw(needed_width) << std::left;
        builder << name_value_list[idx++];
        builder.flags(f);
        builder << opt.description;
        if (opt.has_default()) {
            if (opt.type == option::Type::String) {
                const auto& str = std::get<string_ref>(opt.value).get();
                builder << " (Default value: " << std::quoted(str.empty() ? std::string{"<empty>"} : str) << ")";
            } else if (opt.type == option::Type::Bool) {
                const auto& boolv = std::get<bool_ref>(opt.value).get();
                builder << std::boolalpha << " (Default value: " << boolv << ")";
            } else if (opt.type == option::Type::Int) {
                const auto& intv = std::get<int_ref>(opt.value).get();
                builder << "(Default value: " << intv << ")";
            }
        }
        builder << '\n';
    }
    std::cout << builder.str();
}

bool argparser::option::requires_value() const {
    return type == Type::Int || type == Type::String;
}

bool argparser::option::assign(std::string_view arg_value) {
    if (type == Type::String) {
        std::get<string_ref>(value).get() = arg_value;
    } else {
        return false;
    }
    return true;
}

bool argparser::option::assign(bool arg_value) {
    if (type == Type::Bool) {
        std::get<bool_ref>(value).get() = arg_value;
    } else {
        return false;
    }
    return true;
}

bool argparser::option::assign(int arg_value) {
    if (type == Type::Int) {
        std::get<int_ref>(value).get() = arg_value;
    } else {
        return false;
    }
    return true;
}

bool argparser::option::has_default() const {
    if (type != Type::NoValue)
        return true;
    return false;
}
