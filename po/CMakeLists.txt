include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    ../plugins
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/${APP_ID}.desktop.in
    APPDATA_FILES
        ${CMAKE_BINARY_DIR}/data/${APP_ID}.appdata.xml.in
    PLUGIN_FILES
        ../plugins/appindicator/appindicator.plugin
        ../plugins/launcher_indicator/launcherindicator.plugin
)
