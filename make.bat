@rem -----------------------------------
@rem --- compile option
@set CFLAGS=-O2 -s -ffunction-sections -fdata-sections -Wl,--gc-sections
@rem -----------------------------------

@rem compile
g++.exe %CFLAGS% -static -static-libgcc -static-libstdc++ -o "pixi.exe" -Wall --std=c++11 -Wno-format src/*.cpp src/asar/asardll.c
@pause
