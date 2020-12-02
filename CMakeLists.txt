project (go-for-it)

cmake_minimum_required (VERSION 2.8.9)
# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include (GNUInstallDirs)
# where we install data directory (if we have any)
set (INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
set (DATADIR "${INSTALL_PREFIX}/share")

set (RESOURCE_PATH "/go-for-it")
set (APP_ID "com.github.jmoerman.go-for-it" CACHE STRING "The application id.")
set (APP_SYSTEM_NAME ${APP_ID} CACHE STRING "Name to used for the executable and data directories. (This option used to affect the base name of the .desktop file, icons and appstream metadata)")
set (SCHEMA_PATH "/com/github/jmoerman/go-for-it" CACHE STRING "The gsettings schema path.")

set (PKGDATADIR ${DATADIR}/${APP_SYSTEM_NAME})
set (PLUGINDIR "${CMAKE_INSTALL_FULL_LIBDIR}/${APP_SYSTEM_NAME}/plugins")
set (FILE_CONF ${PROJECT_NAME}.conf)

set (EXEC_NAME ${APP_SYSTEM_NAME})
set (APP_NAME "Go For It!")
set (RELEASE_NAME "A stylish to-do list with built-in productivity timer")
set (VERSION "1.8.99")
set (VERSION_INFO "Development snapshot")
set (ICON_NAME ${APP_ID})
set (GETTEXT_PACKAGE ${APP_ID})
set (APIVERSION 0)
set (LIBNAME ${APP_SYSTEM_NAME}-${APIVERSION})
set (LIBVERSION "0")
set (SOVERSION 0)

# The path where library files should be searched for
set (LIBRARY_PATH "src")

set (PROJECT_WEBSITE "https://jmoerman.github.io/go-for-it/")
set (PROJECT_REPO "https://github.com/JMoerman/Go-For-It")
set (PROJECT_DONATIONS "https://jmoerman.github.io/donate/")

#for go-for-it.pc.cmake
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

# find pkgconfig to make sure dependencies are installed
find_package (PkgConfig)
# check for the required dependencies
pkg_check_modules (CORE_DEPS REQUIRED
    gtk+-3.0>=3.14.0
    glib-2.0>=2.40
    libcanberra
)

set (CORE_DEPS_VALA_PACKAGES gtk+-3.0 libcanberra)

option (ENABLE_PLUGINS "Compile with plugin support" ON)
option (BUILD_PLUGINS "Compile plugins" ON)
option (GLOBAL_PLUGIN_ICONS "Store icons used by plugins in \${CMAKE_INSTALL_PREFIX}/share/icons/hicolor in stead of \${PLUGINDIR}/\${PLUGIN_NAME}/icons/" OFF)
if (ENABLE_PLUGINS)
    pkg_check_modules (PEAS
        libpeas-1.0
        libpeas-gtk-1.0
    )
    if (PEAS_FOUND)
        set (CORE_DEPS_CFLAGS ${CORE_DEPS_CFLAGS} ${PEAS_CFLAGS})
        set (CORE_DEPS_LIBRARY_DIRS ${CORE_DEPS_LIBRARY_DIRS} ${PEAS_LIBRARY_DIRS})
        set (CORE_DEPS_LIBRARIES ${CORE_DEPS_LIBRARIES} ${PEAS_LIBRARIES})
        set (CORE_DEPS_VALA_PACKAGES ${CORE_DEPS_VALA_PACKAGES} libpeas-1.0 libpeas-gtk-1.0)
        message ("-- plugin support is enabled")
    else ()
        message ("-- libpeas is missing, disabling plugin support")
        set (ENABLE_PLUGINS OFF CACHE BOOL "" FORCE)
    endif ()
else ()
    message ("-- plugin support is disabled")
endif ()
set (DEFAULT_PLUGINS "[]" CACHE STRING "Plugins to load by default. (= if plugin is present, it will be loaded)")

set (DEPS_CFLAGS ${CORE_DEPS_CFLAGS})
set (DEPS_LIBRARY_DIRS ${CORE_DEPS_LIBRARY_DIRS})
set (DEPS_LIBRARIES ${CORE_DEPS_LIBRARIES})
set (DEPS_VALA_PACKAGES ${CORE_DEPS_VALA_PACKAGES})

option (USE_GRANITE "Build against granite" OFF)
if (USE_GRANITE)
    pkg_check_modules (GRANITE granite)
    if (${GRANITE_VERSION} VERSION_GREATER 5.4)
        set (DEPS_CFLAGS ${DEPS_CFLAGS} ${GRANITE_CFLAGS})
        set (DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${GRANITE_LIBRARY_DIRS})
        set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${GRANITE_LIBRARIES})
        message ("-- building against granite")
    else ()
        message ("-- Granite is missing or too old, using plain Gtk+ 3.0!")
        set (USE_GRANITE OFF CACHE BOOL "" FORCE)
    endif ()
else ()
    message ("-- Not using granite")
endif ()

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
include_directories(${CMAKE_BINARY_DIR}/src)

# disable some c compiler warnings
add_definitions (-Wno-incompatible-pointer-types -Wno-discarded-qualifiers -Werror=implicit-function-declaration)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# make sure we have vala
find_package (Vala REQUIRED)
# make sure we use vala
include (ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.36.15" MINIMUM)

option (BUILD_TESTS "Build a unit test executable." OFF)

option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)

# Options for when information like this is best shown elsewere
option (NO_CONTRIBUTE_DIALOG "Do not include the contribute dialog." OFF)
option (SHOW_ABOUT "Show the about action in the .desktop and menu." ON)

add_subdirectory (src)
add_subdirectory (executable)
if (ENABLE_PLUGINS AND BUILD_PLUGINS)
add_subdirectory (plugins)
endif (ENABLE_PLUGINS AND BUILD_PLUGINS)
if (BUILD_TESTS)
    add_subdirectory (tests)
endif (BUILD_TESTS)
add_subdirectory (data)
add_subdirectory (po)
