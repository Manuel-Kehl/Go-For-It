# Change Log

## [1.9.4](https://github.com/JMoerman/Go-For-It/tree/1.9.4) (2021-09-15)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.9.3...1.9.4)

**_Go For It!_ has been renamed to _GoForIt!_**

Searching for _Go For It!_ generally doesn't yield usable results. For example, AppStream tools remove common words and as `go`, `for`, and `it` are all common words when searching for `go for it` the entire search string gets discarded.
Though it probably still isn't a _great_ name, _GoForIt!_ doesn't have this issue.

**Implemented enhancements:**

- Update various translations (Hebrew, Persian, Portuguese, Spanish).

**Fixed bugs:**

- A few widgets wouldn't be freed after closing the settings dialog.

## [1.9.3](https://github.com/JMoerman/Go-For-It/tree/1.9.3) (2021-08-20)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.9.2...1.9.3)

**Implemented enhancements:**

- Update various translations (Arabic, Bulgarian, Catalan, Croatian, Czech, Danish, Esperanto, German, Hebrew, Italian, Japanese, Lithuanian, Portuguese, Russian, Slovak, Swedish, Turkish, Urdu).

## [1.9.2](https://github.com/JMoerman/Go-For-It/tree/1.9.2) (2021-03-08)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.9.1...1.9.2)

**Implemented enhancements:**

- Added a keyboard shortcut (Ctrl + Q) to close the application.

**Fixed bugs:**

- _Go For It!_ would give an error when trying to save a todo.txt list on an SMB share. _Go For It!_ still won't let you pick such a file as it cannot mount SMB shares itself.

## [1.9.1](https://github.com/JMoerman/Go-For-It/tree/1.9.1) (2021-02-22)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.9.0...1.9.1)

**Implemented enhancements:**

- For each list, You can now select wether you would like to log creation dates to the todo.txt files.
- It should now be easier to edit list properties for touchscreen users.

**Fixed bugs:**

- At startup the "return to list" (->) button could use the wrong icon, depending on the icon theme.
- The menu button would be blurry on Adwaita.

## [1.9.0](https://github.com/JMoerman/Go-For-It/tree/1.9.0) (2020-12-09)

_Go For It!_ now no longer (directly) uses key files to store its settings. GLib.Settings is now used for this purpose (of which the default backend is often DConf). I'm not aware of any project that reads or modifies the old configuation files of _Go For It!_, so I don't expect this to cause any issues. Old settings still get imported into the new version, of course.

The .desktop files, appstream metadata and icon names are now always based on the application ID (`com.github.jmoerman.go-for-it` by default). This means that if `-DAPP_SYSTEM_NAME="something"` was previously used to compile _Go For It!_ you may notice that pinned desktop shortcuts to _Go For It!_ may disappear after upgrading. _Go For It!_ previously used libnotify to send notifications and compensated for cases where the desktop file did not match the application ID by supplying the name of the .desktop file as `desktop-entry` hint. GLib's notification API does not appear to have an option to do something similar.

_Go For It!_ is now split in a library and an application part (with nearly all code in the library part) so make sure that `CMAKE_INSTALL_FULL_LIBDIR` is in your library path. Supplying `-DCMAKE_INSTALL_PREFIX=/usr` as cmake argument will work in most cases.

**Implemented enhancements:**

- It is now possible to manually select todo.txt files for the task lists instead of selecting the folder to store those in. It is now also no longer necessary to have a separate todo.txt file for archiving completed tasks.
- For each list, it is now possible to select a CSV file to log your activity to.
- When logging activity to a new CSV file a header describing the column contents is added.
- _Go For It!_ can now play a sound when it is time to take a break or when it is time to start working again.
- _Go For It!_ now supports plugins. The plugins that are currently available are 2 plugins to show the remaining time, one for panels supporting Ayatana appindicators and another for docks/launchers supporting the LauncherEntry API. The plugin API is currently fairly limited and subject to change.
- _Go For It!_ can now use the Granite framework as an optional build-time dependency. The main advantage is that, on elementary OS 6, this will allow _Go For It!_ to follow the global dark style setting.
- Most tooltips now include the shortcut alternative to clicking the widget.
- The option to select an application stylesheet has been removed. The automatically selected stylesheet should work for all reasonable Gtk+ 3.0 themes (Raleigh and win32 are examples of broken stylesheets).
- The layout of the settings dialogs has been improved.
- Tasks rows are now vertically aligned using the baselines of the widgets.
- Moving tasks around using drag-and-drop now looks better. The point at which the task would be inserted is now shown by reserving space for that task instead of just showing a stripe between the 2 rows where it would get inserted.

