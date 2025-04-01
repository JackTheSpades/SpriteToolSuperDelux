cmake_minimum_required(VERSION 3.18)
set(PIXI_SOURCE_FILES "")
include(FetchContent)
include(CheckIPOSupported)

set(PIXI_LINK_LIBRARIES "")
set(PIXI_LINK_OPTIONS "")
set(PIXI_COMPILE_OPTIONS "")
set(PIXI_COMPILE_DEFINITIONS GITHUB_ISSUE_LINK="https://github.com/JackTheSpades/SpriteToolSuperDelux/issues/new")

set(PIXI_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(PIXI_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(PIXI_VERSION_PATCH ${PROJECT_VERSION_PATCH})
string(TIMESTAMP PIXI_BUILD_TIMESTAMP "%Y/%m/%d %H:%M:%S" UTC)
option(ASAR_USE_DLL "Use asar as a dll instead of statically linking it" ON)
if (ASAR_USE_DLL)
    message(STATUS "Using asar as a dynamic library")
else()
    message(STATUS "Linking asar statically")
endif()
if (MSVC)
    option(MSVC_DYNAMIC_STL "Use the static version of the MSVC STL to link" OFF)
    if (NOT MSVC_DYNAMIC_STL)
        set(PIXI_MSVC_LIB_TYPE "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        message(STATUS "Using LIB flavor of MSVC's STL")
    else()
        set(PIXI_MSVC_LIB_TYPE "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
        message(STATUS "Using DLL flavor of MSVC's STL")
    endif()
endif()

if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR PIXI_CI_BUILD)
    list(APPEND PIXI_COMPILE_DEFINITIONS PIXI_DEV_BUILD=true)
    set(PIXI_RC_VERSION "1")
    set(PIXI_RC_TIMESTAMP "${PIXI_BUILD_TIMESTAMP} DEBUG")
else()
    list(APPEND PIXI_COMPILE_DEFINITIONS PIXI_DEV_BUILD=false)
    set(PIXI_RC_VERSION "0")
    set(PIXI_RC_TIMESTAMP "${PIXI_BUILD_TIMESTAMP}")
endif()

if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.24.0")
    FetchContent_Declare(json 
        URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
else()
    FetchContent_Declare(json URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz)
endif()
FetchContent_MakeAvailable(json)

if (PIXI_BUILD_EXE OR PIXI_BUILD_DLL OR PIXI_BUILD_LIB)

    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

    if (ASAR_USE_DLL)
        set(ASAR_TARGET "asar")
        set(ASAR_GEN_DLL ON)
        set(ASAR_GEN_LIB OFF)
    else()
        set(ASAR_TARGET "asar-static")
        if (MSVC_DYNAMIC_STL)
            set(MSVC_LIB_TYPE "D")
        else()
            set(MSVC_LIB_TYPE "T")
        endif()
        set(ASAR_GEN_DLL OFF)
        set(ASAR_GEN_LIB ON)
    endif()

    set(ASAR_GEN_EXE OFF)
    set(ASAR_GEN_EXE_TEST OFF)
    set(ASAR_GEN_DLL_TEST OFF)

    if (WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Debug")
        FetchContent_Declare(
	        asar
	        GIT_REPOSITORY https://github.com/RPGHacker/asar
	        GIT_TAG 058743e0f7e55410e10373ff296ebae2667f1e36
	        SOURCE_SUBDIR src
        )
    else()
        FetchContent_Declare(
	        asar
	        GIT_REPOSITORY https://github.com/RPGHacker/asar
	        GIT_TAG 058743e0f7e55410e10373ff296ebae2667f1e36
	        SOURCE_SUBDIR src
        )
    endif()
    FetchContent_MakeAvailable(asar)

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        if (ASAR_USE_DLL)
            set_target_properties(${ASAR_TARGET} PROPERTIES COMPILE_OPTIONS "-w")
        else()
            # it is necessary to add -fPIC to compile asar statically when we're compiling with something that is not msvc.
            set_target_properties(${ASAR_TARGET} PROPERTIES COMPILE_OPTIONS "-w;-fPIC")
        endif()
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        set_target_properties(${ASAR_TARGET} PROPERTIES COMPILE_OPTIONS "/w")
    else()
        message(FATAL_ERROR "Unrecognized compiler")
    endif()
    if (NOT ASAR_USE_DLL)
        list(
            APPEND PIXI_LINK_LIBRARIES
            asar-static
        )
    endif()
endif()

list(
    APPEND PIXI_LINK_LIBRARIES
    "nlohmann_json::nlohmann_json"
)

SET(PIXI_RC_CONTENTS "1 ICON \"Pixi.ico\" 

1 VERSIONINFO 
      FILEVERSION     ${PIXI_VERSION_MAJOR}, ${PIXI_VERSION_MINOR}, ${PIXI_VERSION_PATCH}, ${PIXI_RC_VERSION} 
      PRODUCTVERSION  ${PIXI_VERSION_MAJOR}, ${PIXI_VERSION_MINOR}, ${PIXI_VERSION_PATCH}, ${PIXI_RC_VERSION} 
{
    BLOCK \"StringFileInfo\" 
    {
        BLOCK \"040904b0\" // en-US with UTF-8
        {
            VALUE \"CompanyName\", \"Pixi developers\\0\" 
            VALUE \"FileDescription\", \"SMW custom sprites inserter\\0\"
            VALUE \"FileVersion\", \"v${PIXI_VERSION_MAJOR}.${PIXI_VERSION_MINOR}${PIXI_VERSION_PATCH}.${PIXI_RC_VERSION}\\0\"
            VALUE \"InternalName\", \"pixi\\0\" 
            VALUE \"OriginalFilename\", \"pixi.exe\\0\" 
            VALUE \"ProductName\", \"Pixi\\0\" 
            VALUE \"ProductVersion\", \"v${PIXI_VERSION_MAJOR}.${PIXI_VERSION_MINOR}${PIXI_VERSION_PATCH} ${PIXI_RC_TIMESTAMP}\\0\"
        }
    }
    BLOCK \"VarFileInfo\" 
    {
        VALUE \"Translation\", 0x409, 1200 // en-US with UTF-8
    }
}"
)

file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/pixi.rc" "${PIXI_RC_CONTENTS}")

list(
    APPEND PIXI_SOURCE_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/cfg.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/file_io.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/json.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/map16.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/paths.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/sprite.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/structs.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/MeiMei/MeiMei.cpp" 
    "${CMAKE_CURRENT_SOURCE_DIR}/json/base64.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/argparser.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/lmdata.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/cfg.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/file_io.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/map16.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/paths.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/structs.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/MeiMei/MeiMei.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json/base64.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/json_const.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/config.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/argparser.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/lmdata.h"

    "${CMAKE_CURRENT_SOURCE_DIR}/iohandler.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/iohandler.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/libconsole/libconsole.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/libconsole/libconsole.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/libplugin/libplugin.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/libplugin/libplugin.cpp"
    
    "${CMAKE_CURRENT_SOURCE_DIR}/pixi_information_impl.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/pixi_api.h"

    "${CMAKE_CURRENT_SOURCE_DIR}/pixi.rc"
)

if (ASAR_USE_DLL)
    list(APPEND PIXI_SOURCE_FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/asar/asardll.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/asar/asardll.c"
    )
    list(APPEND PIXI_COMPILE_DEFINITIONS
        ASAR_USE_DLL
    )
else()
    list(APPEND PIXI_SOURCE_FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/asar/asar.h"
    )
endif()

check_ipo_supported(RESULT has_ipo OUTPUT ipo_support_error)

if (PIXI_BUILD_EXE)
    add_executable(pixi "${CMAKE_CURRENT_SOURCE_DIR}/main.cpp" ${PIXI_SOURCE_FILES})
endif()
if (PIXI_BUILD_DLL)
    add_library(pixi_api SHARED ${PIXI_SOURCE_FILES})
endif()
if (PIXI_BUILD_LIB)
    add_library(pixi_api_static STATIC ${PIXI_SOURCE_FILES})
endif()

if (has_ipo AND PIXI_BUILD_EXE)
    set_property(TARGET pixi PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
elseif (PIXI_BUILD_EXE)
    message(WARNING "IPO is not supported: ${ipo_support_error}")
endif()

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if (WIN32)
        list(APPEND PIXI_COMPILE_DEFINITIONS
            _CRT_SECURE_NO_WARNINGS 
            WIN32_LEAN_AND_MEAN
            VC_EXTRALEAN
            NOMINMAX
            ON_WINDOWS
            _UNICODE
            UNICODE
        )
        list(APPEND PIXI_LINK_OPTIONS -static -static-libgcc -static-libstdc++)
        if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_SIMULATE_ID MATCHES "MSVC")
            message(STATUS "Windows build (clang-cl)")
            list(APPEND PIXI_COMPILE_OPTIONS /EHsc -Wno-deprecated-declarations)
            if (PIXI_BUILD_EXE)
                set_property(TARGET pixi PROPERTY MSVC_RUNTIME_LIBRARY ${PIXI_MSVC_LIB_TYPE})
            endif()
            if (PIXI_BUILD_DLL)
                set_property(TARGET pixi_api PROPERTY MSVC_RUNTIME_LIBRARY ${PIXI_MSVC_LIB_TYPE})
            endif()
            if (PIXI_BUILD_LIB)
                set_property(TARGET pixi_api_static PROPERTY MSVC_RUNTIME_LIBRARY ${PIXI_MSVC_LIB_TYPE})
            endif()
        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            message(STATUS "Windows build (gcc-mingw)")
            list(APPEND PIXI_COMPILE_OPTIONS -Wno-deprecated-declarations -municode)
        else()
            message(FATAL_ERROR "Unsupported OS-compiler combination, on Windows you can use MSVC, clang-cl or gcc with mingw")
        endif()

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
	    elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
		    message(STATUS "Building release mode with debug info")
            list(APPEND PIXI_LINK_OPTIONS -Wl,--gc-sections)
        else()
            message(STATUS "Building release mode")
            list(APPEND PIXI_LINK_OPTIONS -s -Wl,--gc-sections)
        endif()
        list(APPEND PIXI_COMPILE_OPTIONS -Wall -Wextra -Wpedantic)
        list(APPEND PIXI_LINK_LIBRARIES dl)
    endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    message(STATUS "Windows build (MSVC)")
    list(APPEND PIXI_COMPILE_DEFINITIONS 
        _CRT_SECURE_NO_WARNINGS 
        UNICODE 
        _UNICODE
        WIN32_LEAN_AND_MEAN
        VC_EXTRALEAN
        NOMINMAX
        ON_WINDOWS
    )
    # manifest file only runs on msvc
    if (WIN32 AND NOT CMAKE_COMPILER_IS_GNUCXX AND PIXI_BUILD_EXE)
        add_custom_command(
            TARGET pixi
            POST_BUILD
            COMMAND mt.exe -manifest ${CMAKE_CURRENT_SOURCE_DIR}/pixi.manifest -outputresource:$<TARGET_FILE:pixi>
            COMMENT "Applying manifest file"
        )
    endif()
    if (PIXI_BUILD_EXE)
        set_property(TARGET pixi PROPERTY MSVC_RUNTIME_LIBRARY ${PIXI_MSVC_LIB_TYPE})
    endif()
    if (PIXI_BUILD_DLL)
        set_property(TARGET pixi_api PROPERTY MSVC_RUNTIME_LIBRARY ${PIXI_MSVC_LIB_TYPE})
    endif()
    if (PIXI_BUILD_LIB)
        set_property(TARGET pixi_api_static PROPERTY MSVC_RUNTIME_LIBRARY ${PIXI_MSVC_LIB_TYPE})
    endif()
    list(APPEND PIXI_COMPILE_OPTIONS /utf-8 /W4 /std:c++20 /EHsc)
    list(APPEND PIXI_COMPILE_OPTIONS
        /wd4090 # function different 'const' qualifiers (from asardll.c)
	)
else()
    message(FATAL_ERROR "Unsupported compiler")
endif()

list(APPEND PIXI_COMPILE_DEFINITIONS
    PIXI_VERSION_MAJOR=${PIXI_VERSION_MAJOR}
    PIXI_VERSION_MINOR=${PIXI_VERSION_MINOR}
    PIXI_VERSION_PATCH=${PIXI_VERSION_PATCH}
    PIXI_VERSION_DEBUG="${PIXI_BUILD_TIMESTAMP}"
)

list(APPEND PIXI_COMPILE_OPTIONS
    ${PIXI_SANITIZERS_FLAGS}
)
if (NOT MSVC)
    list(APPEND PIXI_LINK_OPTIONS
        ${PIXI_SANITIZERS_FLAGS}
    )
endif()

if (NOT ASAR_USE_DLL)
    get_target_property(ASAR_INCLUDE_DIR asar-static INCLUDE_DIRECTORIES)
endif()

if (PIXI_BUILD_EXE)
    target_link_libraries(pixi PRIVATE ${PIXI_LINK_LIBRARIES})
    target_link_options(pixi PRIVATE ${PIXI_LINK_OPTIONS})
    target_compile_options(pixi PRIVATE ${PIXI_COMPILE_OPTIONS})
    target_compile_definitions(pixi PRIVATE ${PIXI_COMPILE_DEFINITIONS} PIXI_EXE_BUILD)
    if (NOT ASAR_USE_DLL)
        target_include_directories(pixi SYSTEM PRIVATE ${ASAR_INCLUDE_DIR})
    endif()
endif()

if (PIXI_BUILD_DLL)
    target_link_libraries(pixi_api PRIVATE ${PIXI_LINK_LIBRARIES})
    target_link_options(pixi_api PRIVATE ${PIXI_LINK_OPTIONS})
    target_compile_options(pixi_api PRIVATE ${PIXI_COMPILE_OPTIONS})
    target_compile_definitions(pixi_api PRIVATE ${PIXI_COMPILE_DEFINITIONS} PIXI_DLL_BUILD)
    if (NOT ASAR_USE_DLL)
        target_include_directories(pixi_api SYSTEM PRIVATE ${ASAR_INCLUDE_DIR})
    endif()
endif()

if (PIXI_BUILD_LIB)
    target_link_libraries(pixi_api_static PRIVATE ${PIXI_LINK_LIBRARIES})
    target_link_options(pixi_api_static PRIVATE ${PIXI_LINK_OPTIONS})
    target_compile_options(pixi_api_static PRIVATE ${PIXI_COMPILE_OPTIONS})
    target_compile_definitions(pixi_api_static PRIVATE ${PIXI_COMPILE_DEFINITIONS})
    if (NOT ASAR_USE_DLL)
        target_include_directories(pixi_api_static SYSTEM PRIVATE ${ASAR_INCLUDE_DIR})
    endif()
endif()


if (PIXI_BUILD_EXE)

    if (MINGW)
        set(PIXI_SHARED_LIBRARY_PREFIX "")
    else()
        set(PIXI_SHARED_LIBRARY_PREFIX "${CMAKE_SHARED_LIBRARY_PREFIX}")
    endif()

    if (ASAR_USE_DLL)
        add_custom_command(TARGET pixi POST_BUILD 
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:asar> $<TARGET_FILE_DIR:pixi>/${PIXI_SHARED_LIBRARY_PREFIX}asar${CMAKE_SHARED_LIBRARY_SUFFIX}
            COMMENT "Copying asar dynamic library to output directory"
        )
    endif()

    if (MSVC)
        add_custom_command(
            TARGET pixi POST_BUILD
            COMMAND ${POWERSHELL_PATH} -ExecutionPolicy Bypass -File ${CMAKE_CURRENT_SOURCE_DIR}/../copy_asan_dll.ps1 -TargetPath $<TARGET_FILE:pixi> -TargetDir $<TARGET_FILE_DIR:pixi>
            USES_TERMINAL
            VERBATIM
            COMMENT "Copying required asan dlls into the output directory"
        )
    endif()
    if (ASAR_USE_DLL)
        set_target_properties(pixi PROPERTIES ASAR_LIB_PATH $<TARGET_FILE:asar>)
    endif()
    add_custom_command(TARGET pixi POST_BUILD 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/asm $<TARGET_FILE_DIR:pixi>/asm
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/cluster $<TARGET_FILE_DIR:pixi>/cluster 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/extended $<TARGET_FILE_DIR:pixi>/extended 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/generators $<TARGET_FILE_DIR:pixi>/generators 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/shooters $<TARGET_FILE_DIR:pixi>/shooters 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/misc_sprites $<TARGET_FILE_DIR:pixi>/misc_sprites 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/sprites $<TARGET_FILE_DIR:pixi>/sprites 
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/routines $<TARGET_FILE_DIR:pixi>/routines 
        COMMENT "Copying folders in output directory"
    )
endif()