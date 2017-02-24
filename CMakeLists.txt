project (go-for-it)

cmake_minimum_required (VERSION 2.6)
# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
# where we install data directory (if we have any)
set (INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
set (DATADIR "${INSTALL_PREFIX}/share")

set (PKGDATADIR "${DATADIR}/go-for-it")
set (FILE_CONF "go-for-it.conf")

set (EXEC_NAME "go-for-it")
set (APP_ID "de.manuel-kehl.go-for-it")
set (APP_NAME "Go For It!")
set (RELEASE_NAME "A stylish to-do list with built-in productivity timer.")
set (VERSION "1.5.0")
set (VERSION_INFO "initial release")
set (GETTEXT_PACKAGE "go-for-it")

set (PROJECT_WEBSITE "http://manuel-kehl.de/projects/go-for-it/")
set (PROJECT_REPO "https://github.com/mank319/Go-For-It")
set (PROJECT_DONATIONS "http://manuel-kehl.de/donations/")

# find pkgconfig to make sure dependencies are installed
find_package(PkgConfig)
# check for the required dependencies
pkg_check_modules(DEPS REQUIRED 
    gtk+-3.0>=3.22
    glib-2.0
)

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

# disable c compiler warnings
add_definitions(-w)
set (CMAKE_C_FLAGS "-mwindows")
add_definitions(-Wl, -mwindows)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

add_subdirectory (src)
add_subdirectory (data)
add_subdirectory (style)
add_subdirectory (po)