**Fixed bugs:**

- Popovers now use the same margins as GNOME apps unless the Granite dependency is used.
- Some popover styling issues that occurred when using one of the io.elementary.stylesheet.* Gtk themes have been fixed.
- CSV output is no longer separated by both a comma and space, but just by commas.
- The menu entries for sorting tasks or clearing the list of completed tasks is now only shown if a task list is shown.

## [1.8.7](https://github.com/JMoerman/Go-For-It/tree/1.8.7) (2020-11-22)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.8.6...1.8.7)

**Implemented enhancements:**

- The default application stylesheet is now by default determined at runtime. The minimal "Inherit from GTK theme" stylesheet will now be used when a theme other than Adwaita or elementary is used.
- A large number of translations have been updated. New translations include Danish and Hebrew.

**Fixed bugs:**

- The placeholder tasks shown when creating a new list for the first time are no longer invisible.

## [1.8.6](https://github.com/JMoerman/Go-For-It/tree/1.8.6) (2020-10-07)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.8.4...1.8.6)

**Implemented enhancements:**

- The option to pick themes is no longer shown when using the elementary Gtk3 theme as the "Inherit from GTK theme" application theme doesn't look right in combination with this.
- Arabic translations have been updated.

## [1.8.4](https://github.com/JMoerman/Go-For-It/tree/1.8.4) (2020-10-04)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.8.3...1.8.4)

**Fixed bugs:**

- The shortcuts for moving tasks up or down now work correctly.

**Implemented enhancements:**

- A symbolic icon variant has been added for both the logo and the checkmark icons.
- Various translations have been updated (Arabic, Croatian, Dutch, French, German, Italian, Norwegian Bokmål, Slovak, Turkish). (Most of the changes will not apply to this version, however.)

## [1.8.3](https://github.com/JMoerman/Go-For-It/tree/1.8.3) (2020-09-26)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.8.2...1.8.3)


**Fixed bugs:**

- Fixed an issue that would cause _Go For It!_ to crash when clearing the description of a task.
- Fixed several minor memory leaks.

## [1.8.2](https://github.com/JMoerman/Go-For-It/tree/1.8.2) (2020-09-20)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.8.1...1.8.2)

**Implemented enhancements:**

- When switching to list overview, the previously shown list will now be selected.
- Various translations have been updated (Croatian, French, German, Norwegian Bokmål, Polish, Portuguese, Slovak, Turkish).

## [1.8.1](https://github.com/JMoerman/Go-For-It/tree/1.8.1) (2020-07-20)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.8.0...1.8.1)

**Fixed bugs:**

- The command line help now correctly shows `--load LIST-TYPE LIST-ID` instead of `--load=LIST-TYPE LIST-ID`.
- The active task did not properly refresh when pausing the timer after switching lists and interacting with the to-do list.

**Implemented enhancements:**

- When using `--logfile=~/something`: `~` is now expanded.
- The translations for Central Kurdish, Lithuanian and Portuguese (Brazil) have been updated.

## [1.8.0](https://github.com/JMoerman/Go-For-It/tree/1.8.0) (2020-06-27)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.7.2...1.8.0)

**Implemented enhancements:**

- Introduces configurable shortcuts.
- A custom drag handle icon is now used instead of the "view-list" icon.
- Introduces an option to log the time spent working on a task (using the timer) to the todo.txt files.
- _Go For It!_ now highlights the task you are currently working on with ⏰.
- Changing the system clock or suspending your system will no longer affect the timer.
- It is now possible to tell _Go For It!_ how long a task should take by adding `duration:Xh-Ym` to the description of a task. (Where X and Y are the number of hours and minutes respectively. For a five minute task one would need to add `duration:5m`.) _Go For It!_ will notify you when you exceed this duration. (Do not forget to enable timer logging so _Go For It!_ will know how much time you have spent working on a task after closing the application!)
- Not every break (or time between breaks) has to be of the same length: You can now use _Go For It!_ as a pomodoro timer or use a custom timer schedule.
- Added an option to add new tasks at the start of each list instead of appending them to the end.
- Added `--list` and `--load <id>` arguments to show the configured lists and load a specified list respectively.
- Experimental: It is now possible to log your activities to a csv file by starting _Go For It!_ with `--logfile <filename>`.
- Many translations were updated.

