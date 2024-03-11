#include "../structs.h"
#include <string>

class MeiMei {
  private:
    std::string name;
    ROM prev;
    unsigned char prevEx[0x400];
    unsigned char nowEx[0x400];
    bool always;
    bool debug;
    bool keepTemp;
    std::string sa1DefPath;

    bool patch(const patchfile& patch, const std::vector<patchfile>& patchfiles, ROM& rom);
    int run(ROM &rom);

  public:
    [[nodiscard]] bool initialize(const char *n);
    int run();
    bool& Debug();
    bool& AlwaysRemap();
    bool& KeepTemp();
    void configureSa1Def(const std::string& pathToSa1Def);
};