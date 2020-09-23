/* Copyright 2014-2017 Go For It! developers
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
 * The GOFI namespace is a central collection of static constants that are
 * related to "Go For It!".
 */
namespace GOFI {

    /**
     * Used to pass information about if a feature is standard on the desktop
     * of the user.
     */
    private enum FeatureStatus {
        UNKNOWN,
        ALWAYS,
        COMMON,
        UNCOMMON,
        NEVER;

        public bool use_feature (bool _default) {
            switch (this) {
                case ALWAYS:
                    return true;
                case COMMON:
                    return true;
                case UNCOMMON:
                    return false;
                case NEVER:
                    return false;
                default:
                    return _default;
            }
        }

        public bool config_useful () {
            switch (this) {
                case ALWAYS:
                    return false;
                case NEVER:
                    return false;
                default:
                    return true;
            }
        }
    }

    /**
     * A collection of static utility functions.
     */
    class Utils {
        /**
         * A convenient way to get the path of the directory where Go For It!
         * stores it's configuration files.
         */
        public static string config_dir {
            owned get {
                string user_config_dir = Environment.get_user_config_dir ();
                return Path.build_filename (user_config_dir, APP_SYSTEM_NAME);
            }
        }

        /**
         * A convenient way to get the path of Go For It!'s configuration file
         */
        public static string config_file {
            owned get {
                return Path.build_filename (config_dir, FILE_CONF);
            }
        }

        /**
         * The path of the config file prior to being installed in its own
         * directory
         */
        public static string old_config_file {
            owned get {
                string user_config_dir = Environment.get_user_config_dir ();
                return Path.build_filename (user_config_dir, FILE_CONF);
            }
        }

        public static string get_module_config_dir (string module_name) {
            return Path.build_filename (config_dir, module_name);
        }

        /**
         * Returns whether headerbars are used by native apps on the desktop
         * environment of the user.
         */
        public static FeatureStatus desktop_hb_status {
            get {
                string desktop = Environment.get_variable ("DESKTOP_SESSION");

                switch (desktop) {
                    case "pantheon":
                        return FeatureStatus.ALWAYS;
                    case "gnome":
                        return FeatureStatus.ALWAYS;
                    case "budgie":
                        return FeatureStatus.ALWAYS;
                    case "ubuntu":
                        return FeatureStatus.UNCOMMON;
                    case "kde":
                        return FeatureStatus.UNCOMMON;
                    case "plasma":
                        return FeatureStatus.UNCOMMON;
                    case "xfce4":
                        return FeatureStatus.UNCOMMON;
                    case "cinnamon":
                        return FeatureStatus.UNCOMMON;
                    case "mate":
                        return FeatureStatus.UNCOMMON;
                    case "": // probably a custom DE or MS Windows
                        return FeatureStatus.UNCOMMON;
                    default:
                        return FeatureStatus.UNKNOWN;
                }
            }
        }

        /**
         * Loads the first icon in the list, which is contained in the
         * active icon theme. This way one can avoid the "broken image" icon
         * by offering a list of fallback icon names.
         */
        public static Gtk.Image load_image_fallback (Gtk.IconSize size,
                string icon_name, ...
        ) {
            var available = get_image_fallback2 (icon_name, va_list ());
            return new Gtk.Image.from_icon_name (available, size);
        }

        /**
         * Returns the name of the first icon available in the current icon
         * theme.
         */
        public static string get_image_fallback (string icon_name, ...) {
            return get_image_fallback2 (icon_name, va_list ());
        }

        private static string get_image_fallback2 (string icon_name, va_list fallbacks) {
            var icon_theme = Gtk.IconTheme.get_default ();
            if (icon_theme.has_icon (icon_name)) {
                return icon_name;
            }

            // Iterate through the list of fallbacks, if icon_name was not found
            while (true) {
                string? fallback_name = fallbacks.arg ();
                if (fallback_name == null) {
                    // end of the varargs list without a matching fallback
                    // in this case icon_name is returned
                    return icon_name;
                }

                // If fallback is found, return its name
                if (icon_theme.has_icon (fallback_name)) {
                    return fallback_name;
                }
            }
        }

        //TODO: printing more than 60 minutes is probably not the best way to handle this
        public static string seconds_to_short_string (uint seconds) {
            return "%u %s".printf (seconds/60, _("min."));
        }

        public static string seconds_to_pretty_string (uint seconds) {
            uint hours, minutes;
            uint_to_time (seconds, out hours, out minutes, null);

            if (hours == 0) {
                return _("%u minutes").printf (minutes);
            }
            return _("%u hours and %u minutes").printf (hours, minutes);
        }

        public static void uint_to_time (uint time_val, out uint hours, out uint minutes, out uint seconds) {
            seconds = time_val % 60;
            time_val = time_val / 60;

            minutes = time_val % 60;
            time_val = time_val / 60;

            hours = time_val;
        }

        public static uint time_to_uint (uint hours, uint minutes, uint seconds) {
            return 3600 * hours + 60 * minutes + seconds;
        }

        public static Gtk.Button create_menu_button (string label) {
            var button = new Gtk.Button.with_label (label);
            button.get_style_context ().add_class ("menuitem");
            return button;
        }

        public static void popover_hide (Gtk.Popover popover) {
#if HAS_GTK322
            popover.popdown ();
#else
            popover.hide ();
#endif
        }

        public static void popover_show (Gtk.Popover popover) {
#if HAS_GTK322
            popover.forall ((child) => {
                child.show_all ();
            });
            popover.popup ();
#else
            popover.show_all ();
#endif
        }
    }
}
