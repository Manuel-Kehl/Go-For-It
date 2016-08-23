# install .desktop file so the Applications menu will display it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/go-for-it.desktop DESTINATION ${DATADIR}/applications/)

# install the application's icons
set(SYSTEM_DEFAULT_THEME ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/16x16/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/16x16/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/24x24/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/32x32/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/32x32/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/48x48/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/48x48/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/64x64/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/64x64/apps)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/128x128/apps/go-for-it.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/128x128/apps)
# install the fallback menu icon
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/24x24/actions/go-for-it-open-menu-fallback.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/actions)


install(
    CODE
    "execute_process (COMMAND gtk-update-icon-cache -t -f ${SYSTEM_DEFAULT_THEME})"
    CODE
    "message (STATUS \"Updated icon cache in ${SYSTEM_DEFAULT_THEME}\")"
    )
