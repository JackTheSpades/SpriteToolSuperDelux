@rem -----------------------------------
@rem --- compile option
@set CFLAGS=-g -O0
@rem -----------------------------------

@rem compile
g++.exe %CFLAGS% -static -static-libgcc -static-libstdc++ -o "pixi.exe" -Wall --std=c++11 -Wno-format src/*.cpp src/asar/asardll.c
@pause
