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
        const int[] FILTER = {Gdk.Key.Control_L, Gdk.Key.F};
        const int[] NEW = {Gdk.Key.Control_L, Gdk.Key.N};
        const int[] TIMER = {Gdk.Key.Control_L, Gdk.Key.P};
        const int[] TASK_DONE = {Gdk.Key.Control_L, Gdk.Key.Return};
        const int[] ROW_MOVE_UP = {Gdk.Key.Control_L, Gdk.Key.K};
        const int[] ROW_MOVE_DOWN = {Gdk.Key.Control_L, Gdk.Key.J};
        const int[] SWITCH_PAGE_LEFT = {Gdk.Key.Shift_L, Gdk.Key.K};
        const int[] SWITCH_PAGE_RIGHT = {Gdk.Key.Shift_L, Gdk.Key.J};
        const int[] NEXT_TASK = {Gdk.Key.K};
        const int[] PREV_TASK = {Gdk.Key.J};

        public static string? key_to_accel (int key) {
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

        public static string? key_to_label_str (int key) {
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

        public static string to_accel (int[] keys) {
            var result = "";
            foreach (int key in keys) {
                result += key_to_accel (key);
            }
            return result;
        }
    }
}
