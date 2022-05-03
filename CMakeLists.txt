cmake_minimum_required(VERSION 3.18)
project(pixi VERSION 1.32 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(TOP_LEVEL_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

include(FetchContent)
set(CMAKE_TLS_VERIFY TRUE)

function(download_dll url filename)
	FetchContent_Declare(${filename}
		URL ${url}
		DOWNLOAD_NO_EXTRACT TRUE
	)
	FetchContent_MakeAvailable(${filename})
	get_filename_component(archivename ${url} NAME)
	file(ARCHIVE_EXTRACT 
		INPUT "${${filename}_SOURCE_DIR}/${archivename}"
		DESTINATION "${${filename}_BINARY_DIR}"
		PATTERNS "*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	)
	file(GLOB_RECURSE
		"${filename}_LIB_PATH"
		"${${filename}_BINARY_DIR}/**/*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	)
	set("${filename}_LIB_PATH" "${${filename}_LIB_PATH}" PARENT_SCOPE)
endfunction(download_dll)

function(build_dll url filename)
	FetchContent_Declare(${filename}
		URL ${url}
		DOWNLOAD_NO_EXTRACT TRUE
	)
	get_filename_component(archivename ${url} NAME)
	FetchContent_MakeAvailable(${filename})
	file(ARCHIVE_EXTRACT 
		INPUT "${${filename}_SOURCE_DIR}/${archivename}"
		DESTINATION "${${filename}_BINARY_DIR}"
	)
	file(GLOB_RECURSE
		cmakelists_path
		"${${filename}_BINARY_DIR}/CMakeLists.txt"
	)
	list(GET cmakelists_path 0 primary_cmakelists)
	get_filename_component(primary_cmakelists_dir ${primary_cmakelists} DIRECTORY)
	execute_process(
		COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=MinSizeRel
		WORKING_DIRECTORY ${primary_cmakelists_dir}
	)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --build .
		WORKING_DIRECTORY ${primary_cmakelists_dir}
	)
	file(GLOB_RECURSE
		"${filename}_LIB_PATH"
		"${${filename}_BINARY_DIR}/**/*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	)
	set("${filename}_LIB_PATH" "${${filename}_LIB_PATH}" PARENT_SCOPE)
endfunction(build_dll)

add_subdirectory(src)