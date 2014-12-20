project (just-do-it)

cmake_minimum_required (VERSION 2.6)
# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

set (PKGDATADIR "${DATADIR}/just-do-it")
set (EXEC_NAME "just-do-it")
set (RELEASE_NAME "A stylish to-do list with built-in productivity timer.")
set (VERSION "0.1")
set (VERSION_INFO "initial release")

# find pkgconfig to make sure dependencies are installed
find_package(PkgConfig)
# check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0)
add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)
# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Utils.vala
    src/SettingsManager.vala
    src/TaskStore.vala
    src/TaskManager.vala
    src/view/TaskList.vala
    src/TaskTimer.vala
    src/view/TimerView.vala
    src/view/SettingsDialog.vala
    src/view/MainWindow.vala
    src/Main.vala
    
# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})
# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
# install .desktop file so the Applications menu will display it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/just-do-it.desktop DESTINATION ${DATADIR}/applications/)
# install the application's stylesheet
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/style/just-do-it.css DESTINATION ${PKGDATADIR}/style/)
# install the application's icons
set(SYSTEM_DEFAULT_THEME ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/16x16/apps/just-do-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/16x16/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/24x24/apps/just-do-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/32x32/apps/just-do-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/32x32/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/48x48/apps/just-do-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/48x48/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/64x64/apps/just-do-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/64x64/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/128x128/apps/just-do-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/128x128/apps)

install(
    CODE
    "execute_process (COMMAND gtk-update-icon-cache -t -f ${SYSTEM_DEFAULT_THEME})"
    CODE
    "message (STATUS \"Updated icon cache in ${SYSTEM_DEFAULT_THEME}\")"
    )
