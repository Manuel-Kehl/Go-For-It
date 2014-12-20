/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
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
    public Gtk.TreeView task_view;
    private Gtk.Grid add_new_grid;
    private Gtk.Entry add_new_txt;
    
    /* Signals */
    public signal void add_new_task (string task);
    
    /** 
     * Constructor of the TaskList class.
     * @param add_new whether or not to show a textfield for adding new entries
     */
    public TaskList (TaskStore model, bool add_new = false) {
        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;
        
        /* Setup the widget's children */
        setup_task_view (model);
        if (add_new) {
            setup_add_new ();
        }
    }
    
    /** 
     * Configures the list to display the task entries.
     */
    private void setup_task_view (TaskStore model) {
        this.scroll_view = new Gtk.ScrolledWindow (null, null);
        this.task_view = new Gtk.TreeView ();
        
        // Assign the correct TaskStore to the Gtk.TreeView
        task_view.set_model (model);
        
        /* Configuration of the Gtk.TreeView */
        task_view.headers_visible = false;
        task_view.expand = true;
        task_view.reorderable = true;
        task_view.vscroll_policy = Gtk.ScrollablePolicy.NATURAL;
        
        // Set up checkbox cell
        var toggle_cell = new Gtk.CellRendererToggle ();
        task_view.insert_column_with_attributes (-1, "Done", toggle_cell, 
            "active", 0);
        
        // Set up task entry cell
        var text_cell = new Gtk.CellRendererText ();
        task_view.insert_column_with_attributes (-1, "Task", text_cell,
            "text", 1);
        text_cell.editable = true;
        if (model.done_by_default) {
            text_cell.strikethrough = true;
        }
        
        /* Action and Signal Handling */
        // Handle tasks being marked done/undone
        toggle_cell.toggled.connect ((toggle, path) => {
            var tree_path = new Gtk.TreePath.from_string (path);
            Gtk.TreeIter iter;
            model.get_iter (out iter, tree_path);
            /* 
             * Handle action on higher level via the signal mechanism.
             * Necessary, because it requires an interaction between multiple
             * TaskStore instances for transferring done/undone tasks from
             * one list to another
             */
            model.task_done_changed (iter);
        });
        
        // Handle text editing events
        text_cell.edited.connect ( (path, edited_text) => {
            Gtk.TreeIter iter;
            model.get_iter (out iter, new Gtk.TreePath.from_string (path));
            // Can be directly applied to the corresponding TaskStore
            model.edit_text (iter, edited_text);
        });
        
        // Add to the main widget
        scroll_view.add (task_view);
        this.add (scroll_view);
    }
    
    /**
     * Configures the container with the "add new task" text entry.
     */
    private void setup_add_new () {
        add_new_grid = new Gtk.Grid ();
        add_new_grid.orientation = Gtk.Orientation.HORIZONTAL;
        
        add_new_txt = new Gtk.Entry ();
        add_new_txt.hexpand = true;
        add_new_txt.placeholder_text = "Add new task...";
        
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
}
