@rem -----------------------------------
@rem --- compile option
@set CFLAGS=-O2 -s -ffunction-sections -fdata-sections -Wl,--gc-sections -D _WIN32
@rem -----------------------------------

@rem compile
g++.exe %CFLAGS% -m32 -static -static-libgcc -static-libstdc++ -o "pixi.exe" -Wall --std=c++11 -Wno-format src/*.cpp src/asar/asardll.c src/json/base64.cpp
@pause
