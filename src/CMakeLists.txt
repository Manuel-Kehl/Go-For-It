add_subdirectory (lib)
include_directories(${CMAKE_BINARY_DIR}/src/lib/)

include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    Go-for-it.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    libnotify

CUSTOM_VAPIS
    ${CMAKE_CURRENT_BINARY_DIR}/lib/${PACKAGE_NAME}.vapi
OPTIONS
    ${VALAC_OPTIONS}
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})
target_link_libraries(${EXEC_NAME} ${LIBNAME})
# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
