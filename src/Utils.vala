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
    public enum FeatureStatus {
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
                string icon_name, ...) {
            Gtk.Image result = new Gtk.Image.from_icon_name (icon_name, size);
            // If icon_name is present, simply return the related image
            if (Gtk.IconTheme.get_default ().has_icon (icon_name)) {
                return result;
            }

            // Iterate through the list of fallbacks, if icon_name was not found
            var fallbacks = va_list();
            while (true) {
                string? fallback_name = fallbacks.arg();
                if (fallback_name == null) {
                    // end of the varargs list without a matching fallback
                    // in this case the "broken image" icon is returned
                    return result;
                }

                // If fallback is found, return the related image
                if (Gtk.IconTheme.get_default ().has_icon (fallback_name)) {
                    return new Gtk.Image.from_icon_name (fallback_name, size);
                }
            }
        }
    }
}
