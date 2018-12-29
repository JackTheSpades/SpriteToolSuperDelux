@rem -----------------------------------
@rem --- compile option
@set CFLAGS=-g -O0
@rem -----------------------------------

@rem compile
g++.exe %CFLAGS% -m32 -static -static-libgcc -static-libstdc++ -o "pixi.exe" -Wall --std=c++11 -Wno-format src/*.cpp src/asar/asardll.c src/json/base64.cpp -DDEBUGMSG
@pause
