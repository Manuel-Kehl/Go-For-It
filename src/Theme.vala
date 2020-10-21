/* Copyright 2019 Go For It! developers
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

namespace GOFI {
    enum Theme {
        INVALID,
        ELEMENTARY,
        MINIMAL;

        private static Theme determine_from_desktop_theme () {
            var desktop_theme_name = Gtk.Settings.get_default ().gtk_theme_name;
            if (desktop_theme_name == "elementary" || desktop_theme_name == "Adwaita") {
                return ELEMENTARY;
            }
            return MINIMAL;
        }

        public static Theme from_string (string str) {
            switch (str) {
                case "elementary":
                    return ELEMENTARY;
                case "minimal":
                    return MINIMAL;
                case "":
                    return determine_from_desktop_theme ();
                default:
                    return INVALID;
            }
        }

        public static Theme from_string_safe (string str) {
            var parsed = from_string (str);
            switch (parsed) {
                case INVALID:
                    return determine_from_desktop_theme ();
                default:
                    return parsed;
            }
        }

        public string to_string () {
            switch (this) {
                case ELEMENTARY:
                    return "elementary";
                case MINIMAL:
                    return "minimal";
                default:
                    assert_not_reached();
            }
        }

        /**
         * Translatable descriptive names
         */
        public string to_theme_description () {
            switch (this) {
                case ELEMENTARY:
                    return "elementary";
                case MINIMAL:
                    return _("Inherit from GTK theme");
                default:
                    assert_not_reached();
            }
        }

        public static Theme[] all () {
            return {ELEMENTARY, MINIMAL};
        }

        public string get_stylesheet (bool dark_variant) {
            switch (this) {
                case ELEMENTARY:
                    if (dark_variant) {
                        return "elementary-dark";
                    } else {
                        return "elementary";
                    }
                case MINIMAL:
                    return "widgets-minimal";
                default:
                    assert_not_reached();
            }
        }
    }
}
