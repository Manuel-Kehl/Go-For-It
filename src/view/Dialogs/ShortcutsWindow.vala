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

    /**
     * A Window for displaying the keyboard shortcuts available in Go For It!
     * Gtk.ShortcutsWindow was not used as it dowsn't support Gtk 3.18 which we
     * currently still support. Furthermore it seems that using a
     * Gtk.ShortcutsWindow would force the use of a .ui file with hardcoded
     * shortcuts, which is not ideal.
     */
    public class ShortcutsWindow : Gtk.Window {
        public ShortcutsWindow (Gtk.Window parent) {
            set_transient_for (parent);
            title = _("Keyboard Shortcuts");
            modal = true;
            window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
            resizable = false;

            var layout = new Gtk.Grid ();
            layout.column_spacing = 12;
            layout.row_spacing = 12;
            layout.hexpand = true;
            layout.margin = 12;

            int y = 0;
            add_shortcut_descr (layout, ref y, _("Filter tasks"), Shortcuts.FILTER);
            add_shortcut_descr (layout, ref y, _("Add new task/list"), Shortcuts.NEW);
            add_shortcut_descr (layout, ref y, _("Start/Stop the timer"), Shortcuts.TIMER);
            add_shortcut_descr (layout, ref y, _("Mark the task as complete"), Shortcuts.TASK_DONE);
            add_shortcut_descr (layout, ref y, _("Move selected row up"), Shortcuts.ROW_MOVE_UP);
            add_shortcut_descr (layout, ref y, _("Move selected row down"), Shortcuts.ROW_MOVE_DOWN);
            add_shortcut_descr (layout, ref y, _("Move to left screen"), Shortcuts.SWITCH_PAGE_LEFT);
            add_shortcut_descr (layout, ref y, _("Move to right screen"), Shortcuts.SWITCH_PAGE_RIGHT);
            add_shortcut_descr (layout, ref y, _("Move to next task/row"), Shortcuts.NEXT_TASK);
            add_shortcut_descr (layout, ref y, _("Move to previous task/row"), Shortcuts.PREV_TASK);

            add (layout);
            layout.show_all ();
        }

        private void add_shortcut_descr (Gtk.Grid grid, ref int y, string descr, int[] shortcut) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
            var first = true;

            foreach (int key in shortcut) {
                if (first) {
                    first = false;
                } else {
                    box.add (new Gtk.Label ("+"));
                }
                var key_label = new Gtk.Label (Shortcuts.key_to_label_str (key));
                key_label.get_style_context ().add_class ("keycap");

                box.add (key_label);
            }
            var descr_label = new Gtk.Label (descr + ":");
            descr_label.halign = Gtk.Align.END;
            descr_label.xalign = 1;

            grid.attach (descr_label, 0, y, 1, 1);
            grid.attach (box, 1, y, 1, 1);
            y++;
        }
    }
}
