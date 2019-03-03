/* Copyright 2018 Go For It! developers
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

using GOFI.TXT;

/**
 * A widget for displaying and manipulating info lists.
 */
class GOFI.SelectionPage : Gtk.Grid {
    /* GTK Widgets */
    private Gtk.ScrolledWindow scroll_view;
    private DragList todolist_view;
    private Gtk.Button add_button;
    private TxtListEditDialog create_dialog;
    private Gtk.Widget placeholder;

    /* Data Model */
    private ListManager list_manager;

    /* Signals */
    public signal void selection_changed (TodoListInfo selected_info);
    public signal void list_chosen (TodoListInfo selected_info);

    /**
     * Constructor of the SelectionPage class.
     */
    public SelectionPage (ListManager list_manager) {
        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;
        this.list_manager = list_manager;
        create_dialog = null;

        /* Setup the widget's children */
        setup_todolist_view ();
    }

    private Gtk.Widget create_row (Object info) {
        TodoListInfoRow row = new TodoListInfoRow (((TodoListInfo) info));
        row.delete_clicked.connect (on_row_delete_clicked);
        row.edit_clicked.connect (on_row_edit_clicked);
        return row;
    }

    private void on_row_delete_clicked (TodoListInfo info) {
        list_manager.delete_list (info, this.get_toplevel () as Gtk.Window);
    }

    private void on_row_edit_clicked (TodoListInfo info) {
        list_manager.edit_list (info, this.get_toplevel () as Gtk.Window);
    }

    /**
     * Configures the list to display the info entries.
     */
    private void setup_todolist_view () {
        this.scroll_view = new Gtk.ScrolledWindow (null, null);
        this.todolist_view = new DragList ();

        todolist_view.bind_model ((DragListModel)list_manager, create_row);
        todolist_view.vadjustment = scroll_view.vadjustment;
        todolist_view.row_activated.connect (on_todolist_view_row_activated);

        placeholder = new Gtk.Label (_("No lists configured, add one below"));
        placeholder.show ();
        todolist_view.set_placeholder (placeholder);

        scroll_view.expand = true;

        // Add to the main widget
        scroll_view.add (todolist_view);
        this.add (scroll_view);

        add_button = new Gtk.Button.with_label ("Add list");
        this.add (add_button);

        add_button.clicked.connect (on_add_button_clicked);
    }

    private void on_add_button_clicked () {
        if (create_dialog == null) {
            Gtk.Window? window = this.get_toplevel () as Gtk.Window;
            create_dialog = list_manager.get_txt_manager ().get_creation_dialog (window);
            create_dialog.destroy.connect (() => {
                create_dialog = null;
            });
        }
        create_dialog.show_all ();
    }

    private void on_todolist_view_row_activated (DragListRow? selected_row) {
        TodoListInfo? info = null;
        if (selected_row != null) {
            info = ((TodoListInfoRow) selected_row).info;
        }
        list_chosen (info);
    }
}
