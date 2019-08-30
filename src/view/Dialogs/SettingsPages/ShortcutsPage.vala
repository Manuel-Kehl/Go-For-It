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

using GOFI.DialogUtils;

/**
 * Settings page to display and configure shortcuts based on the keyboard
 * settings switchboard plug from elementary OS.
 */
class GOFI.ShortcutsPage : Gtk.Grid {

    private Gtk.TreeView sc_tree;
    private Gtk.ScrolledWindow scrollwindow;

    public ShortcutsPage () {
        setup_tree ();

        scrollwindow = new Gtk.ScrolledWindow (null, null);
        scrollwindow.add (sc_tree);

        var shortcuts_frame = new Gtk.Frame (null);
        shortcuts_frame.add (scrollwindow);

        attach (shortcuts_frame, 0, 0, 1, 1);
        var restart_info_label = new Gtk.Label (
            "%s needs to be restarted for changes to take effect.".printf ("Go For It!")
        );
        attach (restart_info_label, 0, 1, 1, 1);
        load_and_display_shortcuts ();
        apply_grid_spacing (this);
        sc_tree.show_all ();
    }

    private void setup_tree () {
        sc_tree = new Gtk.TreeView ();
        var cell_desc = new Gtk.CellRendererText ();
        var cell_edit = new Gtk.CellRendererAccel ();

        cell_edit.editable   = true;
        cell_edit.accel_mode = Gtk.CellRendererAccelMode.OTHER;

        sc_tree.insert_column_with_attributes (-1, null, cell_desc, "text", 0);
        sc_tree.insert_column_with_attributes (-1, null, cell_edit, "text", 1);

        sc_tree.headers_visible = false;
        sc_tree.expand          = true;

        sc_tree.get_column (0).expand = true;

        sc_tree.button_press_event.connect ((event) => {
            if (event.window != sc_tree.get_bin_window ()) {
                return false;
            }

            Gtk.TreePath path;

            if (sc_tree.get_path_at_pos ((int) event.x, (int) event.y,
                                         out path, null, null, null)) {
                Gtk.TreeViewColumn col = sc_tree.get_column (1);
                sc_tree.grab_focus ();
                sc_tree.set_cursor (path, col, true);
            }

            return true;
        });

        cell_edit.accel_edited.connect ((path, key, mods) => {
            change_shortcut (path, new Shortcut (key, mods));
        });

        cell_edit.accel_cleared.connect ((path) => {
            change_shortcut (path, new Shortcut.disabled ());
        });
    }


    public void change_shortcut (string path, Shortcut shortcut) {
        Gtk.TreeIter  iter;
        GLib.Value    key, name;
        string? conflict_id = null;
        var model = sc_tree.model;

        model.get_iter (out iter, new Gtk.TreePath.from_string (path));

        model.get_value (iter, 0, out name);
        model.get_value (iter, 2, out key);

        if (shortcut.is_valid) {
            conflict_id = kbsettings.conflicts (shortcut);
        }

        if (conflict_id != null) {
            if ((string) key == conflict_id) {
                return;
            }
            kbsettings.set_shortcut (conflict_id, new Shortcut.disabled ());
        }

        kbsettings.set_shortcut ((string) key, shortcut);

        load_and_display_shortcuts ();
    }

    private void load_and_display_shortcuts () {
        var known_shortcuts = KeyBindingSettings.known_shortcuts;

        var store = new Gtk.ListStore (
            3, typeof (string), typeof (string), typeof (string)
        );

        Gtk.TreeIter iter;

        foreach (var sc in known_shortcuts) {
            var shortcut = kbsettings.get_shortcut (sc.shortcut_id);

            if (shortcut == null) {
                continue;
            }

            store.append (out iter);
            store.set (
                iter,
                0, sc.description,
                1, shortcut.to_readable(),
                2, sc.shortcut_id, -1  // hidden
            );
        }

        sc_tree.model = store;
    }

}
