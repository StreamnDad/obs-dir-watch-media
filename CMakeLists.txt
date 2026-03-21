# --- Detect if the plugin is build out of tree or not ---
if(CMAKE_PROJECT_NAME STREQUAL "obs-studio")
  set(BUILD_OUT_OF_TREE OFF)
  if(OBS_CMAKE_VERSION VERSION_GREATER_EQUAL 3.0.0)
    legacy_check()
  endif()
else()
  set(BUILD_OUT_OF_TREE ON)
  cmake_minimum_required(VERSION 3.18)
endif()

project(dir-watch-media VERSION 0.7.1)
set(PROJECT_FULL_NAME "Directory Watch Media")

# Set new UUIDs when you start to create a new plugin.
set(MACOS_PACKAGE_UUID "AA2D9C73-418B-4680-9B70-5740DEE8340E")
set(MACOS_INSTALLER_UUID "BEA2887C-4DA5-4BE1-862C-64DDB55B2ADB")

add_library(${PROJECT_NAME} MODULE)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/version.h.in ${CMAKE_CURRENT_SOURCE_DIR}/version.h)

target_sources(${PROJECT_NAME} PRIVATE
	dir-watch-media.c
	dir-watch-media.h
	version.h)

if(BUILD_OUT_OF_TREE)
	find_package(libobs QUIET)
	if(libobs_FOUND)
		include(cmake/ObsPluginHelpers.cmake)
	else()
		# Local dev fallback: manual OBS_INCLUDE_DIR / OBS_LIBRARY
		set(OBS_INCLUDE_DIR "" CACHE PATH "Path to OBS include directory containing obs-module.h")
		set(OBS_LIBRARY "" CACHE FILEPATH "Path to libobs library file")
		if(NOT OBS_INCLUDE_DIR OR NOT OBS_LIBRARY)
			message(FATAL_ERROR
				"libobs was not found via find_package. Set OBS_INCLUDE_DIR and OBS_LIBRARY.\n"
				"Run: make find-obs-dev-paths")
		endif()
		# OBS headers include simde for SSE intrinsics on ARM
		set(SIMDE_INCLUDE_DIR "" CACHE PATH "Path to simde include directory (auto-detected on macOS)")
		if(NOT SIMDE_INCLUDE_DIR AND APPLE)
			execute_process(
				COMMAND brew --prefix simde
				OUTPUT_VARIABLE _simde_prefix
				OUTPUT_STRIP_TRAILING_WHITESPACE
				ERROR_QUIET
				RESULT_VARIABLE _simde_result)
			if(_simde_result EQUAL 0 AND EXISTS "${_simde_prefix}/include")
				set(SIMDE_INCLUDE_DIR "${_simde_prefix}/include" CACHE PATH "" FORCE)
			endif()
		endif()

		set(_obs_interface_dirs "${OBS_INCLUDE_DIR}")
		if(SIMDE_INCLUDE_DIR)
			list(APPEND _obs_interface_dirs "${SIMDE_INCLUDE_DIR}")
		endif()
		# Fallback obsconfig.h for out-of-tree builds
		if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include/obsconfig.h")
			list(APPEND _obs_interface_dirs "${CMAKE_CURRENT_SOURCE_DIR}/include")
		endif()

		add_library(OBS::libobs UNKNOWN IMPORTED)
		set_target_properties(OBS::libobs PROPERTIES
			IMPORTED_LOCATION "${OBS_LIBRARY}"
			INTERFACE_INCLUDE_DIRECTORIES "${_obs_interface_dirs}")
	endif()
endif()
  
if(OS_WINDOWS)
	get_filename_component(ISS_FILES_DIR "${CMAKE_BINARY_DIR}\\..\\package" ABSOLUTE)
	file(TO_NATIVE_PATH "${ISS_FILES_DIR}" ISS_FILES_DIR)
	get_filename_component(ISS_PACKAGE_DIR "${CMAKE_PACKAGE_PREFIX}\\.." ABSOLUTE)
	file(TO_NATIVE_PATH "${ISS_PACKAGE_DIR}" ISS_PACKAGE_DIR)
	get_filename_component(ISS_SOURCE_DIR "${PROJECT_SOURCE_DIR}" ABSOLUTE)
	file(TO_NATIVE_PATH "${ISS_SOURCE_DIR}" ISS_SOURCE_DIR)
	configure_file("installer.iss.in"
			"${PROJECT_BINARY_DIR}/installer.iss"
		)
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/resource.rc.in ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.rc)
	target_sources(${PROJECT_NAME} PRIVATE 
		${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.rc)
elseif(OS_MACOS)
		set(MACOS_BUNDLEID "com.exeldro.${PROJECT_NAME}")
		set(MACOSX_PLUGIN_GUI_IDENTIFIER "${MACOS_BUNDLEID}")
		set(MACOSX_PLUGIN_BUNDLE_VERSION "${PROJECT_VERSION}")
		set(MACOSX_PLUGIN_SHORT_VERSION_STRING "1")
		configure_file(cmake/bundle/macos/installer-macos.pkgproj.in ${CMAKE_BINARY_DIR}/installer-macos.generated.pkgproj)
		target_compile_options(${PROJECT_NAME} PRIVATE -Wall)
endif()

target_link_libraries(${PROJECT_NAME}
	OBS::libobs)

if(BUILD_OUT_OF_TREE)
    if(NOT LIB_OUT_DIR)
        set(LIB_OUT_DIR "/lib/obs-plugins")
    endif()
    if(NOT DATA_OUT_DIR)
        set(DATA_OUT_DIR "/share/obs/obs-plugins/${PROJECT_NAME}")
    endif()
    set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
    install(TARGETS ${PROJECT_NAME}
        LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/${LIB_OUT_DIR})
    install(DIRECTORY data/locale
        DESTINATION ${CMAKE_INSTALL_PREFIX}/${DATA_OUT_DIR})
    if(COMMAND setup_plugin_target)
        setup_plugin_target(${PROJECT_NAME})
    endif()
else()
    target_include_directories(${PROJECT_NAME} PRIVATE
        "${CMAKE_SOURCE_DIR}/UI/obs-frontend-api")
    if(OBS_CMAKE_VERSION VERSION_GREATER_EQUAL 3.0.0)
        set_target_properties_obs(${PROJECT_NAME} PROPERTIES FOLDER "plugins/exeldro" PREFIX "")
    else()
        set_target_properties(${PROJECT_NAME} PROPERTIES FOLDER "plugins/exeldro")
        setup_plugin_target(${PROJECT_NAME})
    endif()
endif()
