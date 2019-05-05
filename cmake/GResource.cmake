# Taken from FindGLib.cmake with dependency output fix applied
#
# FindGLib.cmake
# <https://github.com/nemequ/gnome-cmake>
#
# CMake support for GLib/GObject/GIO.
#
# License:
#
#   Copyright (c) 2016 Evan Nemerson <evan@nemerson.com>
#
#   Permission is hereby granted, free of charge, to any person
#   obtaining a copy of this software and associated documentation
#   files (the "Software"), to deal in the Software without
#   restriction, including without limitation the rights to use, copy,
#   modify, merge, publish, distribute, sublicense, and/or sell copies
#   of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be
#   included in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.

find_program(GLIB_COMPILE_RESOURCES glib-compile-resources)
if(GLIB_COMPILE_RESOURCES)
  add_executable(glib-compile-resources IMPORTED)
  set_property(TARGET glib-compile-resources PROPERTY IMPORTED_LOCATION "${GLIB_COMPILE_RESOURCES}")
endif()

function(glib_compile_resources SPEC_FILE)
  set (options INTERNAL)
  set (oneValueArgs TARGET SOURCE_DIR HEADER SOURCE C_NAME)
  set (multiValueArgs)
  cmake_parse_arguments(GLIB_COMPILE_RESOURCES "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  unset (options)
  unset (oneValueArgs)
  unset (multiValueArgs)

  if(NOT GLIB_COMPILE_RESOURCES_SOURCE_DIR)
    set(GLIB_COMPILE_RESOURCES_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  set(FLAGS)

  if(GLIB_COMPILE_RESOURCES_INTERNAL)
    list(APPEND FLAGS "--internal")
  endif()

  if(GLIB_COMPILE_RESOURCES_C_NAME)
    list(APPEND FLAGS "--c-name" "${GLIB_COMPILE_RESOURCES_C_NAME}")
  endif()

  get_filename_component(SPEC_FILE "${SPEC_FILE}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

  execute_process(
    COMMAND glib-compile-resources
      --generate-dependencies
      --sourcedir "${GLIB_COMPILE_RESOURCES_SOURCE_DIR}"
      "${SPEC_FILE}"
    OUTPUT_VARIABLE in_file_dep
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  string(REGEX REPLACE "(\r?\n)" ";" in_file_dep "${in_file_dep}")
  set(deps "${SPEC_FILE}")
  foreach(dep ${in_file_dep})
    list(APPEND deps "${dep}")
  endforeach(dep ${in_file_dep})

  if(GLIB_COMPILE_RESOURCES_HEADER)
    get_filename_component(GLIB_COMPILE_RESOURCES_HEADER "${GLIB_COMPILE_RESOURCES_HEADER}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")

    add_custom_command(
      OUTPUT "${GLIB_COMPILE_RESOURCES_HEADER}"
      COMMAND glib-compile-resources
        --sourcedir "${GLIB_COMPILE_RESOURCES_SOURCE_DIR}"
        --generate-header
        --target "${GLIB_COMPILE_RESOURCES_HEADER}"
        ${FLAGS}
        "${SPEC_FILE}"
      DEPENDS ${deps}
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  if(GLIB_COMPILE_RESOURCES_SOURCE)
    get_filename_component(GLIB_COMPILE_RESOURCES_SOURCE "${GLIB_COMPILE_RESOURCES_SOURCE}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")

    add_custom_command(
      OUTPUT "${GLIB_COMPILE_RESOURCES_SOURCE}"
      COMMAND glib-compile-resources
        --sourcedir "${GLIB_COMPILE_RESOURCES_SOURCE_DIR}"
        --generate-source
        --target "${GLIB_COMPILE_RESOURCES_SOURCE}"
        ${FLAGS}
        "${SPEC_FILE}"
      DEPENDS "${SPEC_FILE}" ${deps}
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()
endfunction()
