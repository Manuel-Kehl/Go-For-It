include (Translations)
include_directories(${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}/src/lib/)

set (PLUGIN_NAME "launcherindicator")

pkg_check_modules (LAUNCHER_PLUGIN_DEPS
    unity
)

if (LAUNCHER_PLUGIN_DEPS_FOUND)
    include(ValaPrecompile)
    vala_precompile(VALA_C ${PLUGIN_NAME}
        LauncherIndicator.vala

    # tell what libraries to use when compiling
    PACKAGES
        gtk+-3.0
        libpeas-1.0
        unity

    CUSTOM_VAPIS
        ${CMAKE_BINARY_DIR}/src/${LIBNAME}.vapi
    OPTIONS
        ${VALAC_OPTIONS}
    )

    add_definitions(${LAUNCHER_PLUGIN_DEPS_CFLAGS})
    link_directories (${LAUNCHER_PLUGIN_DEPS_LIBRARY_DIRS})

    add_library(${PLUGIN_NAME} MODULE ${VALA_C})
    target_link_libraries(${PLUGIN_NAME} ${LIBNAME} ${LAUNCHER_PLUGIN_DEPS_LIBRARIES})

    configure_file_translation (${PLUGIN_NAME}.plugin ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.plugin ${CMAKE_SOURCE_DIR}/po/)

    install(TARGETS ${PLUGIN_NAME} DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.plugin DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})

    message("-- Launcher inidicator plugin (libunity) will be compiled")
else ()
    message("-- Launcher inidicator plugin (libunity) will not be compiled")
endif ()
