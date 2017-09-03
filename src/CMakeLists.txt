# Create Constants.vala
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    Constants.vala
    Utils.vala
    SettingsManager.vala
    TodoTask.vala
    TaskStore.vala
    TaskManager.vala
    TaskTimer.vala
    DragListModel.vala
    Filter.vala
    view/TaskRow.vala
    view/TaskList.vala
    view/DragList.vala
    view/TimerView.vala
    view/SettingsDialog.vala
    view/AboutDialog.vala
    view/ContributeDialog.vala
    view/MainWindow.vala
    Main.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    libnotify

OPTIONS
    ${VALAC_OPTIONS}
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})
# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
