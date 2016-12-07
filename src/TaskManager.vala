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
    private bool read_only;
    private bool need_to_add_tasks;
    private bool io_failed;
    
    // refreshing
    private FileMonitor todo_monitor;
    private FileMonitor done_monitor;
    private bool prevent_refresh;
    private string todo_etag = "";
    private string done_etag = "";
        
    string[] default_todos = {
        "Choose Todo.txt folder via \"Settings\"",
        "Spread the word about \"Go For It!\"",
        "Consider a donation to help the project",
        "Consider contributing to the project"
    };
    
    string error_implications = _("Go For It! won't save or load from the current todo.txt directory until it is either restarted or another location is chosen.");
    
    public signal void active_task_invalid ();
    public signal void refreshing ();
    public signal void refreshed ();
    
    public TaskManager (SettingsManager settings) {
        this.settings = settings;
        
        need_to_add_tasks = settings.first_start;
        
        // Initialize TaskStores
        todo_store = new TaskStore (false);
        done_store = new TaskStore (true);
        
        prevent_refresh = false;
        
        load_task_stores ();
        
        /* Signal processing */
        settings.todo_txt_location_changed.connect (load_task_stores);
        
        // Move done tasks off the todo list on startup
        auto_transfer_tasks();
    }
    
    public void set_active_task (TodoTask? task) {
        todo_store.active_task = task;
        todo_store.active_task_invalid = false;
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
    
    /**
     * Deletes all task on the "Done" list
     */
    public void clear_done_store () {
        read_only = true; // Don't save while clearing
        done_store.clear ();
        read_only = false;
        
        save_tasks ();
    }
    
    /**
     * Reloads all tasks.
     */
    public void refresh () {
        stdout.printf("Refreshing\n");
        refreshing ();
        load_tasks ();
        // Some tasks may have been marked as done by other applications.
        auto_transfer_tasks ();
        refreshed ();
    }
    
    private bool auto_refresh () {
        if (!check_etags()) {
            refresh ();
        }
        
        prevent_refresh = false;
        
        return false;
    }
    
    private void gen_etags () {
        try {
            FileInfo file_info;
            file_info = todo_txt.query_info (GLib.FileAttribute.ETAG_VALUE, 0);
            todo_etag = file_info.get_etag ();
            file_info = done_txt.query_info (GLib.FileAttribute.ETAG_VALUE, 0);
            done_etag = file_info.get_etag ();
        } catch (Error e) {
            warning (e.message);
        }
    }
    
    private bool check_etags () {
        string todo_etag_old = todo_etag;
        string done_etag_old = done_etag;
        
        gen_etags ();
        
        return (todo_etag == todo_etag_old) && (done_etag == done_etag_old);
    }
    
    private void load_task_stores () {
        stdout.printf("load_task_stores\n");
        todo_txt_dir = File.new_for_path(settings.todo_txt_location);
        todo_txt = todo_txt_dir.get_child ("todo.txt");
        done_txt = todo_txt_dir.get_child ("done.txt");
        
        io_failed = false;
        
        // Save data, as soon as something has changed
        todo_store.task_data_changed.connect (save_tasks);
        done_store.task_data_changed.connect (save_tasks);

        // Move task from one list to another, if done or undone
        todo_store.task_done_changed.connect (task_done_handler);
        done_store.task_done_changed.connect (task_done_handler);
        
        // When removing the last task or adding a task to an empty list, the
        // timer should be updated.
        todo_store.refresh_active_task.connect ( () => {
            active_task_invalid ();
        });
        
        load_tasks ();

        watch_files ();
    }
    
    private void watch_files () {
        try {
            todo_monitor = todo_txt.monitor_file (FileMonitorFlags.NONE, null);
            done_monitor = done_txt.monitor_file (FileMonitorFlags.NONE, null);
        } catch (IOError e) {
            stderr.printf ("watch_files: %s\n", e.message);
        }
        
        todo_monitor.changed.connect (on_file_changed);
        done_monitor.changed.connect (on_file_changed);
    }
    
    private void on_file_changed () {
        if (!prevent_refresh) {
            prevent_refresh = true;
            
            // Reload after 0.1 seconds so we can be relatively sure, that the 
            // other application has finished, writing
            GLib.Timeout.add(
                100, auto_refresh, GLib.Priority.DEFAULT_IDLE
            );
        }
    }

    private void task_done_handler (TaskStore source, Gtk.TreeIter iter) {
        if (source == todo_store) {
            transfer_task (iter, todo_store, done_store);
        } else if (source == done_store) {
            transfer_task (iter, done_store, todo_store);
        }
    }
    
    private void load_tasks () {
        // read_only flag, so that "clear()" does not delete the files' content
        read_only = true;
        todo_store.clear ();
        done_store.clear ();
        if (todo_store.active_task != null) {
            todo_store.active_task_invalid = true;
        }
        read_task_file (this.todo_store, this.todo_txt);
        read_task_file (this.done_store, this.done_txt);
        read_only = false;
        
        if (need_to_add_tasks) {
            // Iterate in reverse order because todos are added to position 0
            for (int i = default_todos.length - 1;
                 i >= 0;
                 i--)
            {
                todo_store.add_task(default_todos[i], 0);
            }
            need_to_add_tasks = false;
        }
        
        if (todo_store.active_task_invalid) {
            active_task_invalid ();
        }
    }
    
    private void save_tasks () {
        if (!read_only) {
            write_task_file (this.todo_store, this.todo_txt);
            write_task_file (this.done_store, this.done_txt);
            gen_etags ();
        }
    }
    
    private void show_error_dialog (string error_message) {
        var dialog = new Gtk.MessageDialog (
            null, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.ERROR, 
            Gtk.ButtonsType.OK, error_message
        );
        dialog.response.connect ((response_id) => {
            dialog.destroy ();
		});
        
        dialog.show ();
    }
    
    /**
     * Reads tasks from a Todo.txt formatted file.
     */
    private void read_task_file (TaskStore store, File file) {
        if (io_failed) {
            return;
        }
        stdout.printf ("Reading file: %s\n", file.get_path ());
        
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
                // Removing carriage return at the end of a task and
                // skipping empty lines
                int length = line.length;
                if (length > 0) {
                    if (line.get_char (length - 1) == 13) {
                        if (length == 1) {
                            continue;
                        }
                        line = line.slice (0, length - 1);
                    }
                } else {
                    continue;
                }
                
                // Todo.txt notation: completed tasks start with an "x "
                bool done = line.has_prefix ("x ");
                
                if (done) {
                    // Remove "x " from displayed string
                    line = line.split ("x ", 2)[1];
                }
                
                store.add_initial_task (line, done);
            }
        } catch (Error e) {
            io_failed = true;
            var error_message = _("Couldn't read the todo.txt file (%s):").printf(file.get_path ()) + "\n\n%s\n\n".printf(e.message) + error_implications;
            warning (error_message);
            show_error_dialog (error_message);
        }
    }
    
    /**
     * Saves tasks to a Todo.txt formatted file.
     */
    private void write_task_file (TaskStore store, File file) {
        if (io_failed) {
            return;
        }
        stdout.printf ("Writing file: %s\n", file.get_path ());
        
        try {
            var file_io_stream = 
                file.replace_readwrite (null, true, FileCreateFlags.NONE);
            var stream_out = 
                new DataOutputStream (file_io_stream.output_stream);
            
            Gtk.TreeIter iter;
            // Iterate through the TaskStore
            for (bool next = store.get_iter_first (out iter); next;
                    next = store.iter_next (ref iter)) {
                // Get data out of store
                Value done, text;
                store.get_value (iter, 0, out done);
                store.get_value (iter, 1, out text);
                
                if ((bool) done) {
                    text = "x " + (string) text;
                }
                
                stream_out.put_string ((string) text + "\n");
            }
        } catch (Error e) {
            io_failed = true;
            var error_message = _("Couldn't save the todo list (%s):").printf(file.get_path ()) + "\n\n%s\n\n".printf(e.message) + error_implications;
            warning (error_message);
            show_error_dialog (error_message);
        }
    }
}
