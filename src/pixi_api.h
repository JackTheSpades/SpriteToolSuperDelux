#pragma once

#ifndef PIXI_EXE_BUILD
#ifndef _WIN32
#define pixifunc extern "C"
#else
#define pixifunc extern "C" __declspec(dllimport)
#endif
#else
#define pixifunc
#endif
pixifunc int pixi_run(int, char **, const char*, const char*);
