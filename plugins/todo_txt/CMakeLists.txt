include_directories(${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}/src/lib/)

set (PLUGIN_NAME "todo_txt")

include(ValaPrecompile)
vala_precompile(VALA_C ${PLUGIN_NAME}
    src/Constants.vala
    src/TXTTask.vala
    src/Utils.vala
    src/SettingsManager.vala
    src/TaskStore.vala
    src/TaskManager.vala
    src/TXTList.vala
    src/TXTListProvider.vala
    src/view/TaskList.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    libpeas-1.0

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/src/lib/${PACKAGE_NAME}.vapi
OPTIONS
    ${VALAC_OPTIONS}
)

add_library(${PLUGIN_NAME} MODULE ${VALA_C})
target_link_libraries(${PLUGIN_NAME} ${LIBNAME})

install(TARGETS ${PLUGIN_NAME} DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})
install(FILES ${PLUGIN_NAME}.plugin DESTINATION ${PLUGINDIR}/${PLUGIN_NAME})

message("-- Todo.txt plugin will be compiled")
