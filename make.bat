@rem -----------------------------------
@rem --- compile option
@set CFLAGS=-O2 -s -Wl,--gc-sections
@rem -----------------------------------

@rem compile
g++.exe %CFLAGS% -m32 -static -static-libgcc -static-libstdc++ -o "pixi.exe" src/icon.res -Wall -Wpedantic -Wextra -std=c++17 src/*.cpp src/MeiMei/*.cpp src/asar/asardll.c src/json/base64.cpp
@pause
