@rem -----------------------------------
@rem --- compile option
@set CFLAGS=-Og -g -ffunction-sections -fdata-sections -Wl,--gc-sections
@rem -----------------------------------

@rem compile
g++.exe %CFLAGS% -m32 -static -static-libgcc -static-libstdc++ -o "pixi.exe" src/icon.res -Wall --std=c++17 -Wno-format src/*.cpp src/MeiMei/*.cpp src/asar/asardll.c src/json/base64.cpp -DDEBUGMSG
@pause
