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

    /* Signals */
    public signal void selection_changed (TodoListInfo selected_info);
    public signal void list_chosen (TodoListInfo selected_info);

    [Signal (action = true)]
    public virtual signal void list_edit_action () {
        var selected_row = todolist_view.get_selected_row () as TodoListInfoRow;
        if (selected_row != null) {
            on_row_edit_clicked (selected_row.info);
        }
    }

    [Signal (action = true)]
    public virtual signal void list_delete_action () {
        var selected_row = todolist_view.get_selected_row () as TodoListInfoRow;
        if (selected_row != null) {
            on_row_delete_clicked (selected_row.info);
        }
    }

    /**
     * Constructor of the SelectionPage class.
     */
    public SelectionPage () {
        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;
        this.width_request = 200;
        this.height_request = 250;
        create_dialog = null;

        /* Setup the widget's children */
        setup_todolist_view ();

        // TODO: It is probably better to create a style class specific to this widget
        get_style_context ().add_class ("task-layout");
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

    public void move_cursor (int amount) {
        todolist_view.move_cursor (Gtk.MovementStep.DISPLAY_LINES, amount);
    }

    public void select_row (TodoListInfo info) {
        DragListRow corresponding_row = null;
        foreach (var row in todolist_view.get_rows ()) {
            if (((TodoListInfoRow) row).info.cmp (info) == 0) {
                corresponding_row = row;
                break;
            }
        }
        if (corresponding_row != null) {
            todolist_view.select_row (corresponding_row);
        }
    }

    public void move_selected_row (int amount) {
        var row = todolist_view.get_selected_row ();
        if (row == null) {
            return;
        }
        var new_index = row.get_index ();
        if (new_index < -amount) {
            new_index = 0;
        } else {
            new_index += amount;
        }
        todolist_view.move_row (row, new_index);
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

        var placeholder_lbl = new Gtk.Label (_("Currently, no lists are configured.\nAdd one below!"));
        placeholder_lbl.margin = 10;
        placeholder_lbl.wrap = true;
        placeholder_lbl.wrap_mode = Pango.WrapMode.WORD_CHAR;
        placeholder = placeholder_lbl;
        placeholder.show ();
        todolist_view.set_placeholder (placeholder);

        scroll_view.expand = true;

        // Add to the main widget
        scroll_view.add (todolist_view);
        this.add (scroll_view);

        add_button = new Gtk.Button.with_label (_("Add list"));

        var sc = kbsettings.get_shortcut (KeyBindingSettings.SCK_ADD_NEW);
        add_button.tooltip_markup = sc.get_accel_markup (_("Add list"));

        this.add (add_button);

        add_button.clicked.connect (on_add_button_clicked);
    }

    [Signal (action = true)]
    public virtual signal void show_list_creation_dialog () {
        if (create_dialog == null) {
            Gtk.Window? window = this.get_toplevel () as Gtk.Window;
            create_dialog = list_manager.get_txt_manager ().get_creation_dialog (window);
            create_dialog.destroy.connect (() => {
                create_dialog = null;
            });
        }
        create_dialog.show_all ();
    }

    private void on_add_button_clicked () {
        show_list_creation_dialog ();
    }

    private void on_todolist_view_row_activated (DragListRow? selected_row) {
        TodoListInfo? info = null;
        if (selected_row != null) {
            info = ((TodoListInfoRow) selected_row).info;
        }
        list_chosen (info);
    }
}
