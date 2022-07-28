cmake_minimum_required(VERSION 3.18)
include(FetchContent)

get_target_property(PIXI_SOURCE_DIR pixi_api_static SOURCE_DIR)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest
    GIT_TAG main
)
enable_testing()
include(GoogleTest)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

add_executable(PixiUnitTest harness.cpp)
target_include_directories(PixiUnitTest PUBLIC ${PIXI_SOURCE_DIR})
target_link_libraries(PixiUnitTest PRIVATE pixi_api_static gtest_main)

get_target_property(ASAR_LIB_PATH pixi ASAR_LIB_PATH)
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
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ASAR_LIB_PATH} $<TARGET_FILE_DIR:PixiUnitTest>
    COMMENT "Copying necessary files in test output directory"
)

gtest_discover_tests(PixiUnitTest WORKING_DIRECTORY $<TARGET_FILE_DIR:PixiUnitTest>)