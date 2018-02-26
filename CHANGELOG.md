# Change Log

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
