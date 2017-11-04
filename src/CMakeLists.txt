# Create Constants.vala
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala)

if (${NO_CONTRIBUTE_DIALOG})
    set (VALAC_OPTIONS ${VALAC_OPTIONS} -D NO_CONTRIBUTE_DIALOG)
endif ()
if (${SHOW_ABOUT})
    set (VALAC_OPTIONS ${VALAC_OPTIONS} -D SHOW_ABOUT)
endif ()

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

add_library (${LIBNAME} STATIC
    ${LIB_FILES}
)

target_link_libraries (${LIBNAME} ${LIBS})
