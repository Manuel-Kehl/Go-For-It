/* Copyright 2014-2020 Go For It! developers
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
 * A class that currently uses a GLib.KeyFile to store and access the settings
 * of each to-do list.
 */
class GOFI.TXT.TxtListManager {
    private bool add_default_todos;

    private GLib.Settings global_txt_settings;
    private const string ID_TODO_TXT = GOFI.APP_ID + ".todo-txt";
    private const string KEY_LIST_IDS = "lists";


    // The keys are string representations of uints, uints are not used directly
    // as elsewhere strings are used for ids.
    private HashTable<string, ListSettings> list_table;

    public bool first_run {
        public get;
        private set;
    }

    string[] list_ids {
        owned get {
            string[] ids = {};
            foreach (string id in global_txt_settings.get_strv (KEY_LIST_IDS)) {
                if (is_valid_id (id)) {
                    ids += id;
                } else {
                    warning ("Invalid todo.txt list id: %s", id);
                }
            }
            return ids;
        }
        set {
            global_txt_settings.set_strv (KEY_LIST_IDS, value);
        }
    }

    public signal void lists_added (List<TodoListInfo> new_lists);
    public signal void lists_removed (List<string> removed);

    /**
     * Constructs a SettingsManager object from a configuration file.
     * Reads the corresponding file and creates it, if necessary.
     */
    public TxtListManager (string? import_dir) {
        list_table = new HashTable<string, ListSettings> (str_hash, str_equal);
        global_txt_settings = new GLib.Settings (ID_TODO_TXT);
        if (import_dir != null) {
            var legacy_settings = new LegacyTxtListImport (import_dir);
            legacy_settings.import_settings_instances (list_table);
            sync_list_ids ();
            first_run = legacy_settings.first_run;
        } else {
            first_run = false;
            create_settings_instances ();
        }
        add_default_todos = first_run;
    }

    private void sync_list_ids () {
        global_txt_settings.set_strv (KEY_LIST_IDS, list_table.get_keys_as_array ());
    }

    /**
     * Checks if the uri is used by another TxtList
     */
    public bool todo_uri_available (ListSettings changed) {
        var todo_uri = changed.todo_uri;
        foreach (ListSettings list in list_table.get_values ()) {
            if (list.todo_uri == todo_uri && list.id != changed.id) {
                return false;
            }
            if (list.done_uri == todo_uri && list.id != changed.id) {
                return false;
            }
        }
        return true;
    }
    public bool done_uri_available (ListSettings changed) {
        var done_uri = changed.done_uri;
        foreach (ListSettings list in list_table.get_values ()) {
            if (list.todo_uri == done_uri) {
                return false;
            }
        }
        return true;
    }

    public TxtList? get_list (string id) {
        var list = new TxtList (list_table[id]);
        return list;
    }

    public TodoListInfo? get_list_info (string id) {
        return list_table[id];
    }

    private void swap_todo_done (string todo_uri, string done_uri) throws Error {
        var tmp_file = File.new_for_path (Path.build_filename (Environment.get_tmp_dir (), "gofi-done.txt"));
        var todo_txt = File.new_for_uri (todo_uri);
        var done_txt = File.new_for_uri (done_uri);
        bool todo_exists = todo_txt.query_exists ();
        bool done_exists = done_txt.query_exists ();

        if (todo_exists && done_exists) {
            done_txt.move (tmp_file, FileCopyFlags.OVERWRITE | FileCopyFlags.BACKUP, null, null);
            todo_txt.move (done_txt, FileCopyFlags.OVERWRITE, null, null);
            tmp_file.move (todo_txt, FileCopyFlags.OVERWRITE | FileCopyFlags.BACKUP, null, null);
        } else if (todo_exists) {
            todo_txt.move (done_txt, FileCopyFlags.OVERWRITE, null, null);
        } else if (done_exists) {
            done_txt.move (todo_txt, FileCopyFlags.OVERWRITE, null, null);
        }
    }

