cmake_minimum_required(VERSION 3.10)
project(pixi VERSION 1.32)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CURRENT_SOURCE_DIR "src")
set(PIXI_SOURCE_FILES "")
list(
    APPEND PIXI_SOURCE_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/icon.rc"
    "${CMAKE_CURRENT_SOURCE_DIR}/cfg.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/file_io.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/json.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/map16.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/paths.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/sprite.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/structs.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/MeiMei/MeiMei.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/asar/asardll.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/json/base64.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/cfg.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/file_io.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/map16.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/paths.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/structs.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/MeiMei/MeiMei.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/asar/asardll.h" 
    "${CMAKE_CURRENT_SOURCE_DIR}/json/base64.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json/json.hpp"
)
add_executable(pixi ${PIXI_SOURCE_FILES})
if (CMAKE_COMPILER_IS_GNUCXX)
    if (WIN32)
        message(STATUS "Windows build, adding static libraries")
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")  # if debug mode, don't add -s and --gc-sections
            message(STATUS "Building debug mode")
            target_link_options(pixi PRIVATE -m32 -static) 
        else()
            message(STATUS "Building release mode")
            target_link_options(pixi PRIVATE -m32 -static -s -Wl,--gc-sections)
        endif()
        target_link_libraries(pixi PRIVATE -static-libgcc -static-libstdc++)
        target_compile_options(pixi PRIVATE -m32 -Wall -Wextra -Wpedantic)
    else()
        message(STATUS "Unix build, not adding static libraries")   # on unix we don't care about -m32, for... some reason I guess
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            message(STATUS "Building debug mode")
        else()
            message(STATUS "Building release mode")
            target_link_options(pixi PRIVATE -s -Wl,--gc-sections)
        endif()
        target_link_libraries(pixi PRIVATE dl)
        target_compile_options(pixi PRIVATE -Wall -Wextra -Wpedantic)
    endif() 
    message(STATUS "GCC detected, adding compile flags")
else()
    set(CMAKE_GENERATOR "Visual Studio 16 2019")
    set(CMAKE_GENERATOR_PLATFORM Win32 CACHE INTERNAL "")
    set(CMAKE_VS_PLATFORM_NAME Win32 CACHE INTERNAL "")
    target_link_options(pixi PRIVATE /INCREMENTAL:NO /NODEFAULTLIB:MSVCRT)
    message(STATUS "MSVC detected, adding compile flags")
    target_compile_options(pixi PRIVATE /MT /Wall /std:c++17)
    target_compile_options(pixi PRIVATE
            # generic & extremely noisy warnings which do (almost) nothing useful
            # not to say that most come from code which I have no control over
			/wd4514 # unreferenced inline function removed
			/wd4710 # function not inlined
			/wd4711 # function selected for automatic inline expansion
			/wd4820 # 'bytes' bytes padding added after construct 'member_name'
			/wd4464 # relative include path contains '..'

            # specific warnings of pixi
            /wd4996 # deprecated function
            /wd6031 # return value ignored -> should probably be taken care of instead of ignored at some point
            /wd4365 # signed/unsigned mismatch -> should probably be taken care of instead of ignored at some point
            /wd5045 # spectre mitigation
            /wd4774 # format string is not a string literal

            # from here are warnings that I can't do anything about
            /wd4061 # stuff in nlohmann::json that I can't fix
            /wd28020 # same as above
            /wd26495 # same as above
            /wd5039 # throwing stuff passed to extern "C"
            /wd4090 # function different 'const' qualifiers (stuff from asardll.c)
            /wd4668 # stuff from limits.h (why does stuff from the stdlib have warnings)
	)
endif()
