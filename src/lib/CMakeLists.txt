# Generate Constants.vala and go-for-it.pc
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/${PACKAGE_NAME}.pc.cmake ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}.pc)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    Constants.vala
    Utils.vala
    SettingsManager.vala
    Interface.vala
    PluginManager.vala
    TodoTask.vala
    TaskList.vala
    TaskTimer.vala
    view/TimerView.vala
    view/TaskLayout.vala
    view/ListChooser.vala
    view/SettingsDialog.vala
    view/AboutDialog.vala
    view/ContributeDialog.vala
    view/MainWindow.vala
    Main.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    libnotify
    libpeas-1.0
    libpeas-gtk-1.0

OPTIONS
    ${VALAC_OPTIONS}
GENERATE_VAPI
    ${PACKAGE_NAME}
GENERATE_HEADER
    ${PACKAGE_NAME}
)

add_library (${LIBNAME} SHARED
    ${VALA_C}
)

# link the library to the dependencies
target_link_libraries(${LIBNAME} ${DEPS_LIBRARIES})

set_target_properties (${LIBNAME} PROPERTIES
    VERSION ${LIBVERSION}.0
    SOVERSION ${SOVERSION}
)
    
list(APPEND VAPIFILES "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}.vapi")

# install library
install (TARGETS ${LIBNAME} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

# install development files
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/${PACKAGE_NAME}/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${PACKAGE_NAME}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