    private void perform_file_operations (ConflictChoices? file_operations) {
        string move_err_msg = _("An error was encountered while moving a file!");
        string move_err_info_msg =  _("Error information: ");
        foreach (var to_move in file_operations.get_replace_choices ()) {
            try {
                var src_file = File.new_for_uri (to_move.src_uri);
                var dst_file = File.new_for_uri (to_move.dst_uri);
                src_file.move (dst_file, FileCopyFlags.OVERWRITE | FileCopyFlags.BACKUP);
            } catch (Error e) {
                show_error_dialog (
                    @"$move_err_msg\n$move_err_info_msg\"$(e.message)\""
                );
            }
        }
        foreach (var to_swap in file_operations.get_swap_choices ()) {
            try {
                swap_todo_done (to_swap.src_uri, to_swap.dst_uri);
            } catch (Error e) {
                show_error_dialog (
                    @"$move_err_msg\n$move_err_info_msg\"$(e.message)\""
                );
            }
        }
    }

    public List<TodoListInfo> get_list_infos () {
        var infos = new List<TodoListInfo> ();
        foreach (var info in list_table.get_values ()) {
            infos.prepend(info);
        };
        return infos;
    }

    private void create_settings_instances () {
        foreach (var id in list_ids) {
            list_table[id] = new ListSettings.glib_settings (id);
        }
    }

    public bool has_id (string id) {
        return list_table.contains (id);
    }

    private bool is_valid_id (string id) {
        return /[\d[a-z][A-Z]]+(\-?[\d[a-z][A-Z]]+)*/.match(id, 0, null);
    }

    /**
     * Generates a new unique id.
     * The resulting id is the string representation of an unsigned integer.
     */
    public string get_new_id (string name) {
        uint id = str_hash (name);
        string id_str = id.to_string ();
        while (has_id (id_str)) {
            if (id < uint.MAX) {
                id++;
            } else {
                id = 0;
            }
            id_str = id.to_string ();
        }
        return id_str;
    }

    /**
     * Availability of the URIs must have been checked in advance
     */
    public void add_new (string name, string todo_uri, string done_uri, bool imported = true) {
        string id = get_new_id (name);
        var list_settings = new ListSettings.glib_settings (id);
        list_settings.name = name;
        list_settings.todo_uri = todo_uri;
        list_settings.done_uri = done_uri;

        // Do not add default tasks if the user already has an old list.
        list_settings.add_default_todos = add_default_todos && !imported;
        add_default_todos = false;

        add_listsettings (list_settings);
    }

    public void add_new_from_settings (ListSettings settings) {
        var to_add = new ListSettings.glib_settings (get_new_id (settings.name));
        to_add.apply (settings);
        to_add.add_default_todos = add_default_todos;
        add_default_todos = false;
        add_listsettings (to_add);
    }

    private void add_listsettings (ListSettings settings) {
        message ("Added new Todo.txt list: %s (%s)\n", settings.name, settings.id);
        list_table[settings.id] = settings;
        sync_list_ids ();

        var added = new List<TodoListInfo> ();
        added.prepend (settings);

        lists_added (added);
    }

    /***************************************************************************
     * dialogs
     */

    public TxtListEditDialog get_creation_dialog (Gtk.Window? parent) {
        var dialog = new TxtListEditDialog (parent, this);
        dialog.add_list_clicked.connect (on_dialog_list_add);
        return dialog;
    }

    private void on_dialog_list_add (TxtListEditDialog dialog, ListSettings lsettings, ConflictChoices? file_operations) {
        perform_file_operations (file_operations);
        add_new_from_settings (lsettings);
        dialog.destroy ();
    }

    public void delete_list (string id, Gtk.Window? window) {
        bool key_exists = false;
        var lsettings = list_table.take (id, out key_exists);
        list_ids = list_table.get_keys_as_array ();
        assert (key_exists);

        var removed = new List<string> ();
        removed.prepend (id);

        lists_removed (removed);
        sync_list_ids ();

        var dconf_settings = lsettings.stored_settings;
        lsettings.unbind ();
        lsettings = null;

        reset_dconf_path (dconf_settings);
    }

    /**
     * Attempt to reset the given path
     * from https://github.com/solus-project/budgie-desktop/blob/c6751695ffaad199761366efb9180d45a77b58b2/src/panel/manager.vala#L440
     */
    public void reset_dconf_path(Settings? settings) {
        if (settings == null) {
            return;
        }
        string path = settings.path;
        GLib.Settings.sync();
        if (settings.path == null) {
            return;
        }
        string argv[] = { "dconf", "reset", "-f", path};
        message("Resetting dconf path: %s", path);
        try {
            Process.spawn_command_line_sync(string.joinv(" ", argv), null, null, null);
        } catch (Error e) {
            warning("Failed to reset dconf path %s: %s", path, e.message);
        }
        GLib.Settings.sync();
    }

