#pragma once
#include <algorithm>
#include <array>
#include <cstdio>
#include <string>

constexpr size_t operator""_sz(unsigned long long n) {
    return n;
}

enum class PathType : int {
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

enum class ExtType : int { Ssc, Mwt, Mw2, S16, __SIZE__ };

enum class ListType : int { Sprite, Extended, Cluster, MinorExtended, Bounce, Smoke, SpinningCoin, Score, __SIZE__ };

template <typename T> constexpr auto FromEnum(T val) {
    return static_cast<std::underlying_type_t<T>>(val);
}

struct Debug {
    FILE *output = nullptr;

    template <typename... Args> inline void dprintf(const char *format, Args... args) {
        if (this->output)
            fprintf(this->output, format, args...);
    }

    ~Debug() {
        if (this->output)
            fclose(this->output);
    }
};

struct Paths {
    static constexpr int ArrSize = FromEnum(PathType::__SIZE__);
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

    inline constexpr std::string &operator[](size_t index) noexcept {
        std::array<std::string *, ArrSize> paths{&routines, &sprites,      &generators, &shooters,      &list,
                                                 &pasm,     &extended,     &cluster,    &minorextended, &bounce,
                                                 &smoke,    &spinningcoin, &score};
        index = std::clamp(index, 0_sz, paths.size() - 1_sz);
        return *paths[index];
    };

    inline constexpr const std::string &operator[](size_t index) const noexcept {
        std::array<const std::string *, ArrSize> paths{&routines, &sprites,      &generators, &shooters,      &list,
                                                       &pasm,     &extended,     &cluster,    &minorextended, &bounce,
                                                       &smoke,    &spinningcoin, &score};
        index = std::clamp(index, 0_sz, paths.size() - 1_sz);
        return *paths[index];
    };
};

struct Extensions {
    static constexpr int ArrSize = FromEnum(ExtType::__SIZE__);
    std::string ssc{};
    std::string mwt{};
    std::string mw2{};
    std::string s16{};

    inline constexpr std::string &operator[](size_t index) noexcept {
        std::array<std::string *, ArrSize> exts{&ssc, &mwt, &mw2, &s16};
        index = std::clamp(index, 0_sz, exts.size() - 1_sz);
        return *exts[index];
    };

    inline constexpr const std::string &operator[](size_t index) const noexcept {
        std::array<const std::string *, ArrSize> exts{&ssc, &mwt, &mw2, &s16};
        index = std::clamp(index, 0_sz, exts.size() - 1_sz);
        return *exts[index];
    };
};

struct PixiConfig {

    PixiConfig() = default;

    Debug m_Debug{};
    Paths m_Paths{};
    Extensions m_Extensions{};
    bool KeepFiles = false;
    bool PerLevel = false;
    bool disable255Sprites = false;
    bool Warnings = false;
    bool ExtMod = true;
    bool DisableMeiMei = false;
    bool DisableAllExtensionFiles = false;
    int Routines = 100;
    std::string AsmDir{};
    std::string AsmDirPath{};

    ~PixiConfig() {
        this->m_Debug.~Debug();
    }
};