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
 * A widget for displaying and manipulating task lists.
 */
class TaskList : Gtk.Grid {
    /* GTK Widgets */
    private Gtk.ScrolledWindow scroll_view;
    private DragList task_view;
    private Gtk.Grid add_new_grid;
    private Gtk.SearchBar search_bar;
    private Gtk.Entry add_new_txt;
    private Gtk.SearchEntry filter_entry;
    private Filter filter;

    /* Data Model */
    private TaskStore model;

    /* Signals */
    public signal void add_new_task (string task);
    public signal void selection_changed (TodoTask selected_task);

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
        }
    }

    public TodoTask? get_selected_task () {
        TaskRow selected_row = (TaskRow) task_view.get_selected_row ();
        if (selected_row != null) {
            return selected_row.task;
        }
        return null;
    }

    private Gtk.Widget create_row (Object task) {
        TaskRow row = new TaskRow (((TodoTask) task));
        row.link_clicked.connect (on_row_link_clicked);
        return row;
    }

    private void on_row_link_clicked (string uri) {
        search_bar.set_search_mode (true);
        filter_entry.set_text (uri);
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
        add_new_txt.placeholder_text = _("Add new task") + "...";
        add_new_txt.margin = 5;

        add_new_txt.set_icon_from_icon_name (
            Gtk.EntryIconPosition.SECONDARY, "list-add-symbolic");

        /* Action and Signal Handling */
        // Handle clicks on the icon
        add_new_txt.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                // Emit the corresponding signal, if button has been pressed
                add_new_task (add_new_txt.text);
                add_new_txt.text = "";
            }
        });
        // Handle "activate" signals (Enter Key presses)
        add_new_txt.activate.connect ((source) => {
            add_new_task (add_new_txt.text);
            add_new_txt.text = "";
        });

        add_new_grid.add (add_new_txt);

        // Add to the main widget
        this.add (add_new_grid);
    }

    private void setup_filter () {
        search_bar = new Gtk.SearchBar();
        filter_entry = new Gtk.SearchEntry ();
        filter = new Filter ();

        filter_entry.search_changed.connect (() => {
            filter.parse (filter_entry.text);
            task_view.invalidate_filter ();
        });

        search_bar.add (filter_entry);
        search_bar.set_show_close_button (true);

        this.add (search_bar);
    }

    public void toggle_filter_bar () {
        search_bar.set_search_mode (!search_bar.search_mode_enabled);
    }
}