## [1.7.3](https://github.com/JMoerman/Go-For-It/tree/1.7.3) (2019-08-26)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.7.2...1.7.3)

This release contains some fixes and translation updates from the development branch.

**Fixed bugs:**

- Work around a ListBox bug which could cause situations where no row is selected even though suitable rows exist.
- Keep the row focussed when the user stops editing a row.

**Implemented enhancements:**

- Escape now cancels the editing of a task.
- The following translations were updated: Turkish, German, Norwegian Bokmål, Japanese, Polish, Telugu.

## [1.7.2](https://github.com/JMoerman/Go-For-It/tree/1.7.2) (2019-04-25)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.7.1...1.7.2)

**Implemented enhancements:**

- Switched to weblate for translations.
- Introduced sorting by priority.
- The following translations were updated: Portuguese, Spanish, Lithuanian, Korean, Norwegian Bokmål.
- The ctrl+n shortcut was added to quickly create new tasks or lists.

## [1.7.1](https://github.com/JMoerman/Go-For-It/tree/1.7.1) (2019-03-18)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.7.0...1.7.1)

**Implemented enhancements:**

- The application id can now be set with -DAPP\_ID=some\_id

**Fixed bugs:**

- For some widgets _Go For It!_ did not properly load a fallback icon.

## [1.7.0](https://github.com/JMoerman/Go-For-It/tree/1.7.0) (2019-03-16)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.10...1.7.0)

**Implemented enhancements:**

- You can now have more than one to-do list.
- The application design has been updated. The application now uses less vertical space if a headerbar is used.
- The default stylesheet has been improved, resulting in improved looks when the application is used on elementary OS.
- Not using the elementary or Adwaita theme, or a theme with a similar color scheme? You can now select a different stylesheet in the settings window.
- The location from which the stylesheet is loaded is now determined by the installation directory.

**Fixed bugs:**

- _Go For It!_ now properly exports that it uses notifications.
- Non ascii character were not properly parsed when parsing contexts and projects.

**Closed issues:**

