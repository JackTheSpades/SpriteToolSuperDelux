#pragma once
#include "libconsole/libconsole.h"
#include <algorithm>
#include <array>
#include <cstdio>
#include <string>

constexpr int DEFAULT_ROUTINES = 100;
#define MAX_ROUTINES 310

constexpr size_t operator""_sz(unsigned long long n) {
    return n;
}

enum class PathType : size_t {
    Routines,
    Sprites,
    Generators,
    Shooters,
    List,
    Asm,
    Extended,
    Cluster,
    MinorExtended,
    Bounce,
    Smoke,
    SpinningCoin,
    Score,
    // Overworld,
    __SIZE__ // this is here as a shorthand for counting how many elements are in the enum
};

enum class ExtType : size_t { Ssc, Mwt, Mw2, S16, __SIZE__ };

enum class ListType : int { Sprite, Extended, Cluster, MinorExtended, Bounce, Smoke, SpinningCoin, Score, __SIZE__ };

template <typename T> constexpr auto FromEnum(T val) {
    return static_cast<std::underlying_type_t<T>>(val);
}
template <typename T> constexpr auto ToEnum(std::underlying_type_t<T> val) {
    return static_cast<T>(val);
}

using strref = std::reference_wrapper<std::string>;

using namespace std::string_view_literals;
struct DefaultPaths {

    static constexpr size_t ArrSize = FromEnum(PathType::__SIZE__);
    constexpr static auto list = "list.txt"sv;
    constexpr static auto pasm = "asm/"sv;
    constexpr static auto sprites = "sprites/"sv;
    constexpr static auto shooters = "shooters/"sv;
    constexpr static auto generators = "generators/"sv;
    constexpr static auto extended = "extended/"sv;
    constexpr static auto cluster = "cluster/"sv;
    constexpr static auto minorextended = "misc_sprites/minorextended/"sv;
    constexpr static auto bounce = "misc_sprites/bounce/"sv;
    constexpr static auto smoke = "misc_sprites/smoke/"sv;
    constexpr static auto spinningcoin = "misc_sprites/spinningcoin/"sv;
    constexpr static auto score = "misc_sprites/score/"sv;
    constexpr static auto routines = "routines/"sv;

    constexpr static std::array<std::string_view, ArrSize> paths{
        routines, sprites,       generators, shooters, list,         pasm, extended,
        cluster,  minorextended, bounce,     smoke,    spinningcoin, score};

    constexpr static auto get(PathType index) {
        return paths[FromEnum(index)];
    }
};

class Paths {
    std::string list{DefaultPaths::list};
    std::string pasm{DefaultPaths::pasm};
    std::string sprites{DefaultPaths::sprites};
    std::string shooters{DefaultPaths::shooters};
    std::string generators{DefaultPaths::generators};
    std::string extended{DefaultPaths::extended};
    std::string cluster{DefaultPaths::cluster};
    std::string minorextended{DefaultPaths::minorextended};
    std::string bounce{DefaultPaths::bounce};
    std::string smoke{DefaultPaths::smoke};
    std::string spinningcoin{DefaultPaths::spinningcoin};
    std::string score{DefaultPaths::score};
    std::string routines{DefaultPaths::routines};

    std::array<strref, DefaultPaths::ArrSize> paths{
        strref{routines}, strref{sprites},      strref{generators}, strref{shooters},      strref{list},
        strref{pasm},     strref{extended},     strref{cluster},    strref{minorextended}, strref{bounce},
        strref{smoke},    strref{spinningcoin}, strref{score}};

  public:
    inline constexpr std::string& operator[](PathType index) noexcept {
        auto sindex = std::clamp(FromEnum(index), 0_sz, paths.size() - 1_sz);
        return paths[sindex];
    };

    inline constexpr const std::string& operator[](PathType index) const noexcept {
        auto sindex = std::clamp(FromEnum(index), 0_sz, paths.size() - 1_sz);
        return paths[sindex];
    };
};

class Extensions {
    static constexpr size_t ArrSize = FromEnum(ExtType::__SIZE__);
    std::string ssc{};
    std::string mwt{};
    std::string mw2{};
    std::string s16{};

    std::array<strref, ArrSize> exts{strref{ssc}, strref{mwt}, strref{mw2}, strref{s16}};

  public:
    inline constexpr std::string& operator[](ExtType index) noexcept {
        auto sindex = std::clamp(FromEnum(index), 0_sz, exts.size() - 1_sz);
        return exts[sindex];
    };

    inline constexpr const std::string& operator[](ExtType index) const noexcept {
        auto sindex = std::clamp(FromEnum(index), 0_sz, exts.size() - 1_sz);
        return exts[sindex];
    };
};

class PixiConfig {

    Paths m_Paths{};
    Extensions m_Extensions{};

  public:
    PixiConfig() = default;
    void reset() {
        DebugEnabled = false;
        KeepFiles = false;
        PerLevel = false;
        Disable255Sprites = false;
        Warnings = false;
        ExtModDisabled = false;
        DisableMeiMei = false;
        DisableAllExtensionFiles = false;
        Routines = DEFAULT_ROUTINES;
        AsmDir = "";
        AsmDirPath = "";
        SymbolsType = "";
        for (size_t i = 0; i < FromEnum(PathType::__SIZE__); i++) {
            m_Paths[static_cast<PathType>(i)] = DefaultPaths::get(static_cast<PathType>(i));
        }
        for (size_t i = 0; i < FromEnum(ExtType::__SIZE__); i++) {
            m_Extensions[static_cast<ExtType>(i)] = "";
        }
    }
    std::string& operator[](PathType pt) {
        return m_Paths[pt];
    }
    const std::string& operator[](PathType pt) const {
        return m_Paths[pt];
    }
    std::string& operator[](ExtType pt) {
        return m_Extensions[pt];
    }
    const std::string& operator[](ExtType pt) const {
        return m_Extensions[pt];
    }
    const auto& GetPaths() const {
        return m_Paths;
    }
    bool DebugEnabled = false;
    bool KeepFiles = false;
    bool PerLevel = false;
    bool Disable255Sprites = false;
    bool Warnings = false;
    bool ExtModDisabled = false;
    bool DisableMeiMei = false;
    bool DisableAllExtensionFiles = false;
    int Routines = DEFAULT_ROUTINES;
    std::string AsmDir{};
    std::string AsmDirPath{};
    std::string SymbolsType{};
};