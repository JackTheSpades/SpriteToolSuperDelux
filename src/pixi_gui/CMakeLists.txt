cmake_minimum_required(VERSION 3.18)

find_package(Qt6 REQUIRED COMPONENTS Widgets)
qt_standard_project_setup()

add_executable(PixiGui
    PixiGuiUI.h
	PixiGuiUI.cpp
    PixiGui.cpp
	PixiGui.h
    PixiGui.ui
)

cmake_path(GET CMAKE_CURRENT_SOURCE_DIR PARENT_PATH PIXI_INCLUDE_DIR)
message(STATUS "JSON SOURCE DIR: ${json_SOURCE_DIR}")
target_include_directories(PixiGui PRIVATE ${PIXI_INCLUDE_DIR} ${json_SOURCE_DIR}/single_include)
target_link_libraries(PixiGui PRIVATE Qt6::Widgets pixi_api_static)

if (WIN32)
    target_compile_options(PixiGui PRIVATE /utf-8 /Zc:preprocessor)
    target_compile_definitions(PixiGui PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

set_target_properties(PixiGui PROPERTIES
    WIN32_EXECUTABLE ON
	MACOSX_BUNDLE ON
)

get_target_property(_qmake_executable Qt6::qmake IMPORTED_LOCATION)
get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
find_program(WINDEPLOYQT_EXE windeployqt HINTS "${_qt_bin_dir}")

if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_CONFIGURATION_TYPES STREQUAL "Debug")
    set(WINDEPLOY_CFG "debug")
else()
    set(WINDEPLOY_CFG "release")
endif()

if (WIN32)
    message(STATUS "Building ${WINDEPLOY_CFG} windeploy")
    add_custom_command(TARGET PixiGui POST_BUILD
        COMMAND ${WINDEPLOYQT_EXE} --${WINDEPLOY_CFG} --no-compiler-runtime --no-translations "$<TARGET_FILE:PixiGui>"
		WORKING_DIRECTORY ${_qt_bin_dir}
        COMMENT "Running windeployqt..."
    )
endif()

add_custom_command(TARGET PixiGui POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    $<TARGET_FILE:asar> $<TARGET_FILE_DIR:PixiGui>
    COMMENT "Copying $<TARGET_FILE:asar> to output directory"
)

if (WINDEPLOY_CFG STREQUAL "release")
    message(STATUS "Building Release, removing qDebug()")
    target_compile_definitions(PixiGui PRIVATE QT_NO_DEBUG_OUTPUT)
	if (WIN32)
        target_link_options(PixiGui PRIVATE /SUBSYSTEM:windows /ENTRY:mainCRTStartup)
    endif()
endif()