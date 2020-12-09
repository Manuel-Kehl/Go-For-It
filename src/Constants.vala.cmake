/* Copyright 2014-2020 Go For It! developers
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* Go For It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Go For It!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * This file contains a central collection of static constants that are
 * related to "Go For It!".
 * Constants.vala should not be edited as it will be overwritten by the build
 * system.
 */
namespace GOFI {
    /* Strings */
    public const string APP_NAME = "@APP_NAME@";
    public const string EXEC_NAME = "@EXEC_NAME@";
    public const string APP_SYSTEM_NAME = "@APP_SYSTEM_NAME@";
    public const string APP_ID = "@APP_ID@";
    public const string ICON_NAME = "@ICON_NAME@";
    public const int MAJOR_VERSION = @MAJOR_VERSION@;
    public const int MINOR_VERSION = @MINOR_VERSION@;
    public const int MICRO_VERSION = @MICRO_VERSION@;
    const string FILE_CONF = "@FILE_CONF@";
    const string PROJECT_WEBSITE = "@PROJECT_WEBSITE@";
    const string PROJECT_REPO = "@PROJECT_REPO@";
    const string PROJECT_DONATIONS = "@PROJECT_DONATIONS@";
    const string INSTALL_PREFIX = "@INSTALL_PREFIX@";
    const string DATADIR = "@PKGDATADIR@";
    const string PLUGINDIR = "@PLUGINDIR@";
    const string GETTEXT_PACKAGE = "@GETTEXT_PACKAGE@";
    const string DEFAULT_THEME = "@DEFAULT_THEME@";
    const string RESOURCE_PATH = "@RESOURCE_PATH@";
    const string SCHEMA_PATH = "@SCHEMA_PATH@";

    public static string get_app_name () {
        return APP_NAME;
    }

    public static string get_app_id () {
        return APP_ID;
    }

    public static int get_major_version () {
        return MAJOR_VERSION;
    }

    public static int get_minor_version () {
        return MINOR_VERSION;
    }

    public static int get_micro_version () {
        return MICRO_VERSION;
    }

    public static string get_version_str () {
        return "%i.%i.%i".printf (MAJOR_VERSION, MINOR_VERSION, MICRO_VERSION);
    }

    public static string[] get_default_todos () {
        return {
            _("Spread the word about \"%s\"").printf (APP_NAME),
            _("Consider a donation to help the project"),
            _("Consider contributing to the project")
        };
    }
}
