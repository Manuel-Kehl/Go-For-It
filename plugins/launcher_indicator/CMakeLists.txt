include_directories(${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}/src/lib/)

set (PLUGIN_NAME "launcherindicator")

pkg_check_modules (PLUGIN_DEPS
    unity
)

if (PLUGIN_DEPS_FOUND)
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

    add_definitions(${PLUGIN_DEPS_CFLAGS})
    link_directories (${PLUGIN_DEPS_LIBRARY_DIRS})

    add_library(${PLUGIN_NAME} MODULE ${VALA_C})
    target_link_libraries(${PLUGIN_NAME} ${LIBNAME} ${PLUGIN_DEPS_LIBRARIES})

    install(TARGETS ${PLUGIN_NAME} DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})
    install(FILES ${PLUGIN_NAME}.plugin DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})

    message("-- Launcher inidicator plugin (libunity) will be compiled")
else ()
    message("-- Launcher inidicator plugin (libunity) will not be compiled")
endif ()
