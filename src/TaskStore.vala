/* Copyright 2014-2016 Go For It! developers
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
 * An implementation of Gtk.ListStore that offers special functionality
 * targeted towards the storage of todo list entries
 */

/* Columns */
public enum Columns {
    TOGGLE,
    TEXT,
    DRAGHANDLE,
    N_COLUMNS
}

class TaskStore : Gtk.ListStore {

    /* Various Variables */
    public bool active_task_invalid = false;
    public bool done_by_default;
    public TodoTask? active_task;
    
    /* Signals */
    public signal void task_data_changed ();
    public signal void task_done_changed (Gtk.TreeIter iter);
    public signal void refresh_active_task ();
    
    /**
     * Constructor of the TaskStore class
     */
    public TaskStore (bool done_by_default) {
        this.done_by_default = done_by_default;
        
        // Setup the columns
        base.set_column_types ({
            typeof(bool),   /* toggle */
            typeof(string), /* title */
            typeof(string)  /* drag handle */
        });
        
        /* Reroute underlying signals to task_data_changed */
        this.rows_reordered.connect (trigger_task_data_changed);

        this.row_deleted.connect (trigger_task_data_changed);
    }

    private void trigger_task_data_changed () {
        task_data_changed ();
    }

    /** 
     * To be called when an actually new task is to be added to the list.
     * Therefore it does not need a "done" parameter, as one can determine
     * that by observing the type of list to be added to.
     */
    public void add_task (string description, int position = -1) {
        // Only add task, if description is not empty
        if (description._strip () != "") {
            bool was_empty = this.is_empty ();
            add_initial_task (description, done_by_default, position);
            task_data_changed ();
            if (was_empty) {
                refresh_active_task ();
            }
        }
    }
    
    /**
     * Removes the given task from the list.
     */
    public void remove_task (Gtk.TreeIter iter) {
        bool is_active_task = compare_tasks (iter);
        var _active_task = active_task;
        this.remove (iter);
        if (is_active_task && _active_task == active_task) {
            active_task = null;
            refresh_active_task ();
        }
    }
    
    /**
     * Function for adding a task on application startup.
     * When tasks are added initially, the "task_data_changed" signal
     * is not emmited.
     */
    public void add_initial_task (string description,
            bool done = done_by_default, int position = -1) {
        Gtk.TreeIter iter;
        this.insert_with_values (out iter, position,
                                 Columns.TOGGLE, done,
                                 Columns.TEXT, description,
                                 Columns.DRAGHANDLE, "view-list-symbolic",
                                 -1);
        if (active_task_invalid && active_task != null) {
            if (description == active_task.title) {
                var path = this.get_path (iter);
                active_task.reference = new Gtk.TreeRowReference (this, path);
                active_task_invalid = false;
            }
        }
    }
    
    /**
     * Function for modifying the text of a specific task.
     */
    public void edit_text (Gtk.TreeIter iter, string text) {
        if (text._strip () != "") {
            this.set (iter, 1, text);
            task_data_changed ();
            if (compare_tasks (iter)) {
                active_task.title = text;
            }
        } else {
            remove_task (iter);
        }
    }
    
    /**
     * Checks if iter corresponds to the active task.
     */
    private bool compare_tasks (Gtk.TreeIter iter) {
        if (active_task != null) {
            var active_path = active_task.reference.get_path ();
            var iter_path = this.get_path (iter);
            
            if (iter_path != null && active_path != null) {
                return (active_path.compare (iter_path) == 0);
            }
        }
        
        return false;
    }
    
    /**
     * Checks if the TaskStore is empty
     */
    public bool is_empty () {
        // get_iter_first returns false, if tree is empty -> invert result
        Gtk.TreeIter tmp;
        return (!this.get_iter_first (out tmp));
    }
}
