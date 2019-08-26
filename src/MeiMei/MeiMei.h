#include "../structs.h"
#include "Rom.h"
#include <string>

class MeiMei
{
	private:
		static string name;
		static Rom* prev;
		static uchar prevEx[0x400];
		static uchar nowEx[0x400];
        static bool always;
        static bool debug;
        static bool keepTemp;
        static string sa1DefPath;

        static bool patch(const char *patch_name, ROM& rom);
        static int run(ROM& rom);

    public:
        static void initialize(const char* n);
        static int run();
        static void setDebug();
        static void setAlwaysRemap();
        static void setKeepTemp();
        static void configureSa1Def(string pathToSa1Def);
};