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
            add_shortcut_descr (layout, ref y, _("Filter tasks"), kbsettings.get_shortcut ("filter"));
            add_shortcut_descr (layout, ref y, _("Add new task/list"), kbsettings.get_shortcut ("add-new"));
            add_shortcut_descr (layout, ref y, _("Start/Stop the timer"), kbsettings.get_shortcut ("toggle-timer"));
            add_shortcut_descr (layout, ref y, _("Mark the task as complete"), kbsettings.get_shortcut ("mark-task-done"));
            add_shortcut_descr (layout, ref y, _("Move selected row up"), kbsettings.get_shortcut ("move-row-up"));
            add_shortcut_descr (layout, ref y, _("Move selected row down"), kbsettings.get_shortcut ("move-row-down"));
            add_shortcut_descr (layout, ref y, _("Move to right screen"), kbsettings.get_shortcut ("cycle-page"));
            add_shortcut_descr (layout, ref y, _("Move to left screen"), kbsettings.get_shortcut ("cycle-page-reverse"));
            add_shortcut_descr (layout, ref y, _("Move to next task/row"), kbsettings.get_shortcut ("next-task"));
            add_shortcut_descr (layout, ref y, _("Move to previous task/row"), kbsettings.get_shortcut ("prev-task"));

            add (layout);
            layout.show_all ();
        }

        private Gtk.Label create_key_label (string text) {
            Gtk.Label key_label = new Gtk.Label (text);
            key_label.get_style_context ().add_class ("keycap");
            return key_label;
        }

        private void add_shortcut_descr (Gtk.Grid grid, ref int y, string descr, Shortcut sc) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);

            if ((sc.modifier & Gdk.ModifierType.CONTROL_MASK) != 0) {
                box.add (create_key_label ("Ctrl"));
                box.add (new Gtk.Label ("+"));
            }
            if ((sc.modifier & Gdk.ModifierType.SHIFT_MASK) != 0) {
                box.add (create_key_label ("Shift"));
                box.add (new Gtk.Label ("+"));
            }
            if ((sc.modifier & Gdk.ModifierType.MOD1_MASK) != 0) {
                box.add (create_key_label ("Alt"));
                box.add (new Gtk.Label ("+"));
            }
            switch (sc.key) {
                case Gdk.Key.Return:
                    box.add (create_key_label ("Enter")); // Most keyboards have Enter printed on the key
                    break;
                default:
                    box.add (create_key_label (Gdk.keyval_name (sc.key)));
                    break;
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
