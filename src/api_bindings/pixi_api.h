#pragma once

#ifndef PIXI_EXE_BUILD
#ifndef _WIN32
#define PIXI_IMPORT extern "C"
#else
#define PIXI_IMPORT extern "C" __declspec(dllimport)
#endif
#else
#define PIXI_IMPORT
#endif

/// <summary>
/// Runs the complete pixi program.
/// Parses the lists and applies the sprite to a rom
/// The first 2 parameters expect exactly the same as a main() function.
/// </summary>
/// <param name="argc">Number of arguments</param>
/// <param name="argv">Arguments</param>
/// <param name="stdin">Name of file to use as stdin, pass NULL to get input directly from console</param>
/// <param name="stdout">Name of file to use as stdout, pass NULL to output directly to console</param>
/// <returns>Exit code of the program</returns>
PIXI_IMPORT int pixi_run(int argc, char ** argv, const char * stdin, const char *stdout);

/// <summary>
/// Returns the API version as 100*edition + 10*major + minor
/// For example: 1.32 would return as 132
/// </summary>
/// <returns>API version as 100*edition + 10*major + minor</returns>
PIXI_IMPORT int pixi_api_version();

/// <summary>
/// Checks equality between the expected (passed in) API version values and the current ones.
/// </summary>
/// <param name="version_edition">Edition (e.g. for Pixi 1.32, it would be 1)</param>
/// <param name="version_major">Major revision (e.g. for Pixi 1.32 it would be 3)</param>
/// <param name="version_minor">Minor revision (e.g. for Pixi 1.32 it would be 2)</param>
/// <returns>1 on equality, 0 otherwise</returns>
PIXI_IMPORT int pixi_check_api_version(int version_edition, int version_major, int version_minor);
