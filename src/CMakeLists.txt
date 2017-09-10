# Create Constants.vala
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.pc.cmake ${CMAKE_CURRENT_BINARY_DIR}/${LIBNAME}.pc)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.deps.cmake ${CMAKE_CURRENT_BINARY_DIR}/${LIBNAME}.deps)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${LIBNAME}
    Constants.vala
    Utils.vala
    SettingsManager.vala
    TodoTask.vala
    TaskStore.vala
    FileWatcher.vala
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
GENERATE_VAPI
    ${LIBNAME}
GENERATE_HEADER
    ${LIBNAME}
GENERATE_INTERNAL_VAPI
    ${LIBNAME}_internal
GENERATE_INTERNAL_HEADER
    ${LIBNAME}_internal
)

set (LIBS ${DEPS_LIBRARIES} -lm)
set (LIB_PATHS ${DEPS_LIBRARY_DIRS})
link_directories (${LIB_PATHS})

set (LIB_FILES ${C_SOURCES} ${VALA_C})

add_library (${LIBNAME} SHARED
    ${LIB_FILES}
)

target_link_libraries (${LIBNAME} ${LIBS})

set_target_properties (${LIBNAME} PROPERTIES
    VERSION ${LIBVERSION}.0
    SOVERSION ${SOVERSION})

install (TARGETS ${LIBNAME} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

# Install lib stuffs
install (FILES ${CMAKE_BINARY_DIR}/src/${LIBNAME}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIBNAME}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIBNAME}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIBNAME}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/scratch/)