    public void edit_list (string id, Gtk.Window? window) {
        var info = list_table[id];
        assert (info != null);

        var dialog = new TxtListEditDialog (window, this, info.copy ());
        dialog.add_list_clicked.connect (on_dialog_list_edit);
        dialog.show_all ();
    }

    private void on_dialog_list_edit (TxtListEditDialog dialog, ListSettings lsettings, ConflictChoices? file_operations) {
        var info = list_table[lsettings.id];
        assert (info != null);

        perform_file_operations (file_operations);
        info.apply (lsettings);
        dialog.destroy ();
    }

    private void show_error_dialog (string msg) {
        var error_dialog = new Gtk.MessageDialog (
            null,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR,
            Gtk.ButtonsType.CLOSE,
            msg
        );
        error_dialog.show ();
    }
}

class GOFI.TXT.LegacyTxtListImport {
    private KeyFile key_file;
    private string list_file;
    private string config_dir;
    public bool first_run;

    public LegacyTxtListImport (string config_dir) {
        this.config_dir = config_dir;
        this.list_file = Path.build_filename (
            config_dir, "lists"
        );
        // Instantiate the key_file object
        key_file = new KeyFile ();
        first_run = true;

        if (!FileUtils.test (list_file, FileTest.EXISTS)) {
            int dir_exists = DirUtils.create_with_parents (
                config_dir, 0775
            );
            if (dir_exists != 0) {
                error (_("Couldn't create folder: %s"), config_dir);
            }
        } else {
            // If it does exist, read existing values
            first_run = false;
            try {
                key_file.load_from_file (list_file,
                   KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (Error e) {
                stderr.printf ("Reading %s failed", list_file);
                error ("%s", e.message);
            }
        }
    }

    public void import_settings_instances (HashTable<string, ListSettings> list_table) {
        foreach (string group in key_file.get_groups ()) {
            if (group.has_prefix ("list")) {
                var list_id = group.offset (4);
                if (list_id == "") {
                    warning ("Invalid list id stored in %s: '%s'", list_file, group);
                    continue;
                }
                var list_settings = import_settings_instance (list_id);
                if (list_settings != null) {
                    list_table[list_id] = list_settings;
                }
            }
        }
        return;
    }

    /**
     * Constructs a settings instance from the information stored in the key
     * file.
     */
    private ListSettings? import_settings_instance (string list_id) {
        var list_group = "list"+list_id;
        ListSettings list_settings = null;
        try {
            if (key_file.has_key (list_group, "name") && key_file.has_key (list_group, "location")) {
                var name = key_file.get_value (list_group, "name");
                var txt_dir = key_file.get_value (list_group, "location");
                list_settings = new ListSettings.glib_settings (list_id);
                list_settings.name = name;
                list_settings.todo_uri = Filename.to_uri (Path.build_filename (txt_dir, "todo.txt"));
                list_settings.done_uri = Filename.to_uri (Path.build_filename (txt_dir, "done.txt"));
            } else {
                return null;
            }
        } catch (Error e) {
            warning ("An error occured while importing list"
                +" %s: %s", list_group, e.message);
            return null;
        }

        try {
            list_settings.log_timer_in_txt = key_file.get_boolean (list_group, "log_timer_in_txt");
        } catch (Error e) {}
        try {
            list_settings.reminder_time = key_file.get_integer (list_group, "reminder_time");
        } catch (Error e) {}


        list_settings.schedule = import_schedule (list_group);

        return list_settings;
    }

    private Schedule? import_schedule (string list_group) {
        Schedule? schedule = null;

        try {
            var raw_sched_array = key_file.get_integer_list (list_group, "schedule");
            if (raw_sched_array.length >= 2 && raw_sched_array[0] > 0) {
                schedule = new Schedule ();
                schedule.import_raw (raw_sched_array);
            }
        } catch (Error e) {
            if (e is KeyFileError.KEY_NOT_FOUND) {
                int task_duration = -1;
                int break_duration = -1;

                try {
                    task_duration = key_file.get_integer (list_group, "task_duration");
                    break_duration = key_file.get_integer (list_group, "break_duration");
                } catch (Error e) {}

                if (task_duration > 0) {
                    if (break_duration <= 0) {
                        break_duration = 300;
                    }

                    schedule = new Schedule ();
                    schedule.import_raw ({task_duration, break_duration});
                }
            }
        }

        return schedule;
    }
}
