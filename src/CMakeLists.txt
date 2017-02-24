# Create Constants.vala
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala)

# Generate object file containing the icon
execute_process(COMMAND windres "${CMAKE_SOURCE_DIR}/data/app-icon.rs" -o "${CMAKE_CURRENT_BINARY_DIR}/app-icon.o")

# checking if have a recent version of Gtk+-3.0
pkg_check_modules( GTK3 gtk+-3.0 )
if (${GTK3_VERSION} VERSION_GREATER 3.9)
    set (VALAC_OPTIONS ${VALAC_OPTIONS} -D HAS_GTK310)
else ()
    message ("-- No recent Gtk+-3.0 found... Using pre 3.10 features.")
endif ()

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    Constants.vala
    Utils.vala
    SettingsManager.vala
    TodoTask.vala
    TaskStore.vala
    TaskManager.vala
    view/TaskList.vala
    TaskTimer.vala
    view/TimerView.vala
    view/SettingsDialog.vala
    view/AboutDialog.vala
    view/ContributeDialog.vala
	view/WinNotification.vala
    view/MainWindow.vala
    Main.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0

OPTIONS
    ${VALAC_OPTIONS}
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME}
	${CMAKE_CURRENT_BINARY_DIR}/app-icon.o 
	${VALA_C})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})
# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
