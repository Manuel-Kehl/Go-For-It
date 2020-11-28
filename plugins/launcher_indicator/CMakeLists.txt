include (Translations)
include_directories(${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}/src/lib/)

set (PLUGIN_NAME "launcherindicator")

set (VALA_PACKAGES gtk+-3.0 libpeas-1.0)

if (USE_GRANITE)
  set (LAUNCHER_PLUGIN_SOURCES LauncherIndicator.vala)
  set (VALAC_OPTIONS ${VALAC_OPTIONS} -D USE_GRANITE)
  set (VALA_PACKAGES ${VALA_PACKAGES} granite)
else ()
  set (LAUNCHER_PLUGIN_SOURCES LauncherIndicator.vala LauncherEntryAPI.vala)
endif ()

include(ValaPrecompile)
vala_precompile(VALA_C ${PLUGIN_NAME}
    ${LAUNCHER_PLUGIN_SOURCES}

# tell what libraries to use when compiling
PACKAGES
    ${VALA_PACKAGES}

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/src/${LIBNAME}.vapi
OPTIONS
    ${VALAC_OPTIONS}
)

add_definitions(${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

add_library(${PLUGIN_NAME} MODULE ${VALA_C})
target_link_libraries(${PLUGIN_NAME} ${LIBNAME} ${DEPS_LIBRARIES})

configure_file_translation (${PLUGIN_NAME}.plugin ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.plugin ${CMAKE_SOURCE_DIR}/po/)

install(TARGETS ${PLUGIN_NAME} DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.plugin DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})

message("-- Launcher inidicator plugin (Unity LauncherEntry API) will be compiled")
