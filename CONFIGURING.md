# Configuration options

This information will not be useful to most end users.
The options documented here can, however be useful for package maintainers in making *Go For It!* integrate better with the target operating system.

## Cmake build flags

The following options can be supplied either as command line parameter or by using a GUI for cmake.

### Setting the system name
By default *Go For It!* uses reverse domain notation for its files (executable name, name of the directory data is stored in, name of the configuration directory, ...), this means that the application is installed as com.github.jmoerman.go-for-it.
In case a different naming scheme is used on the target operating system or another naming scheme was used previously, the name of these files and directories can be changed by changing the system name.

The system name can be set to `new-name` by appending `-DAPP_SYSTEM_NAME:STRING=new-name` to the cmake build command.

For example:

```
cmake -DCMAKE_INSTALL_PREFIX=/usr -DAPP_SYSTEM_NAME:STRING=go-for-it ..
make
sudo make install
```

In this case *Go For It!* would be installed as `/usr/bin/go-for-it`, `/usr/share/applications/go-for-it.desktop`, etc...

### Setting the application id
The application id can be set by appending `-DAPP_ID:STRING=new-id` to the cmake build command.
The default value of `APP_SYSTEM_NAME` is based on `APP_ID` meaning that, asuming a clean build, setting the application id will have a similar effect to changing the system name.

For example:

```
cmake -DCMAKE_INSTALL_PREFIX=/usr -DAPP_ID=test.go-for-it ..
make
sudo make install
```

### Removing the contribute dialog
By default *Go For It!* includes a contribute dialog.
In cases where the information present in this dialog is also provided by other sources such as the elementary OS AppCenter results for *Go For It!* it may be desirable to leave out this dialog.

This can be accomplished by appending `-DNO_CONTRIBUTE_DIALOG:BOOL="1"` to the cmake build command.

For example:

```
cmake -DCMAKE_INSTALL_PREFIX=/usr -DNO_CONTRIBUTE_DIALOG:BOOL="1" ..
make
sudo make install
```

### Removing references to the about dialog
By default it is possible to view the about dialog of *Go For It!* via a menu option or by activating an action present in the .desktop file.
If this information is easily accessible elsewhere it may be desirable to decrease clutter by these actions.

This can be accomplished by appending `-DSHOW_ABOUT:BOOL="0"` to the cmake build command.

For example:

```
cmake -DCMAKE_INSTALL_PREFIX=/usr -DSHOW_ABOUT:BOOL="0" ..
make
sudo make install
```

### gtk-update-icon-cache
By default `gtk-update-icon-cache` will run after installing the icons, .desktop file and appdata metadata.
This may not be desirable if `make install` is used to generate an installation package like a .deb file.

gtk-update-icon-cache will not run if `-DICON_UPDATE:BOOL="0"` is appended to the cmake build command.

### Building unit tests
For some of the classes used in *Go For It!* unit tests can be build and run.

Unit tests can be enabled by appending `-DBUILD_TESTS:BOOL="1"` to the cmake build command.

This will result in a testing binary located in `<build directory>/tests/`.
