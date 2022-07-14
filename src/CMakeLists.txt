cmake_minimum_required(VERSION 3.18)
set(PIXI_SOURCE_FILES "")
include(FetchContent)
include(CheckIPOSupported)

set(PIXI_LINK_LIBRARIES "")
set(PIXI_LINK_OPTIONS "")
set(PIXI_COMPILE_OPTIONS "")
set(PIXI_COMPILE_DEFINITIONS GITHUB_ISSUE_LINK="https://github.com/JackTheSpades/SpriteToolSuperDelux/issues/new")

set(PIXI_VERSION_EDITION 1)
set(PIXI_VERSION_MAJOR 4)
set(PIXI_VERSION_MINOR 0)
string(TIMESTAMP PIXI_VERSION_DEBUG "%Y%m%d_%H-%M-%S" UTC)

if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR PIXI_CI_BUILD)
    list(APPEND PIXI_COMPILE_DEFINITIONS PIXI_DEV_BUILD=true)
    set(PIXI_RC_VERSION_DEBUG ${PIXI_VERSION_DEBUG})
else()
    list(APPEND PIXI_COMPILE_DEFINITIONS PIXI_DEV_BUILD=false)
    set(PIXI_RC_VERSION_DEBUG "0")
endif()

FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json
    GIT_TAG v3.10.5
)

FetchContent_MakeAvailable(json)

set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
set(ASAR_GEN_EXE OFF)
set(ASAR_GEN_EXE_TEST OFF)
set(ASAR_GEN_DLL_TEST OFF)
FetchContent_Declare(
	asar
	GIT_REPOSITORY https://github.com/RPGHacker/asar
	GIT_TAG v1.81
	SOURCE_SUBDIR src
)
FetchContent_MakeAvailable(asar)
set_target_properties(asar PROPERTIES CXX_STANDARD 14)

list(
    APPEND PIXI_LINK_LIBRARIES
    "nlohmann_json::nlohmann_json"
)

SET(PIXI_RC_CONTENTS "1 ICON \"Pixi.ico\" 

1 VERSIONINFO 
      FILEVERSION     ${PIXI_VERSION_EDITION}, ${PIXI_VERSION_MAJOR}, ${PIXI_VERSION_MINOR}, ${PIXI_RC_VERSION_DEBUG} 
      PRODUCTVERSION  ${PIXI_VERSION_EDITION}, ${PIXI_VERSION_MAJOR}, ${PIXI_VERSION_MINOR}, ${PIXI_RC_VERSION_DEBUG} 
{
    BLOCK \"StringFileInfo\" 
    {
        BLOCK \"040904b0\" // en-US with UTF-8
        {
            VALUE \"CompanyName\", \"Pixi developers\\0\" 
            VALUE \"FileDescription\", \"SMW custom sprites inserter\\0\"
            VALUE \"FileVersion\", \"v${PIXI_VERSION_EDITION}.${PIXI_VERSION_MAJOR}${PIXI_VERSION_MINOR}_${PIXI_RC_VERSION_DEBUG}\\0\"
            VALUE \"InternalName\", \"pixi\\0\" 
            VALUE \"OriginalFilename\", \"pixi.exe\\0\" 
            VALUE \"ProductName\", \"Pixi\\0\" 
            VALUE \"ProductVersion\", \"v${PIXI_VERSION_EDITION}.${PIXI_VERSION_MAJOR}${PIXI_VERSION_MINOR}_${PIXI_RC_VERSION_DEBUG}\\0\"
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

    "${CMAKE_CURRENT_SOURCE_DIR}/iohandler.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/iohandler.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/libconsole/libconsole.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/libconsole/libconsole.cpp"
    
    "${CMAKE_CURRENT_SOURCE_DIR}/pixi_information_impl.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/pixi_api.h"
)

check_ipo_supported(RESULT has_ipo OUTPUT ipo_support_error)

add_executable(pixi "${CMAKE_CURRENT_SOURCE_DIR}/main.cpp" ${PIXI_SOURCE_FILES})
add_library(pixi_api SHARED ${PIXI_SOURCE_FILES})
add_library(pixi_api_static STATIC ${PIXI_SOURCE_FILES})

if (has_ipo)
    set_property(TARGET pixi PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
    message(WARNING "IPO is not supported: ${ipo_support_error}")
endif()

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
    if (WIN32 AND NOT CMAKE_COMPILER_IS_GNUCXX)
        add_custom_command(
            TARGET pixi
            POST_BUILD
            COMMAND mt.exe -manifest ${CMAKE_CURRENT_SOURCE_DIR}/pixi.manifest -outputresource:$<TARGET_FILE:pixi>
            COMMENT "Applying manifest file"
        )
    endif()
    set_property(TARGET pixi PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    set_property(TARGET pixi_api PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	set_property(TARGET pixi_api_static PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    list(APPEND PIXI_COMPILE_OPTIONS /utf-8 /W3 /std:c++20)
    list(APPEND PIXI_COMPILE_OPTIONS
        /wd4090 # function different 'const' qualifiers (from asardll.c)
	)
endif()

list(APPEND PIXI_COMPILE_DEFINITIONS
    PIXI_VERSION_EDITION=${PIXI_VERSION_EDITION}
    PIXI_VERSION_MAJOR=${PIXI_VERSION_MAJOR}
    PIXI_VERSION_MINOR=${PIXI_VERSION_MINOR}
    PIXI_VERSION_DEBUG=${PIXI_VERSION_DEBUG}
)

target_link_libraries(pixi PRIVATE ${PIXI_LINK_LIBRARIES})
target_link_options(pixi PRIVATE ${PIXI_LINK_OPTIONS})
target_compile_options(pixi PRIVATE ${PIXI_COMPILE_OPTIONS})
target_compile_definitions(pixi PRIVATE ${PIXI_COMPILE_DEFINITIONS})

target_link_libraries(pixi_api PRIVATE ${PIXI_LINK_LIBRARIES})
target_link_options(pixi_api PRIVATE ${PIXI_LINK_OPTIONS})
target_compile_options(pixi_api PRIVATE ${PIXI_COMPILE_OPTIONS})
target_compile_definitions(pixi_api PRIVATE ${PIXI_COMPILE_DEFINITIONS} PIXI_DLL_BUILD)

target_link_libraries(pixi_api_static PRIVATE ${PIXI_LINK_LIBRARIES})
target_link_options(pixi_api_static PRIVATE ${PIXI_LINK_OPTIONS})
target_compile_options(pixi_api_static PRIVATE ${PIXI_COMPILE_OPTIONS})
target_compile_definitions(pixi_api_static PRIVATE ${PIXI_COMPILE_DEFINITIONS})

add_custom_command(TARGET pixi POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    $<TARGET_FILE:asar> $<TARGET_FILE_DIR:pixi>
    COMMENT "Copying $<TARGET_FILE:asar> to output directory"
)
set_target_properties(pixi PROPERTIES ASAR_LIB_PATH $<TARGET_FILE:asar>)

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

add_subdirectory(pixi_gui)
