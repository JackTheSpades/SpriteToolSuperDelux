cmake_minimum_required(VERSION 3.18)
set(PIXI_SOURCE_FILES "")
include(FetchContent)

set(PIXI_LINK_LIBRARIES "")
set(PIXI_LINK_OPTIONS "")
set(PIXI_COMPILE_OPTIONS "")
set(PIXI_COMPILE_DEFINITIONS "")

FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json
    GIT_TAG v3.10.5
)

FetchContent_MakeAvailable(json)

list(
    APPEND PIXI_LINK_LIBRARIES
    "nlohmann_json::nlohmann_json"
)

list(
    APPEND PIXI_SOURCE_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/pixi.rc"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/argparser.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/cfg.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/file_io.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/map16.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/paths.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/structs.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/MeiMei/MeiMei.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/asar/asardll.h" 
    "${CMAKE_CURRENT_SOURCE_DIR}/json/base64.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json_const.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/config.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/argparser.h"

    "${CMAKE_CURRENT_SOURCE_DIR}/pixi_information_impl.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/api_bindings/pixi_api.h"
)
add_executable(pixi "${CMAKE_CURRENT_SOURCE_DIR}/main.cpp" ${PIXI_SOURCE_FILES})

if (PIXI_LIBRARY_TYPE STREQUAL "STATIC")
    list(APPEND PIXI_COMPILE_DEFINITIONS
    "PIXI_STATIC_LIB"
    )
else()
    set(PIXI_LIBRARY_TYPE "SHARED")
endif()

add_library(pixi_api ${PIXI_LIBRARY_TYPE} ${PIXI_SOURCE_FILES})
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if (WIN32)
        message(STATUS "Windows build (on Clang/MINGW)")
        list(APPEND PIXI_LINK_OPTIONS -static -static-libgcc -static-libstdc++)
        list(APPEND PIXI_COMPILE_OPTIONS -Wno-deprecated-declarations)
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")  # if debug mode, don't add -s and --gc-sections
            message(STATUS "Building debug mode")
        else()
            message(STATUS "Building release mode")
            list(APPEND PIXI_LINK_OPTIONS -s -Wl,--gc-sections)
        endif()
    elseif(APPLE)
        message(STATUS "MacOS build")
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            message(STATUS "Building debug mode")
        else()
            message(STATUS "Building release mode")
        endif()
        list(APPEND PIXI_COMPILE_OPTIONS -Wall -Wextra -Wpedantic)
        list(APPEND PIXI_LINK_LIBRARIES dl)
    else()
        message(STATUS "Unix build")
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            message(STATUS "Building debug mode")
        else()
            message(STATUS "Building release mode")
            list(APPEND PIXI_LINK_OPTIONS -s -Wl,--gc-sections)
        endif()
        list(APPEND PIXI_COMPILE_OPTIONS -Wall -Wextra -Wpedantic)
        list(APPEND PIXI_LINK_LIBRARIES dl)
    endif() 
    message(STATUS "GCC/Clang detected, adding compile flags")
else()
    message(STATUS "MSVC detected, adding compile flags")
    list(APPEND PIXI_COMPILE_DEFINITIONS _CRT_SECURE_NO_WARNINGS)
    if (PIXI_LIBRARY_TYPE STREQUAL "SHARED")
        set(PIXI_MSVC_LIB_TYPE "/MD$<$<CONFIG:Debug>:d>")
    else()
        set(PIXI_MSVC_LIB_TYPE "/MT$<$<CONFIG:Debug>:d>")
    endif()
    list(APPEND PIXI_COMPILE_OPTIONS /Wall /std:c++20 ${PIXI_MSVC_LIB_TYPE})
    list(APPEND PIXI_COMPILE_OPTIONS
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
            # but I still dont't want them clogging my output

            # from nlhomann's json.hpp
            /wd4061 # enumerator 'identifier' in switch of enum 'enumeration' is not explicitly handled by a case label
            /wd4623 # default constructor was implicitely defined as deleted
            /wd4625 # copy constructor was implicitely defined as deleted
            /wd4626 # assignment operator was implicitely defined as deleted
            /wd5027 # move assignment operator was implicitely defined as deleted
            /wd26819 # unannotated fallthrought between switch labels
            /wd28020 # The expression <expr> is not true at this call
            /wd26495 # Variable <var> is uninitialized. Always initialize a member variable

            # from asardll.c
            /wd5039 # throwing stuff passed to extern "C"
            /wd4090 # function different 'const' qualifiers (stuff from asardll.c)

            # from stdlib's limits.h for some reason (why does stuff from the stdlib have warnings)
            /wd4668
	)
endif()

target_link_libraries(pixi PRIVATE ${PIXI_LINK_LIBRARIES})
target_link_options(pixi PRIVATE ${PIXI_LINK_OPTIONS})
target_compile_options(pixi PRIVATE ${PIXI_COMPILE_OPTIONS})
target_compile_definitions(pixi PRIVATE ${PIXI_COMPILE_DEFINITIONS} PIXI_EXE_BUILD)

target_link_libraries(pixi_api PRIVATE ${PIXI_LINK_LIBRARIES})
target_link_options(pixi_api PRIVATE ${PIXI_LINK_OPTIONS})
target_compile_options(pixi_api PRIVATE ${PIXI_COMPILE_OPTIONS})
target_compile_definitions(pixi_api PRIVATE ${PIXI_COMPILE_DEFINITIONS})

set(asar_shared_lib "${CMAKE_SHARED_LIBRARY_PREFIX}asar${CMAKE_SHARED_LIBRARY_SUFFIX}")

if (WIN32)
    if (NOT EXISTS "$<TARGET_FILE_DIR:pixi>/${asar_shared_lib}")
        message(STATUS "Downloading asar shared library")
        download_dll("https://github.com/RPGHacker/asar/releases/download/v1.81/asar181.zip" "asar181")
    endif()
else()
    if (NOT EXISTS "$<TARGET_FILE_DIR:pixi>/${asar_shared_lib}")
        message(STATUS "Downloading asar shared library")
        build_dll("https://github.com/RPGHacker/asar/archive/refs/tags/v1.81.tar.gz" "asar181")
    endif()
endif()

add_custom_command(TARGET pixi POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    ${asar181_LIB_PATH} $<TARGET_FILE_DIR:pixi>
    COMMENT "Copying ${asar181_LIB_PATH} to output directory"
)
