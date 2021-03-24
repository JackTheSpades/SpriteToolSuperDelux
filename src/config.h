#include <algorithm>
#include <array>
#include <cstdio>
#include <string>

enum class PathType : int {
    Routines,
    Sprites,
    Generators,
    Shooters,
    List,
    Asm,
    Extended,
    Cluster,
    // Overworld,
    SIZE // this is here as a shorthand for counting how many elements are in the enum
};

enum class ExtType : int { Ssc, Mwt, Mw2, S16, SIZE };

enum class ListType : int { Sprite = 0, Extended = 1, Cluster = 2, Overworld = 3 };

template <typename T> constexpr auto FromEnum(T val) {
    return static_cast<std::underlying_type_t<T>>(val);
}


struct Debug {
    bool isOn = false;
    std::string outfile{};
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
    static constexpr int ArrSize = FromEnum(PathType::SIZE);
    std::string list{"list.txt"};
    std::string pasm{"asm/"};
    std::string sprites{"sprites/"};
    std::string shooters{"shooters/"};
    std::string generators{"generators/"};
    std::string extended{"extended/"};
    std::string cluster{"cluster/"};
    std::string routines{"routines/"};

    inline constexpr std::string &operator[](int index) noexcept {
        std::array<std::string *, ArrSize> paths{&routines, &sprites, &generators, &shooters,
                                                 &list,     &pasm,    &extended,   &cluster};
        index = std::clamp(index, 0, (int)paths.size() - 1);
        return *paths[index];
    };

    inline constexpr const std::string &operator[](int index) const noexcept {
        std::array<const std::string *, ArrSize> paths{&routines, &sprites, &generators, &shooters,
                                                       &list,     &pasm,    &extended,   &cluster};
        index = std::clamp(index, 0, (int)paths.size() - 1);
        return *paths[index];
    };
};

struct Extensions {
    static constexpr int ArrSize = FromEnum(ExtType::SIZE);
    std::string ssc{};
    std::string mwt{};
    std::string mw2{};
    std::string s16{};

    inline constexpr std::string &operator[](int index) noexcept {
        std::array<std::string *, ArrSize> exts{&ssc, &mwt, &mw2, &s16};
        index = std::clamp(index, 0, (int)exts.size() - 1);
        return *exts[index];
    };

    inline constexpr const std::string &operator[](int index) const noexcept {
        std::array<const std::string *, ArrSize> exts{&ssc, &mwt, &mw2, &s16};
        index = std::clamp(index, 0, (int)exts.size() - 1);
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
    int Routines = 100;
    std::string AsmDir{};
    std::string AsmDirPath{};

    ~PixiConfig() {
        this->m_Debug.~Debug();
    }
};