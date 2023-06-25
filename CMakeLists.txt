cmake_policy(SET CMP0091 NEW)
cmake_minimum_required(VERSION 3.18)
project(pixi VERSION 1.40 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(TOP_LEVEL_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
option(PIXI_CI_BUILD "Set to true if this is a CI build, not to publish." OFF)
option(PIXI_BUILD_TESTS "Set to true to build tests." ON)
option(PIXI_BUILD_DLL "Build pixi as a dynamic library" ON)
option(PIXI_BUILD_LIB "Build pixi as a static library" ON)
option(PIXI_BUILD_EXE "Build pixi as an executable" ON)
option(PIXI_FORCE_SANITIZERS "Always enable sanitizers, even in release builds" OFF)
option(PIXI_DISABLE_SANITIZERS "Always disable sanitizers, this takes precendence over PIXI_FORCE_SANITIZERS" OFF)
find_package(Python COMPONENTS Interpreter)
find_program(CCACHE_FOUND ccache)
if (CCACHE_FOUND)
	message(STATUS "ccache executable was found")
	set(C_COMPILER_LAUNCHER "ccache")
	set(CXX_COMPILER_LAUNCHER "ccache")
endif()
if (MSVC)
	find_program(POWERSHELL_PATH NAMES powershell)
endif()
if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR PIXI_FORCE_SANITIZERS)
	if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_SIMULATE_ID MATCHES "MSVC") # windows + clang-cl
		set(PIXI_SANITIZERS_FLAGS "")
	elseif(MINGW OR CYGWIN)
		set(PIXI_SANITIZERS_FLAGS "")
	elseif(UNIX OR APPLE)	# gcc/clang on linux/macos
		set(PIXI_SANITIZERS_FLAGS "-fsanitize=address,undefined,leak")
	elseif(WIN32)			# windows + cl.exe
		set(PIXI_SANITIZERS_FLAGS "/fsanitize=address")
	endif()
endif()
if (PIXI_DISABLE_SANITIZERS)
	set(PIXI_SANITIZERS_FLAGS "")
endif()
message(STATUS "Setting sanitizers flags to \"${PIXI_SANITIZERS_FLAGS}\"")
add_subdirectory(src)
if (PIXI_BUILD_TESTS AND PIXI_BUILD_LIB)
	message(STATUS "Building test suite")
	add_subdirectory(unittests)
endif()
add_custom_command(
	OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/json_const.h" "${CMAKE_CURRENT_SOURCE_DIR}/src/CFG Editor/CFG Editor/Json/JsonConst.cs"
	COMMAND ${Python_EXECUTABLE} generate_json.py
	DEPENDS tweak_bit_names.json generate_json.py
	COMMENT "Generating JSON tweak source files"
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_custom_target(
	JsonBitGenerator 
	DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/json_const.h" "${CMAKE_CURRENT_SOURCE_DIR}/src/CFG Editor/CFG Editor/Json/JsonConst.cs" 
	COMMENT "Check if we need to re-run the generator"
)
if (PIXI_BUILD_EXE)
	add_dependencies(pixi JsonBitGenerator)
endif()
if (PIXI_BUILD_DLL)
	add_dependencies(pixi_api JsonBitGenerator)
endif()
if (PIXI_BUILD_LIB)
	add_dependencies(pixi_api_static JsonBitGenerator)
endif()