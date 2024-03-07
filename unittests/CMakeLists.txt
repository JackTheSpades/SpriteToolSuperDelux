cmake_minimum_required(VERSION 3.18)
include(FetchContent)

set(BUILD_GMOCK OFF)
get_target_property(PIXI_SOURCE_DIR pixi_api_static SOURCE_DIR)
get_target_property(UNITTEST_RUNTIME_LIBRARY pixi_api_static MSVC_RUNTIME_LIBRARY)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest
    GIT_TAG main
)
enable_testing()
include(GoogleTest)

set(SAVED_C_FLAGS ${CMAKE_C_FLAGS})
set(SAVED_CXX_FLAGS ${CMAKE_C_FLAGS})
if (MSVC)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PIXI_SANITIZERS_FLAGS}")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PIXI_SANITIZERS_FLAGS}")
endif()
FetchContent_MakeAvailable(googletest)
### vvvv BEGIN WORKAROUND FOR https://github.com/google/googletest/issues/4067
set_property(TARGET gtest PROPERTY MSVC_RUNTIME_LIBRARY ${UNITTEST_RUNTIME_LIBRARY})
set_property(TARGET gtest_main PROPERTY MSVC_RUNTIME_LIBRARY ${UNITTEST_RUNTIME_LIBRARY})
### ^^^ END WORKAROUND
set(CMAKE_C_FLAGS ${SAVED_C_FLAGS})
set(CMAKE_CXX_FLAFS ${SAVED_CXX_FLAGS})
add_executable(PixiUnitTest harness.cpp)
add_library(testplugin SHARED "testplugin/testplugin.cpp")
set_property(TARGET PixiUnitTest PROPERTY MSVC_RUNTIME_LIBRARY ${UNITTEST_RUNTIME_LIBRARY})
add_dependencies(PixiUnitTest testplugin)
target_include_directories(PixiUnitTest PUBLIC ${PIXI_SOURCE_DIR})
target_link_libraries(PixiUnitTest PRIVATE pixi_api_static gtest gtest_main)
if (MSVC)
    target_compile_options(PixiUnitTest PRIVATE /utf-8 /W4 /std:c++20 /EHsc)
endif()
target_compile_options(PixiUnitTest PRIVATE ${PIXI_SANITIZERS_FLAGS})
target_link_options(PixiUnitTest PRIVATE ${PIXI_SANITIZERS_FLAGS})

if (ASAR_USE_DLL)
    get_target_property(ASAR_LIB_PATH pixi ASAR_LIB_PATH)
endif()
add_custom_command(TARGET PixiUnitTest POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/testing_files $<TARGET_FILE_DIR:PixiUnitTest>
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/asm $<TARGET_FILE_DIR:PixiUnitTest>/asm
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/cluster $<TARGET_FILE_DIR:PixiUnitTest>/cluster 
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/extended $<TARGET_FILE_DIR:PixiUnitTest>/extended 
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/generators $<TARGET_FILE_DIR:PixiUnitTest>/generators 
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/shooters $<TARGET_FILE_DIR:PixiUnitTest>/shooters 
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/misc_sprites $<TARGET_FILE_DIR:PixiUnitTest>/misc_sprites 
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/sprites $<TARGET_FILE_DIR:PixiUnitTest>/sprites 
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${TOP_LEVEL_DIR}/routines $<TARGET_FILE_DIR:PixiUnitTest>/routines 
    COMMENT "Copying necessary files in test output directory"
)
if (ASAR_USE_DLL)
    add_custom_command(TARGET PixiUnitTest POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ASAR_LIB_PATH} $<TARGET_FILE_DIR:PixiUnitTest>
    )
endif()
if (MINGW AND ASAR_USE_DLL)
    add_custom_command(TARGET PixiUnitTest POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE_DIR:PixiUnitTest>/libasar.dll $<TARGET_FILE_DIR:PixiUnitTest>/asar.dll
        COMMENT "Renaming libasar.dll to asar.dll because MinGW is a mess"
    )
endif()
if (MSVC)
    add_custom_command(
        TARGET PixiUnitTest POST_BUILD
        COMMAND ${POWERSHELL_PATH} -ExecutionPolicy Bypass -File ${CMAKE_CURRENT_SOURCE_DIR}/../copy_asan_dll.ps1 -TargetPath $<TARGET_FILE:PixiUnitTest> -TargetDir $<TARGET_FILE_DIR:PixiUnitTest>
        USES_TERMINAL
        VERBATIM
    )
endif()
gtest_discover_tests(PixiUnitTest WORKING_DIRECTORY $<TARGET_FILE_DIR:PixiUnitTest>)