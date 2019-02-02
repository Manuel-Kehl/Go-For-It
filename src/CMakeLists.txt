# Create Constants.vala
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala)

if (${NO_CONTRIBUTE_DIALOG})
    set (VALAC_OPTIONS ${VALAC_OPTIONS} -D NO_CONTRIBUTE_DIALOG)
endif ()
if (${SHOW_ABOUT})
    set (VALAC_OPTIONS ${VALAC_OPTIONS} -D SHOW_ABOUT)
endif ()

# checking if have a recent version of Gtk+-3.0
pkg_check_modules( GTK3 gtk+-3.0 )
if (${GTK3_VERSION} VERSION_GREATER 3.21)
    set (VALAC_OPTIONS ${VALAC_OPTIONS} -D HAS_GTK322)
else ()
    message ("-- No recent Gtk+-3.0 found... Using pre 3.22 features.")
endif ()

# files we want to compile
include (ValaPrecompile)
vala_precompile (VALA_C ${LIBNAME}
    Constants.vala
    Utils.vala
    SettingsManager.vala
    ListInfo.vala
    ListManager.vala
    TodoTask.vala
    SequentialList.vala
    FileWatcher.vala
    TaskTimer.vala
    DragListModel.vala
    view/Widgets/TodoListInfoRow.vala
    view/Widgets/DragList.vala
    view/Dialogs/SettingsDialog.vala
    view/Dialogs/AboutDialog.vala
    view/Dialogs/ContributeDialog.vala
    view/TimerView.vala
    view/TaskListPage.vala
    view/SelectionPage.vala
    view/MainWindow.vala
    todo.txt/TxtUtils.vala
    todo.txt/TaskStore.vala
    todo.txt/TaskManager.vala
    todo.txt/ListSettings.vala
    todo.txt/Filter.vala
    todo.txt/TxtList.vala
    todo.txt/TxtListManager.vala
    todo.txt/view/TaskList.vala
    todo.txt/view/TaskRow.vala
    todo.txt/view/ListCreateDialog.vala
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
