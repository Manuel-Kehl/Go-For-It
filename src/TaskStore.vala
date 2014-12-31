/* Copyright 2014 Manuel Kehl (mank319)
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
 * An implementation of Gtk.ListStore that offers special functionality
 * targeted towards the storage of todo list entries
 */
class TaskStore : Gtk.ListStore {
    /* Various Variables */
    public bool done_by_default;
    
    /* Signals */
    public signal void task_data_changed ();
    public signal void task_done_changed (Gtk.TreeIter iter);
    
    /**
     * Constructor of the TaskStore class
     */
    public TaskStore (bool done_by_default) {
        this.done_by_default = done_by_default;
        
        // Setup the columns
        base.set_column_types ({typeof(bool), typeof(string)});
        
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
    public void add_task (string description) {
        // Only add task, if description is not empty
        if (description._strip () != "") {
            add_initial_task (description, done_by_default);
            task_data_changed ();
        }
    }
    
    /**
     * Removes the given task from the list.
     */
    public void remove_task (Gtk.TreeIter iter) {
        this.remove (iter);
    }
    
    /**
     * Function for adding a task on application startup.
     * When tasks are added initially, the "task_data_changed" signal
     * is not emmited.
     */
    public void add_initial_task (string description, 
            bool done = done_by_default) {
        this.insert_with_values (null, -1, 0, done, 1, description, -1);
    }
    
    /**
     * Function for modifying the text of a specific task.
     */
    public void edit_text (Gtk.TreeIter iter, string text) {
        if (text._strip () != "") {
            this.set (iter, 1, text);
            task_data_changed ();
        } else {
            remove_task (iter);
        }
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
