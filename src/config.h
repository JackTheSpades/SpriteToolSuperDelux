#pragma once
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

struct Debug {
    FILE* output = nullptr;

    template <typename... Args> inline void dprintf(const char* format, Args... args) {
        if (this->output)
            fprintf(this->output, format, args...);
    }

    ~Debug() {
        if (this->output)
            fclose(this->output);
    }
};

class Paths {
    static constexpr size_t ArrSize = FromEnum(PathType::__SIZE__);
    std::string list{"list.txt"};
    std::string pasm{"asm/"};
    std::string sprites{"sprites/"};
    std::string shooters{"shooters/"};
    std::string generators{"generators/"};
    std::string extended{"extended/"};
    std::string cluster{"cluster/"};
    std::string minorextended{"misc_sprites/minorextended/"};
    std::string bounce{"misc_sprites/bounce/"};
    std::string smoke{"misc_sprites/smoke/"};
    std::string spinningcoin{"misc_sprites/spinningcoin/"};
    std::string score{"misc_sprites/score/"};
    std::string routines{"routines/"};

    std::array<std::reference_wrapper<std::string>, ArrSize> paths{
        routines, sprites,       generators, shooters, list,         pasm, extended,
        cluster,  minorextended, bounce,     smoke,    spinningcoin, score};

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

    std::array<std::reference_wrapper<std::string>, ArrSize> exts{ssc, mwt, mw2, s16};

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

    Debug m_Debug{};
    Paths m_Paths{};
    Extensions m_Extensions{};

  public:
    PixiConfig() = default;
    Debug& debug() {
        return m_Debug;
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
};