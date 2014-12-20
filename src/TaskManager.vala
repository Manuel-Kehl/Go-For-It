/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Just Do It!.
*
* Just Do It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Just Do It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Just Do It!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * This class is responsible for loading, saving and managing the user's tasks.
 * Therefore it offers methods for interacting with the set of tasks in all
 * lists. Editing specific tasks (e.g. removing, renaming) is to be done 
 * by addressing the corresponding TaskStore instance.
 */
class TaskManager {
    private SettingsManager settings;
    // The user's todo.txt related files
    private File todo_txt_dir;
    private File todo_txt;
    private File done_txt;
    public TaskStore todo_store;
    public TaskStore done_store;
    
    public TaskManager (SettingsManager settings) {
        this.settings = settings;
        this.todo_txt_dir = File.new_for_path(settings.todo_txt_location);
        this.todo_txt = todo_txt_dir.get_child ("todo.txt");
        this.done_txt = todo_txt_dir.get_child ("done.txt");
        
        // Initialize TaskStores
        this.todo_store = new TaskStore (false);
        this.done_store = new TaskStore (true);
        
        /* Signal processing */
        // Save data, as soon as something has changed
        this.todo_store.task_data_changed.connect (save_tasks);
        this.done_store.task_data_changed.connect (save_tasks);
        
        // Move task from one list to another, if done or undone
        this.todo_store.task_done_changed.connect ((source, iter) => {
            transfer_task(iter, todo_store, done_store);
        });
        this.done_store.task_done_changed.connect ((source, iter) => {
            transfer_task(iter, done_store, todo_store);
        });
        
        load_tasks ();
        // Move done tasks off the todo list on startup
        auto_transfer_tasks();
    }
    
    /**
     * To be called when adding a new (undone) task.
     */
    public void add_new_task (string task) {
        todo_store.add_task (task);
    }
    
    public void mark_task_done (Gtk.TreeRowReference reference) {
        if (reference.valid ()) {
            // Get Gtk.TreeIterator from reference
            var path = reference.get_path ();
            Gtk.TreeIter iter;
            todo_store.get_iter (out iter, path);
            // Remove task from the todo lists
            transfer_task (iter, todo_store, done_store);
        }
    }
    
    /** 
     * Transfers a task from one TaskStore to another.
     */
    private void transfer_task (Gtk.TreeIter iter,
            TaskStore source, TaskStore destination ) {
        Value description;
        source.get_value (iter, 1, out description);
        destination.add_task ((string) description);
        source.remove_task (iter);
    }
    
    /**
     * Cleans the todo list by transfering all done tasks to the done list.
     */
    private void auto_transfer_tasks () {
        Gtk.TreeIter iter;
        // Iterate through TaskStore
        for (bool next = todo_store.get_iter_first (out iter); next;
                    next = todo_store.iter_next (ref iter)) {
            Value out1;
            todo_store.get_value (iter, 0, out out1);
            bool done = (bool) out1;
            
            if (done) {
                transfer_task (iter, todo_store, done_store);
            }
        }
    }
    
    private void load_tasks () {
        read_task_file (this.todo_store, this.todo_txt);
        read_task_file (this.done_store, this.done_txt);
    }
    
    private void save_tasks () {
        write_task_file (this.todo_store, this.todo_txt);
        write_task_file (this.done_store, this.done_txt);
    }
    
    /**
     * Reads tasks from a Todo.txt formatted file.
     */
    private void read_task_file (TaskStore store, File file) {
        // Create file and return if it does not exist
        if (!file.query_exists()) {
            DirUtils.create_with_parents (todo_txt_dir.get_path (), 0700);
            try {
                file.create (FileCreateFlags.NONE); 
            } catch (Error e) {
                error ("%s", e.message);
            }
            return;
        }
        
        // Read data from todo.txt and done.txt files
        try {
            var stream_in = new DataInputStream (file.read ());
            string line;
            
            while ((line = stream_in.read_line (null)) != null) {
                // Todo.txt notation: completed tasks start with an "x"
                bool done = line.has_prefix ("x");
                
                if (done) {
                    // Remove "x" from displayed string
                    line = line.split ("x", 2)[1];
                }
                
                store.add_initial_task (line, done);
            }
        } catch (Error e) {
            error ("%s", e.message);
        }
    }
    
    /**
     * Saves tasks to a Todo.txt formatted file.
     */
    private void write_task_file (TaskStore store, File file) {
        try {
            /*var stream_out = new DataOutputStream (
                file.create (FileCreateFlags.REPLACE_DESTINATION));*/
            var file_io_stream = 
                file.replace_readwrite (null, true, FileCreateFlags.NONE);
            var stream_out = 
                new DataOutputStream (file_io_stream.output_stream);
            
            Gtk.TreeIter iter;
            // Iterate through the TaskStore
            for (bool next = store.get_iter_first (out iter); next;
                    next = store.iter_next (ref iter)) {
                // Get data out of store
                Value out1, out2;
                store.get_value (iter, 0, out out1);
                store.get_value (iter, 1, out out2);
                // Cast to the corresponding types
                bool done = (bool) out1;
                string text = (string) out2;
                
                if (done) {
                    text = "x" + text;
                }
                
                stream_out.put_string (text + "\n");
            }
        } catch (Error e) {
            error ("%s", e.message);
        }
    }
}
