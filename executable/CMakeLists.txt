# files we want to compile
include (ValaPrecompile)
vala_precompile (VALA_C ${EXEC_NAME}
    go-for-it.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    libnotify
OPTIONS
    ${VALAC_OPTIONS}
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/${LIBRARY_PATH}/${LIBNAME}_internal.vapi
)

include(GResource)

configure_file (${CMAKE_SOURCE_DIR}/data/resources.gresource.xml.in ${CMAKE_CURRENT_BINARY_DIR}/resources.gresource.xml)

glib_compile_resources("${CMAKE_CURRENT_BINARY_DIR}/resources.gresource.xml"
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/data"
  SOURCE "${CMAKE_CURRENT_BINARY_DIR}/gui-resources.c"
  C_NAME "gofi_gui_resources"
  INTERNAL)

# tell cmake what to call the executable we just made
add_executable (${EXEC_NAME}
    "${CMAKE_CURRENT_BINARY_DIR}/gui-resources.c"
    ${VALA_C}
    )
add_dependencies (${EXEC_NAME} ${LIBNAME})
set_target_properties (${EXEC_NAME} PROPERTIES
    INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/${LIBRARY_PATH}
)
target_link_libraries (${EXEC_NAME} ${LIBNAME})
# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