- Place tabs in same place as menu button [\#5](https://github.com/JMoerman/Go-For-It/issues/5), [\#49](https://github.com/JMoerman/Go-For-It/issues/49)
- context with wide characters not highlighted [\#68](https://github.com/JMoerman/Go-For-It/issues/68)
- Custom CSS is not working well outside of default Elementary OS gtk theme [\#66](https://github.com/JMoerman/Go-For-It/issues/66)
- Feature suggestion [\#54](https://github.com/JMoerman/Go-For-It/issues/54)

## [1.6.10](https://github.com/JMoerman/Go-For-It/tree/1.6.10) (2019-02-13)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.9...1.6.10)

**Fixed bugs:**

- Pressing delete while editing a task description would remove the task instead of removing a character.

**Implemented enhancements:**

- Updated french translations.

**Closed issues:**

- Hitting Delete button in edit mode removes the task from the list [\#67](https://github.com/JMoerman/Go-For-It/issues/67)

**Merged pull requests:**

- Add French translations [\#62](https://github.com/JMoerman/Go-For-It/pull/62) ([NathanBnm](https://github.com/NathanBnm))

## [1.6.9](https://github.com/JMoerman/Go-For-It/tree/1.6.9) (2018-12-02)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.8...1.6.9)

**Fixed bugs:**

- Editing tasks was a bit finicky for certain Gtk+ 3 versions. Editing should now never be aborted immediately.

**Implemented enhancements:**

- Tasks can now be removed by pressing the delete key or by clicking a new delete button while editing a task.

**Closed issues:**

- How to delete tasks in todo [\#59](https://github.com/JMoerman/Go-For-It/issues/59)

## [1.6.8](https://github.com/JMoerman/Go-For-It/tree/1.6.8) (2018-10-16)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.7...1.6.8)

**Fixed bugs:**

- The application menu was not alligned correctly on Juno and likely other modern distribution releases.
- The use of a global dark theme no longer impacts the themeing of _Go For It!_, while it used to affect a part of the application. (Use the settings dialog if you want to use a dark theme.)

**Closed issues:**

- Application does not support dark theme [\#57](https://github.com/JMoerman/Go-For-It/issues/57)
- Popup menu may not align correctly on Gtk-3.22+ [\#58](https://github.com/JMoerman/Go-For-It/issues/58)

## [1.6.7](https://github.com/JMoerman/Go-For-It/tree/1.6.7) (2018-10-05)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.6...1.6.7)

**Implemented enhancements:**

- Added minimal support for creation and completion dates as well as the priority of a task.
- The creation and completion dates are stored for new tasks.

**Fixed bugs:**

- Dragging a selected task could cause the timer to state that all tasks are finished.

**Closed issues:**

- Priority [\#12](https://github.com/JMoerman/Go-For-It/issues/12)
- Dates [\#17](https://github.com/JMoerman/Go-For-It/issues/17)

**Merged pull requests:**

- Add dates to the written files #56 [\#56](https://github.com/JMoerman/Go-For-It/pull/56) ([daniellandau](https://github.com/daniellandau))

## [1.6.6](https://github.com/JMoerman/Go-For-It/tree/1.6.6) (2018-04-17)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.5...1.6.6)

**Implemented enhancements:**

- The following translation is updated: Lithuanian
- Minor documentation improvements

## [1.6.5](https://github.com/JMoerman/Go-For-It/tree/1.6.5) (2018-02-26)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.4...1.6.5)

**Fixed bugs:**

- Strings containing whitespace consisting of multiple spaces were not parsed correctly, which could lead to crashes.

**Closed issues:**

- Crashes when there's a double space before project tag [mank319/\#127](https://github.com/mank319/Go-For-It/issues/127)

## [1.6.4](https://github.com/JMoerman/Go-For-It/tree/1.6.4) (2018-01-04)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.3...1.6.4)

**Implemented enhancements:**

- The task list and the rest of the main application window now have the same background color.
- The following translations are updated: Czech, Japanese, Spanish.

**Closed issues:**

- Colors between listview and rest of the app window are not consistent [\#50](https://github.com/JMoerman/Go-For-It/issues/50)

## [1.6.3](https://github.com/JMoerman/Go-For-It/tree/1.6.3) (2017-11-10)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/1.6.2...1.6.3)

**Implemented enhancements:**

- The CMake script now checks if intltool-merge is present.
- The following translations are updated: Lithuanian, Dutch, French (new).
- The about dialog and contribute dialog can disabled at compile time. (Useful if that information is better shown in the appstream metadata.)
- The system name (name of data and executable) can now be specified at compile time.

**Closed issues:**

- Add an option to build a version without contribute/donation dialog [\#42](https://github.com/JMoerman/Go-For-It/issues/42)
- Do not show about dialog in menu and .desktop when installed via store? [\#43](https://github.com/JMoerman/Go-For-It/issues/43)
- Do not show header bar toggle when used on Pantheon/Gnome/... [\#41](https://github.com/JMoerman/Go-For-It/issues/41)

**Merged pull requests:**

- French translation [\#44](https://github.com/JMoerman/Go-For-It/pull/44) ([nvivant](https://github.com/nvivant))

## [1.6.2](https://github.com/JMoerman/Go-For-It/tree/1.6.2) (2017-10-28)
[Full Changelog](https://github.com/JMoerman/Go-For-It/compare/release_v1.6.1...1.6.2)

**Implemented enhancements:**

- Reverse Domain Name Notation is now used for filenames (application data, executables).
- An appstream appdata.xml metadata file has been added.
- The following translations are updated: Lithuanian.

**Fixed bugs:**

- Parsed command line strings would not get freed.
- Changing the path to the stored todo.txt files would lead to a crash when a task is marked as done.

**Merged pull requests:**

- Add appdata file [mank319/\#123](https://github.com/mank319/Go-For-It/pull/123) ([AsavarTzeth](https://github.com/AsavarTzeth))
- Add flatpak instructions and fix archlinux [mank319/\#124](https://github.com/mank319/Go-For-It/pull/124) ([AsavarTzeth](https://github.com/AsavarTzeth))

## [1.6.1](https://github.com/mank319/Go-For-It/tree/release_v1.6.1) (2017-10-15)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_v1.6...release_v1.6.1)

**Implemented enhancements:**

- Granite.Widgets.About is used instead of Gtk.AboutDialog when Granite is available, this may be reverted later on when _Go For It!_ will be available on the elementary OS appcenter.
- The following translations are updated: Dutch, Brazillian Portugese, German, Czech.

**Fixed bugs:**

- The minimum required version of Gtk+-3.0 is increased to 3.14 in the CMake scripts and readme. This used to be 3.10, but it would not build with versions lower than 3.10.

**Merged pull requests:**

- Finished translation: Brazilian Portuguese [mank319/\#120](https://github.com/mank319/Go-For-It/pull/120) ([gustavohmsilva](https://github.com/gustavohmsilva))

## [1.6.0](https://github.com/mank319/Go-For-It/tree/release_v1.6) (2017-10-02)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_v1.5...release_v1.6)

**Implemented enhancements:**

- Tasks can be filtered by clicking on a project or context tag, or manually with the ctrl+f key combination.

**Fixed bugs:**

- Crashes on start if ~/.todo already exists and is a file [mank319/\#111](https://github.com/mank319/Go-For-It/issues/111)
- Drag area disappears on all items if one item is too long [mank319/\#60](https://github.com/mank319/Go-For-It/issues/60)
- _Go For It!_ doesn't build with more recent valac versions, caused part of the issues described in  [mank319/\#116](https://github.com/mank319/Go-For-It/issues/116)

**Closed issues:**

- Task name wrapping [mank319/\#65](https://github.com/mank319/Go-For-It/issues/65)

**Merged pull requests:**

- Option to override icon cache update [mank319/\#117](https://github.com/mank319/Go-For-It/pull/117) ([nick87720z](https://github.com/nick87720z))

**Dependency changes:**

- _Go For It!_ now depends on Gtk+-3.0 >= 3.14

## [1.5.0](https://github.com/mank319/Go-For-It/tree/release_v1.5) (2016-12-18)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_v1.4.7...release_v1.5)

**Implemented enhancements:**

- _Go For It!_ now has an option to use the dark theme variant.
- Translation support has been added in this release

**Fixed bugs:**

- No icon on XFCE [mank319/\#67](https://github.com/mank319/Go-For-It/issues/67)

**Closed issues:**

- German Translation [mank319/\#96](https://github.com/mank319/Go-For-It/issues/96)
- Dark theme [mank319/\#94](https://github.com/mank319/Go-For-It/issues/94)
- Translation to Spanish [mank319/\#92](https://github.com/mank319/Go-For-It/issues/92)
- Compiling problem [mank319/\#80](https://github.com/mank319/Go-For-It/issues/80)

**Merged pull requests:**

- Fixes \#67 [mank319/\#97](https://github.com/mank319/Go-For-It/pull/97) ([bil-elmoussaoui](https://github.com/bil-elmoussaoui))

## [1.4.7 (re release)](https://github.com/mank319/Go-For-It/tree/release_v1.4.7) (2016-11-22)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_1.4.6...release_v1.4.7)

Re release of 1.4.7, the CMake install script did not install the .desktop file, this is fixed in this release.

## [1.4.7](https://github.com/mank319/Go-For-It/tree/release_1.4.7) (2016-08-21)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_1.4.6...release_1.4.7)

**Implemented enhancements:**

- _Go For It!_ now supports Gtk+-3.0 versions older than v3.10.

**Fixed bugs:**

- Active Task name is not updated with task renaming [mank319/\#88](https://github.com/mank319/Go-For-It/issues/88)
- Bug on first run: endless loop of "support go for it" in list [mank319/\#83](https://github.com/mank319/Go-For-It/issues/83)

**Closed issues:**

- Add build dependencies to the readme [mank319/\#91](https://github.com/mank319/Go-For-It/issues/91)
- UBUNTU 16.04 support [mank319/\#87](https://github.com/mank319/Go-For-It/issues/87)
- PPA doesn't work in Ubuntu 16.04 [mank319/\#86](https://github.com/mank319/Go-For-It/issues/86)
- Support Gtk \< 3.10 [mank319/\#30](https://github.com/mank319/Go-For-It/issues/30)
