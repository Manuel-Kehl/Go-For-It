include (Translations)

if (SHOW_ABOUT)
set (ABOUT_ACTION
"Actions=AboutDialog;

[Desktop Action AboutDialog]
Name=About ${APP_NAME}
Exec=${EXEC_NAME} --about"
)
else ()

endif ()
configure_file (go-for-it.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.desktop.in)
configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.desktop ${CMAKE_SOURCE_DIR}/po/)
configure_file (go-for-it.appdata.xml.in.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.appdata.xml.in)
configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

# install .desktop file so the Applications menu will display it
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.desktop DESTINATION ${DATADIR}/applications/)

# install appdata file which provides metadata for software centers
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.appdata.xml DESTINATION ${DATADIR}/metainfo/)

# install the application's icons
set (SYSTEM_DEFAULT_THEME ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)
set (ICON_FOLDER /icons)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/16x16/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/16x16/apps RENAME ${ICON_NAME}.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/24x24/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/apps RENAME ${ICON_NAME}.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/32x32/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/32x32/apps RENAME ${ICON_NAME}.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/48x48/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/48x48/apps RENAME ${ICON_NAME}.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/64x64/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/64x64/apps RENAME ${ICON_NAME}.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/128x128/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/128x128/apps RENAME ${ICON_NAME}.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/16x16/apps/go-for-it-symbolic.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/16x16/apps RENAME ${ICON_NAME}-symbolic.svg)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/24x24/apps/go-for-it-symbolic.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/apps RENAME ${ICON_NAME}-symbolic.svg)

if (ICON_UPDATE)
install (
    CODE "message (STATUS \"Updating icon cache in ${SYSTEM_DEFAULT_THEME}\")"
    CODE "execute_process (COMMAND gtk-update-icon-cache -t -f ${SYSTEM_DEFAULT_THEME})"
)
endif (ICON_UPDATE)

# configure and install the gsettings schemas
configure_file (go-for-it.gschema.xml.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.gschema.xml)
include(GSettings)
add_schema("${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.gschema.xml")

# install notification sounds
set (SOUND_FOLDER ${PKGDATADIR}/sounds)
set (SOUND_SOURCE_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/sounds)
install (
FILES
    ${SOUND_SOURCE_FOLDER}/bell.ogg
    ${SOUND_SOURCE_FOLDER}/loud-bell.ogg
    ${SOUND_SOURCE_FOLDER}/singing-bowl.ogg
    ${SOUND_SOURCE_FOLDER}/steel-bell.ogg
DESTINATION
    ${SOUND_FOLDER}
)
