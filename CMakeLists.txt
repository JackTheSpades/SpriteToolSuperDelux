cmake_policy(SET CMP0091 NEW)
cmake_minimum_required(VERSION 3.18)
project(pixi VERSION 1.40 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(TOP_LEVEL_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
option(PIXI_CI_BUILD "Set to true if this is a CI build, not to publish." OFF)
option(PIXI_BUILD_TESTS "Set to true to build tests." ON)
find_package(Python COMPONENTS Interpreter)
add_subdirectory(src)
if (PIXI_BUILD_TESTS)
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
add_dependencies(pixi JsonBitGenerator)
add_dependencies(pixi_api JsonBitGenerator)
add_dependencies(pixi_api_static JsonBitGenerator)