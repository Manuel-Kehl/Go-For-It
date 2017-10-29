configure_file(go-for-it.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.desktop)
configure_file(go-for-it.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.appdata.xml)

# install .desktop file so the Applications menu will display it
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.desktop DESTINATION ${DATADIR}/applications/)

# install appdata file which provides metadata for software centers
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${APP_ID}.appdata.xml DESTINATION ${DATADIR}/metainfo/)

# install the application's icons
set(SYSTEM_DEFAULT_THEME ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)
set(ICON_FOLDER /icons/hicolor)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/16x16/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/16x16/apps RENAME ${ICON_NAME}.svg)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/24x24/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/apps RENAME ${ICON_NAME}.svg)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/32x32/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/32x32/apps RENAME ${ICON_NAME}.svg)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/48x48/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/48x48/apps RENAME ${ICON_NAME}.svg)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/64x64/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/64x64/apps RENAME ${ICON_NAME}.svg)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/128x128/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/128x128/apps RENAME ${ICON_NAME}.svg)
# install the fallback menu icon
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}${ICON_FOLDER}/24x24/actions/go-for-it-open-menu-fallback.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/actions RENAME ${ICON_NAME}-open-menu-fallback.svg)

option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)

if (ICON_UPDATE)
install(
    CODE "message (STATUS \"Updating icon cache in ${SYSTEM_DEFAULT_THEME}\")"
    CODE "execute_process (COMMAND gtk-update-icon-cache -t -f ${SYSTEM_DEFAULT_THEME})"
    )
endif (ICON_UPDATE)
