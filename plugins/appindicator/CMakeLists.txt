include_directories(${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}/src/lib/)

set (PLUGIN_NAME "appindicator")

pkg_check_modules (PLUGIN_DEPS REQUIRED
    ayatana-appindicator3-0.1
)

include(ValaPrecompile)
vala_precompile(VALA_C ${PLUGIN_NAME}
    appindicator.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    libpeas-1.0
    ayatana-appindicator3-0.1

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

message("-- Ayatana indicator plugin will be compiled")
