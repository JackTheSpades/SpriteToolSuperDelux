#pragma once
#include "nlohmann/json.hpp"
#include <algorithm>
#include <concepts>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

struct no_value_tag {};

using string_ref = std::reference_wrapper<std::string>;
using bool_ref = std::reference_wrapper<bool>;
using int_ref = std::reference_wrapper<int>;
using uint_ref = std::reference_wrapper<unsigned int>;
using real_ref = std::reference_wrapper<double>;


#if defined(__clang__) && __clang_major__ < 14 // vvvv clang 13 workaround
template <typename T>
concept signed_integral = std::is_integral_v<T> && std::is_signed_v<T>;
template <typename T>
concept unsigned_integral = std::is_integral_v<T> && std::is_unsigned_v<T>;
template <typename T>
concept floating_point = std::is_floating_point_v<T>;
#else // ^^^^ clang 13 workaround -- vvvv everything else
template <typename T>
concept signed_integral = std::signed_integral<T>;
template <typename T>
concept unsigned_integral = std::unsigned_integral<T>;
template <typename T>
concept floating_point = std::floating_point<T>;
#endif // ^^^^ everything else

template <typename T>
concept option_type = std::same_as<T, int_ref> || std::same_as<T, uint_ref> || std::same_as<T, real_ref> ||
                      std::same_as<T, string_ref> || std::same_as<T, no_value_tag> || std::same_as<T, bool_ref>;

class argparser {
    std::vector<std::string> m_unmatched_arguments;
    std::string m_program_name;
    std::vector<std::string> m_arguments{};

    using arg_iter_t = decltype(m_arguments)::iterator;
    struct option {
        enum class Type { String, Bool, Int, Uint, Real, NoValue } type;
        std::string_view description;
        std::string_view value_name;

        std::variant<no_value_tag, bool_ref, string_ref, int_ref, uint_ref, real_ref> value;
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
            } else if constexpr (std::same_as<T, uint_ref>) {
                return Type::Uint;
            } else if constexpr (std::same_as<T, real_ref>) {
                return Type::Real;
            } else if constexpr (std::same_as<T, no_value_tag>) {
                return Type::NoValue;
            }
        }
        option() : type{Type::NoValue}, description{}, value_name{}, value(no_value_tag{}), found{false} {}
        option(std::string_view desc, std::string_view name, option_type auto&& val)
            : type{map_t_to_type(val)}, description{desc}, value_name{name}, found{false} {
            value = std::move(val);
        }
        bool requires_value() const;
        bool assign(std::string_view arg_value);
        bool assign(bool arg_value);
        bool assign(signed_integral auto arg_value) {
            if (type == Type::Int) {
                std::get<int_ref>(value).get() = static_cast<int>(arg_value);
            } else {
                return false;
            }
            return true;
        }
        bool assign(unsigned_integral auto arg_value) {
            if (type == Type::Uint) {
                std::get<uint_ref>(value).get() = static_cast<unsigned int>(arg_value);
            } else {
                return false;
            }
            return true;
        }
        bool assign(floating_point auto arg_value) {
            if (type == Type::Real) {
                std::get<real_ref>(value).get() = static_cast<double>(arg_value);
            } else {
                return false;
            }
            return true;
        }
        bool has_default() const;
    };

    using opt_t = std::pair<std::string_view, option>;
    using opt_iter_v = std::tuple<std::string_view, option::Type, std::string_view, std::string_view,
                                  std::variant<no_value_tag, bool_ref, string_ref, int_ref, uint_ref, real_ref>, bool>;

    struct opt_iter {
        const std::vector<opt_t>& m_options;
        size_t m_index;
        opt_iter(const std::vector<opt_t>& options, size_t index = 0) : m_options{options}, m_index{index} {
        }
        opt_iter_v operator*() const {
            const auto& opt = m_options[m_index];
            return std::make_tuple(opt.first, opt.second.type, opt.second.description, opt.second.value_name,
                                   opt.second.value, opt.second.found);
        }
        opt_iter& operator++() {
            ++m_index;
            return *this;
        }
        bool operator!=(const opt_iter& other) const {
            return m_index != other.m_index;
        }
    };

    struct opt_iterator {
        const std::vector<opt_t>& m_options;
        opt_iterator(const std::vector<opt_t>& options) : m_options{options} {
        }
        opt_iter begin() const {
            return opt_iter{m_options, 0};
        }
        opt_iter end() const {
            return opt_iter{m_options, m_options.size()};
        }
    };

    std::vector<opt_t> m_options{};
    bool m_help_requested = false;
    uint8_t m_version_partial = 0;
    uint8_t m_version_edition = 0;
    size_t m_leftover_args_needed = 0;
    std::string_view m_usage_string{};

    template <typename T> static constexpr bool inline dependant_false = false;

  public:
    static constexpr inline auto no_value = no_value_tag{};
    argparser() = default;
    bool init(const nlohmann::json& args);
    bool init(int argc, const char** argv);
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
    argparser& add_option(std::string_view opt_name, std::string_view value_name, std::string_view description,
                          unsigned int& value_ref);
    argparser& add_option(std::string_view opt_name, std::string_view value_name, std::string_view description,
                          double& value_ref);
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
        } else if constexpr (std::same_as<Tp, unsigned int>) {
            if (value.type == option::Type::Uint) {
                return std::get<uint_ref>(value.value).get();
            } else {
                throw std::invalid_argument("Requested type `unsigned int` for option containing bool, string or none");
            }
        } else if constexpr (std::same_as<Tp, double>) {
            if (value.type == option::Type::Real) {
                return std::get<real_ref>(value.value).get();
            } else {
                throw std::invalid_argument("Requested type `double` for option containing bool, string or none");
            }
        } else {
            static_assert(dependant_false<T>, "Invalid get() call");
        }
    }

    opt_iterator iter() const {
        return opt_iterator{m_options};
    }
};