# Change Log

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

- Add appdata file [\#123](https://github.com/mank319/Go-For-It/pull/123) ([AsavarTzeth](https://github.com/AsavarTzeth))
- Add flatpak instructions and fix archlinux [\#124](https://github.com/mank319/Go-For-It/pull/124) ([AsavarTzeth](https://github.com/AsavarTzeth))

## [1.6.1](https://github.com/mank319/Go-For-It/tree/release_v1.6.1) (2017-10-15)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_v1.6...release_v1.6.1)

**Implemented enhancements:**

- Granite.Widgets.About is used instead of Gtk.AboutDialog when Granite is available, this may be reverted later on when _Go For It!_ will be available on the elementary OS appcenter.
- The following translations are updated: Dutch, Brazillian Portugese, German, Czech.

**Fixed bugs:**

- The minimum required version of Gtk+-3.0 is increased to 3.14 in the CMake scripts and readme. This used to be 3.10, but it would not build with versions lower than 3.10.

**Merged pull requests:**

- Finished translation: Brazilian Portuguese [\#120](https://github.com/mank319/Go-For-It/pull/120) ([gustavohmsilva](https://github.com/gustavohmsilva))

## [1.6.0](https://github.com/mank319/Go-For-It/tree/release_v1.6) (2017-10-02)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_v1.5...release_v1.6)

**Implemented enhancements:**

- Tasks can be filtered by clicking on a project or context tag, or manually with the ctrl+f key combination.

**Fixed bugs:**

- Crashes on start if ~/.todo already exists and is a file [\#111](https://github.com/mank319/Go-For-It/issues/111)
- Drag area disappears on all items if one item is too long [\#60](https://github.com/mank319/Go-For-It/issues/60)
- _Go For It!_ doesn't build with more recent valac versions, caused part of the issues described in  [\#116](https://github.com/mank319/Go-For-It/issues/116)

**Closed issues:**

- Task name wrapping [\#65](https://github.com/mank319/Go-For-It/issues/65)

**Merged pull requests:**

- Option to override icon cache update [\#117](https://github.com/mank319/Go-For-It/pull/117) ([nick87720z](https://github.com/nick87720z))

**Dependency changes:**

- _Go For It!_ now depends on Gtk+-3.0 >= 3.14

## [1.5.0](https://github.com/mank319/Go-For-It/tree/release_v1.5) (2016-12-18)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_v1.4.7...release_v1.5)

**Implemented enhancements:**

- _Go For It!_ now has an option to use the dark theme variant.
- Translation support has been added in this release

**Fixed bugs:**

- No icon on XFCE [\#67](https://github.com/mank319/Go-For-It/issues/67)

**Closed issues:**

- German Translation [\#96](https://github.com/mank319/Go-For-It/issues/96)
- Dark theme [\#94](https://github.com/mank319/Go-For-It/issues/94)
- Translation to Spanish [\#92](https://github.com/mank319/Go-For-It/issues/92)
- Compiling problem [\#80](https://github.com/mank319/Go-For-It/issues/80)

**Merged pull requests:**

- Fixes \#67 [\#97](https://github.com/mank319/Go-For-It/pull/97) ([bil-elmoussaoui](https://github.com/bil-elmoussaoui))

## [1.4.7 (re release)](https://github.com/mank319/Go-For-It/tree/release_v1.4.7) (2016-11-22)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_1.4.6...release_v1.4.7)

Re release of 1.4.7, the CMake install script did not install the .desktop file, this is fixed in this release.

## [1.4.7](https://github.com/mank319/Go-For-It/tree/release_1.4.7) (2016-08-21)
[Full Changelog](https://github.com/mank319/Go-For-It/compare/release_1.4.6...release_1.4.7)

**Implemented enhancements:**

- _Go For It!_ now supports Gtk+-3.0 versions older than v3.10.

**Fixed bugs:**

- Active Task name is not updated with task renaming [\#88](https://github.com/mank319/Go-For-It/issues/88)
- Bug on first run: endless loop of "support go for it" in list [\#83](https://github.com/mank319/Go-For-It/issues/83)

**Closed issues:**

- Add build dependencies to the readme [\#91](https://github.com/mank319/Go-For-It/issues/91)
- UBUNTU 16.04 support [\#87](https://github.com/mank319/Go-For-It/issues/87)
- PPA doesn't work in Ubuntu 16.04 [\#86](https://github.com/mank319/Go-For-It/issues/86)
- Support Gtk \< 3.10 [\#30](https://github.com/mank319/Go-For-It/issues/30)
