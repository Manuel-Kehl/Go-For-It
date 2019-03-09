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

        public static Theme from_string (string str) {
            switch (str) {
                case "elementary":
                    return ELEMENTARY;
                case "minimal":
                    return MINIMAL;
                default:
                    return INVALID;
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
                    return _("Inherit from Gtk theme");
                default:
                    assert_not_reached();
            }
        }

        public static Theme[] all () {
            return {ELEMENTARY, MINIMAL};
        }

        public string get_palette (bool dark_variant) {
            switch (this) {
                case ELEMENTARY:
                    return dark_variant ? "elementary-dark" : "elementary";
                case MINIMAL:
                    return "theme-based";
                default:
                    assert_not_reached();
            }
        }

        public string get_stylesheet () {
            switch (this) {
                case ELEMENTARY:
                    return "widgets";
                case MINIMAL:
                    return "widgets-minimal";
                default:
                    assert_not_reached();
            }
        }
    }
}
