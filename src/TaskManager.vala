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
    private bool refresh_queued;
    private FileWatcher todo_watcher;
    private FileWatcher done_watcher;

    private TodoTask active_task;
    private bool active_task_found;

    string[] default_todos = {
        "Choose Todo.txt folder via \"Settings\"",
        "Spread the word about \"Go For It!\"",
        "Consider a donation to help the project",
        "Consider contributing to the project"
    };

    string error_implications = _("Go For It! won't save or load from the current todo.txt directory until it is either restarted or another location is chosen.");
    string read_error_message = _("Couldn't read the todo.txt file (%s):") + "\n\n%s\n\n";
    string write_error_message = _("Couldn't save the todo list (%s):") + "\n\n%s\n\n";
    string txt_dir_error = _("The path to the todo.txt directory does not point to a directory, but to a file or mountable location. Please change the path in the settings to a suitable directory or remove this file.");

    public signal void active_task_invalid ();
    public signal void refreshing ();
    public signal void refreshed ();

    public TaskManager (SettingsManager settings) {
        this.settings = settings;

        need_to_add_tasks = settings.first_start;

        // Initialize TaskStores
        todo_store = new TaskStore (false);
        done_store = new TaskStore (true);

        refresh_queued = false;

        load_task_stores ();

        /* Signal processing */
        settings.todo_txt_location_changed.connect (load_task_stores);
    }

    public void set_active_task (TodoTask? task) {
        active_task = task;
    }

    /**
     * To be called when adding a new (undone) task.
     */
    public void add_new_task (string task) {
        todo_store.add_task (new TodoTask (task, false));
        save_todo_tasks ();
    }

    public void mark_task_done (TodoTask task) {
        task.done = true;
    }

    /**
     * Transfers a task from one TaskStore to another.
     */
    private void transfer_task (
        TodoTask task, TaskStore source, TaskStore destination
    ) {
        source.remove_task (task);
        destination.add_task (task);
        save_todo_tasks ();
        save_done_tasks ();
    }

    /**
     * Deletes all task on the "Done" list
     */
    public void clear_done_store () {
        done_store.clear ();

        save_done_tasks ();
    }

    /**
     * Reloads all tasks.
     */
    public void refresh () {
        stdout.printf("Refreshing\n");
        refreshing ();
        load_tasks ();
        refreshed ();
    }

    private bool auto_refresh () {
        if (todo_watcher.being_updated || done_watcher.being_updated) {
            return true;
        }

        refresh ();

        refresh_queued = false;

        return false;
    }

    private void load_task_stores () {
        stdout.printf("load_task_stores\n");
        todo_txt_dir = File.new_for_path(settings.todo_txt_location);
        todo_txt = todo_txt_dir.get_child ("todo.txt");
        done_txt = todo_txt_dir.get_child ("done.txt");

        if (
            todo_txt_dir.query_exists () &&
            todo_txt_dir.query_file_type (FileQueryInfoFlags.NONE) != FileType.DIRECTORY
        ) {
            io_failed = true;
            show_error_dialog (txt_dir_error);
            warning (txt_dir_error);
        } else {
            io_failed = false;
        }

        // Save data, as soon as something has changed
        todo_store.task_data_changed.connect (save_todo_tasks);
        done_store.task_data_changed.connect (save_done_tasks);

        // Move task from one list to another, if done or undone
        todo_store.task_done_changed.connect (task_done_handler);
        done_store.task_done_changed.connect (task_done_handler);

        load_tasks ();

        if (!io_failed) {
            watch_files ();
        }
    }

    private void watch_files () {
        todo_watcher = new FileWatcher (todo_txt);
        done_watcher = new FileWatcher (done_txt);

        todo_watcher.changed.connect (on_file_changed);
        done_watcher.changed.connect (on_file_changed);
    }

    private void on_file_changed () {
        if (!refresh_queued) {
            refresh_queued = true;

            // Reload after 0.5 seconds so we can be relatively sure, that the
            // other application has finished, writing
            GLib.Timeout.add(
                500, auto_refresh, GLib.Priority.DEFAULT_IDLE
            );
        }
    }

    private void task_done_handler (TaskStore source, TodoTask task) {
        if (source == todo_store) {
            transfer_task (task, todo_store, done_store);
        } else if (source == done_store) {
            transfer_task (task, done_store, todo_store);
        }
    }

    private void load_tasks () {
        // read_only flag, so that "clear()" does not delete the files' content
        read_only = true;
        todo_store.clear ();
        done_store.clear ();
        active_task_found = active_task == null;
        read_task_file (this.todo_txt, false);
        read_task_file (this.done_txt, true);

        if (need_to_add_tasks) {
            add_default_todos ();
        }

        read_only = false;

        if (!active_task_found) {
            active_task_invalid ();
        }
    }

    private void add_default_todos () {
        // Iterate in reverse order because todos are added to position 0
        for (int i = default_todos.length - 1;
             i >= 0;
             i--)
        {
            todo_store.add_task (new TodoTask (default_todos[i], false));
        }
        need_to_add_tasks = false;
    }

    private void save_todo_tasks () {
        if (!read_only) {
            todo_watcher.watching = false;
            write_task_file (this.todo_store, this.todo_txt);
            todo_watcher.watching = true;
        }
    }

    private void save_done_tasks () {
        if (!read_only) {
            done_watcher.watching = false;
            write_task_file (this.done_store, this.done_txt);
            done_watcher.watching = true;
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

    private void ensure_file_exists (File file) throws Error {
        // Create file and return if it does not exist
        if (!file.query_exists()) {
            DirUtils.create_with_parents (todo_txt_dir.get_path (), 0700);
            file.create (FileCreateFlags.NONE);
        }
    }

    string remove_carriage_return (string line) {
        int length = line.length;
        if (length > 0) {
            if (line.get_char (length - 1) == 13) {
                if (length == 1) {
                    return "";
                }
                return line.slice (0, length - 1);
            }
        }

        return line;
    }

    private TodoTask? string_to_task (string _line, bool done_by_default) {
        string line = _line.strip();

        line = remove_carriage_return (line);

        // Todo.txt notation: completed tasks start with an "x "
        bool done = line.has_prefix ("x ");

        if (done) {
            // Remove "x " from displayed string
            line = line.split ("x ", 2)[1];
        }

        line = line.strip ();

        if (line == "") {
            return null;
        }

        if (!active_task_found && !done) {
            if (line == active_task.title) {
                active_task_found = true;
                return active_task;
            }
        }

        return new TodoTask (line, done | done_by_default);
    }

    /**
     * Reads tasks from a Todo.txt formatted file.
     */
    private void read_task_file (File file, bool done_by_default) {
        if (io_failed) {
            return;
        }
        stdout.printf ("Reading file: %s\n", file.get_path ());

        // Read data from todo.txt and done.txt files
        try {
            ensure_file_exists (file);
            var stream_in = new DataInputStream (file.read ());
            string line;

            while ((line = stream_in.read_line (null)) != null) {
                TodoTask? task = string_to_task (line, done_by_default);
                if (task != null) {
                    if (task.done) {
                        done_store.add_task (task);
                    } else {
                        todo_store.add_task (task);
                    }
                }
            }
        } catch (Error e) {
            io_failed = true;
            var error_message = read_error_message.printf(file.get_path (), e.message) + error_implications;
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
            ensure_file_exists (file);
            var file_io_stream =
                file.replace_readwrite (null, true, FileCreateFlags.NONE);
            var stream_out =
                new DataOutputStream (file_io_stream.output_stream);

            uint n_items = store.get_n_items ();
            for (uint i = 0; i < n_items; i++) {
                TodoTask task = (TodoTask)store.get_item (i);
                stream_out.put_string (task.to_string () + "\n");
            }
        } catch (Error e) {
            io_failed = true;
            var error_message = write_error_message.printf(file.get_path (), e.message) + error_implications;
            warning (error_message);
            show_error_dialog (error_message);
        }
    }
}
