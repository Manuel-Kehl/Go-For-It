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
 * Widget to show and create a custom timer schedule
 */
class GOFI.TimerScheduleWidget : Gtk.Frame {

    private Gtk.TreeView custom_tree;
    private Gtk.ScrolledWindow scrollwindow;
    Gtk.ListStore sched_model;
    public Gtk.Grid layout;

    public signal void schedule_updated (Schedule new_schedule);

    public TimerScheduleWidget () {
        layout = new Gtk.Grid ();

        setup_tree ();

        scrollwindow = new Gtk.ScrolledWindow (null, null);
        scrollwindow.add (custom_tree);
        scrollwindow.height_request = 120;

        var add_row_button = new Gtk.Button.from_icon_name ("list-add");
        var remove_row_button = new Gtk.Button.from_icon_name ("list-remove");

        add_row_button.clicked.connect (add_new_row);
        remove_row_button.clicked.connect (remove_selected);

        this.add (layout);
        layout.attach (scrollwindow,      0, 0, 2, 1); // vala-lint=double-spaces
        layout.attach (add_row_button,    0, 1, 1, 1); // vala-lint=double-spaces
        layout.attach (remove_row_button, 1, 1, 1, 1);
    }

    /**
     * Places a new row after the currently selected row
     */
    private void add_new_row () {
        Gtk.TreeIter iter;
        Gtk.TreePath path;

        custom_tree.get_cursor (out path, null);
        if (path != null) {
            sched_model.get_iter (out iter, path);
            sched_model.insert_after (out iter, iter);
        } else {
            sched_model.append (out iter);
        }

        sched_model.set (iter, 0, 1, 1, 1, -1);
        _generate_schedule ();
    }

    /**
     * Removes the currently selected row
     */
    private void remove_selected () {
        Gtk.TreeIter iter;
        Gtk.TreePath path;

        custom_tree.get_cursor (out path, null);
        if (path == null) {
            return;
        }
        sched_model.get_iter (out iter, path);
        if (!sched_model.remove (ref iter)) {
            // make sure that at least one row remains
            sched_model.append (out iter);
            sched_model.set (iter, 0, 1, 1, 1, -1);
        }
        _generate_schedule ();
    }

    private void update_tree_value (string path, string text, int column) {
        Gtk.TreeIter iter;
        GLib.Value duration = Value (typeof (int));

        sched_model.get_iter (out iter, new Gtk.TreePath.from_string (path));

        duration.set_int (int.parse (text));

        sched_model.set_value (iter, column, duration);
        _generate_schedule ();
    }

    public Schedule generate_schedule () {
        Gtk.TreeIter iter;
        Schedule sched = new Schedule ();
        int task_duration, break_duration;

        if (!sched_model.get_iter_first (out iter)) {
            return sched;
        } else {
            sched_model.get (iter, 0, out task_duration, 1, out break_duration, -1);
            sched.append (task_duration * 60, break_duration * 60);
        }
        while (sched_model.iter_next (ref iter)) {
            sched_model.get (iter, 0, out task_duration, 1, out break_duration, -1);
            sched.append (task_duration * 60, break_duration * 60);
        }
        return sched;
    }

    private void _generate_schedule () {
        schedule_updated (generate_schedule ());
    }

    private void setup_tree () {
        custom_tree = new Gtk.TreeView ();
        custom_tree.expand = true;
        var cell_task = new Gtk.CellRendererSpin ();
        var cell_break = new Gtk.CellRendererSpin ();

        custom_tree.insert_column_with_attributes (-1, _("Task duration"), cell_task, "text", 0);
        custom_tree.insert_column_with_attributes (-1, _("Break duration"), cell_break, "text", 1);

        custom_tree.get_column (0).expand = true;
        custom_tree.get_column (1).expand = true;

        cell_task.editable = true;
        cell_break.editable = true;
        cell_task.adjustment = new Gtk.Adjustment (0, 1, 1439, 1, 10, 0);
        cell_break.adjustment = new Gtk.Adjustment (0, 1, 1439, 1, 10, 0);

        cell_task.edited.connect ((path, text) => {
            update_tree_value (path, text, 0);
        });
        cell_break.edited.connect ((path, text) => {
            update_tree_value (path, text, 1);
        });
    }

    public void load_schedule (Schedule sched) {
        Gtk.TreeIter iter;

        sched_model = new Gtk.ListStore (
            2, typeof (int), typeof (int)
        );

        for (uint i = 0; i < sched.length; i++) {
            sched_model.append (out iter);
            sched_model.set (
                iter,
                0, sched.get_task_duration (i) / 60,
                1, sched.get_break_duration (i) / 60,
                -1
            );
        }
        custom_tree.model = sched_model;
    }

}
