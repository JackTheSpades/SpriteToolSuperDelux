#include "../structs.h"
#include <string>

class MeiMei {
  private:
    static inline std::string name;
    static inline ROM prev;
    static inline unsigned char prevEx[0x400];
    static inline unsigned char nowEx[0x400];
    static inline bool always;
    static inline bool debug;
    static inline bool keepTemp;
    static inline std::string sa1DefPath;

    static bool patch(const char *patch_name, ROM &rom);
    static int run(ROM &rom);

  public:
    static void initialize(const char *n);
    static int run();
    static void setDebug();
    static void setAlwaysRemap();
    static void setKeepTemp();
    static void configureSa1Def(std::string pathToSa1Def);
};