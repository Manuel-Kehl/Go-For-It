/* Copyright 2014-2019 Go For It! developers
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
 * A widget for displaying and manipulating task lists.
 */
class GOFI.TXT.TaskList : Gtk.Grid, FilterableWidget, TaskListWidget {
    /* GTK Widgets */
    private Gtk.ScrolledWindow scroll_view;
    private DragList task_view;
    private Gtk.Grid add_new_grid;
    private Gtk.SearchBar search_bar;
    private Gtk.Entry add_new_txt;
    private Gtk.SearchEntry filter_entry;
    private Filter filter;
    private Gtk.Label placeholder;

    /* Data Model */
    private TaskStore model;

    private const string placeholder_text_todo = _("You currently don't have any tasks.\nAdd some!");
    private const string filter_text = _("The search operation did not return any tasks.");
    private const string placeholder_text_done = _("You don't have any completed tasks stored.");
    private const string placeholder_text_finished = _("You finished all tasks, good job!");
    private string placeholder_text;

    /* Signals */
    public signal void add_new_task (string task);
    public signal void selection_changed (TodoTask selected_task);

    public bool is_filtering {
        public get {
            return search_bar.search_mode_enabled;
        }
        public set {
            search_bar.set_search_mode (value);
        }
    }

    /**
     * Constructor of the TaskList class.
     * @param add_new whether or not to show a textfield for adding new entries
     */
    public TaskList (TaskStore model, bool add_new = false) {
        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;
        this.model = model;

        /* Setup the widget's children */
        setup_filter ();
        setup_task_view ();
        if (add_new) {
            setup_add_new ();
            placeholder_text = placeholder_text_todo;
        } else {
            placeholder_text = placeholder_text_done;
        }
        add_placeholder ();
    }

    public TodoTask? get_selected_task () {
        TaskRow selected_row = (TaskRow) task_view.get_selected_row ();
        if (selected_row != null) {
            return selected_row.task;
        }
        return null;
    }

    public void select_task (TodoTask task) {
        var pos = model.get_task_position(task);
        var row = task_view.get_row_at_index ((int)pos);
        task_view.select_row (row);
    }

    public void move_cursor (int amount) {
        TaskRow selected_row = (TaskRow) task_view.get_selected_row ();
        if (selected_row == null) {
            return;
        }

        // move_cursor was likely called because of a shortcut key, in this case
        // this key was meant for input for this row so we should ignore it.
        if (selected_row.is_editing) {
            return;
        }
        task_view.move_cursor(Gtk.MovementStep.DISPLAY_LINES, amount);
    }

    public void move_selected_task (int amount) {
        var row = task_view.get_selected_row ();
        if (row == null) {
            return;
        }
        var new_index = row.get_index ();
        if (new_index < -amount) {
            new_index = 0;
        } else {
            new_index += amount;
        }
        task_view.move_row(row, new_index);
    }

    private Gtk.Widget create_row (Object task) {
        TaskRow row = new TaskRow (((TodoTask) task));
        row.link_clicked.connect (on_row_link_clicked);
        row.deletion_requested.connect (on_deletion_requested);
        return row;
    }

    private void on_row_link_clicked (string uri) {
        is_filtering = true;
        filter_entry.set_text (uri);
    }

    private void on_deletion_requested (TaskRow row) {
        model.remove_task (row.task);
    }

    private void add_placeholder () {
        placeholder = new Gtk.Label (placeholder_text);
        placeholder.wrap = true;
        placeholder.justify = Gtk.Justification.CENTER;
        placeholder.wrap_mode = Pango.WrapMode.WORD_CHAR;
        placeholder.width_request = 200;
        task_view.set_placeholder (placeholder);
        placeholder.show ();
    }

    /**
     * Configures the list to display the task entries.
     */
    private void setup_task_view () {
        this.scroll_view = new Gtk.ScrolledWindow (null, null);
        this.task_view = new DragList ();

        task_view.bind_model ((DragListModel)model, create_row);
        task_view.vadjustment = scroll_view.vadjustment;
        task_view.row_selected.connect (on_task_view_row_selected);
        task_view.row_activated.connect (on_task_view_row_activated);
        task_view.set_filter_func (filter.filter);

        scroll_view.expand = true;

        // Add to the main widget
        scroll_view.add (task_view);
        this.add (scroll_view);
    }

    private void on_task_view_row_selected (DragListRow? selected_row) {
        TodoTask? task = null;
        if (selected_row != null) {
            task = ((TaskRow) selected_row).task;
        }
        selection_changed (task);
    }

    private void on_task_view_row_activated (DragListRow? selected_row) {
       ((TaskRow) selected_row).edit ();
    }

    /**
     * Configures the container with the "add new task" text entry.
     */
    private void setup_add_new () {
        add_new_grid = new Gtk.Grid ();
        add_new_grid.orientation = Gtk.Orientation.HORIZONTAL;

        add_new_txt = new Gtk.Entry ();
        add_new_txt.hexpand = true;
        add_new_txt.placeholder_text = _("Add new task") + "…";
        add_new_txt.margin = 5;

        add_new_txt.set_icon_from_icon_name (
            Gtk.EntryIconPosition.SECONDARY, "list-add-symbolic");

        /* Action and Signal Handling */
        // Handle clicks on the icon
        add_new_txt.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                on_entry_activate ();
            }
        });
        // Handle "activate" signals (Enter Key presses)
        add_new_txt.activate.connect (on_entry_activate);

        add_new_grid.add (add_new_txt);

        // Add to the main widget
        this.add (add_new_grid);
    }

    private void on_entry_activate () {
        add_new_task (add_new_txt.text);
        add_new_txt.text = "";
        placeholder_text = placeholder_text_finished;
        placeholder.label = placeholder_text_finished;
    }

    public void entry_focus () {
        add_new_txt.grab_focus ();
    }

    private void on_search_bar_toggle () {
        if (search_bar.search_mode_enabled) {
            placeholder.label = filter_text;
        } else {
            placeholder.label = placeholder_text;
        }
    }

    private void setup_filter () {
        search_bar = new Gtk.SearchBar ();
        filter_entry = new Gtk.SearchEntry ();
        filter = new Filter ();

        filter_entry.search_changed.connect (() => {
            filter.parse (filter_entry.text);
            task_view.invalidate_filter ();
        });
        search_bar.notify["search-mode-enabled"].connect (on_search_bar_toggle);

        search_bar.add (filter_entry);
        search_bar.set_show_close_button (true);

        this.add (search_bar);
    }
}
