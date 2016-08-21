project (go-for-it)

cmake_minimum_required (VERSION 2.6)
# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
include (GNUInstallDirs)

set (PKGDATADIR "${DATADIR}/go-for-it")
set (FILE_CONF "go-for-it.conf")

set (EXEC_NAME "go-for-it")
set (APP_ID "de.manuel-kehl.go-for-it")
set (APP_NAME "Go For It!")
set (RELEASE_NAME "A stylish to-do list with built-in productivity timer.")
set (VERSION "1.4.7")
set (VERSION_INFO "initial release")
set (LIBNAME "gofi")
set (LIBVERSION "0")
set (SOVERSION 0)
set (PACKAGE_NAME "go-for-it")

set (PROJECT_WEBSITE "http://manuel-kehl.de/projects/go-for-it/")
set (PROJECT_REPO "https://github.com/mank319/Go-For-It")
set (PROJECT_DONATIONS "http://manuel-kehl.de/donations/")

# find pkgconfig to make sure dependencies are installed
find_package(PkgConfig)
# check for the required dependencies
pkg_check_modules(DEPS REQUIRED 
    gtk+-3.0
    glib-2.0
    libnotify
)

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

# disable c compiler warnings
add_definitions(-w)
add_definitions(-DGETTEXT_PACKAGE="go-for-it")

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

add_subdirectory (src)
add_subdirectory (data)
add_subdirectory (style)
