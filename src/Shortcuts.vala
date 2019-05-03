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
    namespace Shortcuts {
        const uint[] FILTER = {Gdk.Key.Control_L, Gdk.Key.F};
        const uint[] NEW = {Gdk.Key.Control_L, Gdk.Key.N};
        const uint[] TIMER = {Gdk.Key.Control_L, Gdk.Key.P};
        const uint[] TASK_DONE = {Gdk.Key.Control_L, Gdk.Key.Return};
        const uint[] ROW_MOVE_UP = {Gdk.Key.Control_L, Gdk.Key.K};
        const uint[] ROW_MOVE_DOWN = {Gdk.Key.Control_L, Gdk.Key.J};
        const uint[] SWITCH_PAGE_LEFT = {Gdk.Key.Shift_L, Gdk.Key.J};
        const uint[] SWITCH_PAGE_RIGHT = {Gdk.Key.Shift_L, Gdk.Key.K};
        const uint[] NEXT_TASK = {Gdk.Key.K};
        const uint[] PREV_TASK = {Gdk.Key.J};

        public static string? key_to_accel (uint key) {
            switch (key) {
                case Gdk.Key.Control_L:
                    return "<Control>";
                case Gdk.Key.Shift_L:
                    return "<Shift>";
                case Gdk.Key.Alt_L:
                    return "<Alt>";
                default:
                    return Gdk.keyval_name (key);
            }
        }

        public static string? key_to_label_str (uint key) {
            switch (key) {
                case Gdk.Key.Control_L:
                    return "Ctrl";
                case Gdk.Key.Shift_L:
                    return "Shift";
                case Gdk.Key.Alt_L:
                    return "<Alt>";
                case Gdk.Key.Return:
                    return "Enter"; // Most keyboards have Enter printed on the key
                default:
                    return Gdk.keyval_name (key);
            }
        }

        public static string to_accel (uint[] keys) {
            var result = "";
            foreach (var key in keys) {
                result += key_to_accel (key);
            }
            return result;
        }
    }
}
