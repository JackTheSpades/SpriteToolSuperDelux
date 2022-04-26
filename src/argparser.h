#pragma once
#include <algorithm>
#include <stdexcept>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>


struct no_value_tag {};

using string_ref = std::reference_wrapper<std::string>;
using bool_ref = std::reference_wrapper<bool>;
using int_ref = std::reference_wrapper<int>;

template <typename T>
concept option_type = std::same_as<T, int_ref> || std::same_as<T, string_ref> || std::same_as<T, no_value_tag> ||
    std::same_as<T, bool_ref>;

class argparser {
    std::vector<std::string> m_unmatched_arguments;
    std::string m_program_name;
    std::vector<std::string_view> m_arguments{};

    using arg_iter_t = decltype(m_arguments)::iterator;
    struct option {
        enum class Type { String, Bool, Int, NoValue } type;
        std::string_view description;
        std::string_view value_name;

        std::variant<no_value_tag, bool_ref, string_ref, int_ref> value;
        bool found;
        static constexpr inline size_t npos = static_cast<size_t>(-1);

        static constexpr inline Type map_t_to_type(const option_type auto& val) {
            using T = std::remove_cvref_t<decltype(val)>;
            if constexpr (std::same_as<T, string_ref>) {
                return Type::String;
            } else if constexpr (std::same_as<T, bool_ref>) {
                return Type::Bool;
            } else if constexpr (std::same_as<T, int_ref>) {
                return Type::Int;
            } else if constexpr (std::same_as<T, no_value_tag>) {
                return Type::NoValue;
            }
        }

        option(std::string_view desc, std::string_view name, option_type auto&& val)
            : type{map_t_to_type(val)}, description{desc}, value_name{name}, found{false} {
            value = std::move(val);
        }
        bool requires_value() const;
        bool assign(std::string_view arg_value);
        bool assign(bool arg_value);
        bool assign(int arg_value);
        bool has_default() const;
    };

    using opt_t = std::pair<std::string_view, option>;

    std::vector<opt_t> m_options{};
    bool m_help_requested = false;
    uint8_t m_version_partial = 0;
    uint8_t m_version_edition = 0;
    size_t m_leftover_args_needed = 0;
    std::string_view m_usage_string{};

    template <typename T> static constexpr bool inline dependant_false = false;

  public:
    static constexpr inline auto no_value = no_value_tag{};

    argparser(int argc, char** argv);
    void add_version(uint8_t version_partial, uint8_t version_edition);
    void allow_unmatched(size_t quantity = option::npos);
    const std::vector<std::string>& unmatched() const {
        return m_unmatched_arguments;
    }
    void add_usage_string(std::string_view usage_string);
    bool parse();
    bool help_requested() const;
    argparser& add_option(std::string_view opt_name, std::string_view value_name, std::string_view description,
                          std::string& value_ref);
    argparser& add_option(std::string_view opt_name, std::string_view value_name, std::string_view description,
                          int& value_ref);
    argparser& add_option(std::string_view opt_name, std::string_view description, bool& value_ref);
    argparser& add_option(std::string_view opt_name, std::string_view description, no_value_tag);
    void print_help() const;

    bool is_present(std::string_view opt_name) {
        auto it =
            std::find_if(m_options.begin(), m_options.end(), [&](const auto& kvp) { return kvp.first == opt_name; });
        if (it == m_options.end())
            throw std::out_of_range{"Invalid option"};
        const auto& [_, value] = *it;
        return value.found;
    }

    template <typename T>
    requires option_type<std::reference_wrapper<std::remove_cvref_t<T>>>
    auto& get(std::string_view opt_name) {
        using Tp = std::remove_cvref_t<T>;
        auto it =
            std::find_if(m_options.begin(), m_options.end(), [&](const auto& kvp) { return kvp.first == opt_name; });
        if (it == m_options.end())
            throw std::out_of_range{"Invalid option"};
        auto& [_, value] = *it;
        if constexpr (std::same_as<Tp, bool>) {
            if (value.type == option::Type::Bool) {
                return std::get<bool_ref>(value.value).get();
            } else if (value.type == option::Type::NoValue) {
                return value.found;
            } else {
                throw std::invalid_argument("Requested type `bool` for option containing int or string");
            }
        } else if constexpr (std::same_as<Tp, std::string>) {
            if (value.type == option::Type::String) {
                return std::get<string_ref>(value.value).get();
            } else {
                throw std::invalid_argument("Requested type `string` for option containing int, string or none");
            }
        } else if constexpr (std::same_as<Tp, int>) {
            if (value.type == option::Type::Int) {
                return std::get<int_ref>(value.value).get();
            } else {
                throw std::invalid_argument("Requested type `int` for option containing bool, string or none");
            }
        } else {
            static_assert(dependant_false<T>, "Invalid get() call");
        }
    };
};