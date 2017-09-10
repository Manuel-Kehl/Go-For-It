# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
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

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})
add_dependencies(${EXEC_NAME} ${LIBNAME})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES} ${LIBNAME})
# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
