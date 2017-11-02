include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/${APP_SYSTEM_NAME}.desktop.in
    APPDATA_FILES
        ${CMAKE_BINARY_DIR}/data/${APP_SYSTEM_NAME}.appdata.xml.in
)
