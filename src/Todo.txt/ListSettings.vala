/* Copyright 2018-2019 Go For It! developers
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
 * Object used to keep track of the settings of a single todo.txt list
 */
class GOFI.TXT.ListSettings : Object, TodoListInfo {

    const string ID_TODO_TXT_LIST = GOFI.APP_ID + ".todo-txt.list";
    const string KEY_SCHEDULE = "schedule";
    const string KEY_REMINDER_TIME = "reminder-time";
    const string KEY_TODO_URI = "todo-list-uri";
    const string KEY_DONE_URI = "done-list-uri";
    const string KEY_LOG_TIMER = "log-timer-in-txt";
    const string KEY_NAME = "name";

    public GLib.Settings stored_settings {
        construct set;
        public get;
    }

    public string id {
        construct set;
        public get;
    }

    public string provider_name {
        get {
            return GOFI.TXT.PROVIDER_NAME;
        }
    }

    public string name {
        get;
        set;
    }

    public string todo_uri {
        get;
        set;
    }
    public string done_uri {
        get;
        set;
    }

    public Schedule? schedule {
        get {
            return _schedule;
        }
        set {
            if (value.valid) {
                _schedule = value;
            } else {
                _schedule = null;
            }
            save_schedule ();
        }
    }
    Schedule? _schedule;
    public int reminder_time {
        get;
        set;
        default = -1;
    }
    public bool add_default_todos {
        get;
        set;
        default = false;
    }

    public bool log_timer_in_txt {
        get;
        set;
        default = false;
    }

    public string? schema_path {
        owned get {
            if (id == null) {
                return null;
            }
            return (GOFI.SCHEMA_PATH + "/backends/todo-txt/" + id);
        }
    }

    public ListSettings (string id, string name, string todo_uri, string done_uri) {
        Object (
            id: id
        );
        this.name = name;
        this.todo_uri = todo_uri;
        this.done_uri = done_uri;
        this.schedule = null;
    }

    public ListSettings.glib_settings (string id) {
        this._id = id;
        var settings = new GLib.Settings.with_path (ID_TODO_TXT_LIST, schema_path);

        Object (
            id: id,
            stored_settings: settings
        );
        bind_stored ();
        load_schedule ();
    }

    public ListSettings.empty () {
        this.name = null;
        this.todo_uri = null;
        this.done_uri = null;
        this.schedule = null;
    }

    public ListSettings copy (string? new_id = null) {
        if(new_id == null) {
            new_id = id;
        }
        var copied = new ListSettings (new_id, name, todo_uri, done_uri);
        copied.reminder_time = reminder_time;
        copied.add_default_todos = add_default_todos;
        copied.log_timer_in_txt = log_timer_in_txt;
        if (schedule != null) {
            copied.schedule = new Schedule ();
            copied.schedule.import_raw (this.schedule.export_raw ());
        }
        return copied;
    }

    public void apply (ListSettings lsettings) {
        this.name = lsettings.name;
        this.todo_uri = lsettings.todo_uri;
        this.done_uri = lsettings.done_uri;

        if (lsettings.schedule == null) {
            this.schedule = null;
        } else {
            var sched = new Schedule ();
            sched.import_raw (lsettings.schedule.export_raw ());
            this.schedule = sched;
        }
        this.reminder_time = lsettings.reminder_time;
        this.log_timer_in_txt = lsettings.log_timer_in_txt;
    }

    public void set_backend (GLib.Settings backend) {
        this.stored_settings = backend;
        bind_stored ();
        load_schedule ();
    }

    private void bind_stored () {
        var sbf = GLib.SettingsBindFlags.DEFAULT;
        stored_settings.bind (KEY_TODO_URI, this, "todo_uri", sbf);
        stored_settings.bind (KEY_DONE_URI, this, "done_uri", sbf);
        stored_settings.bind (KEY_REMINDER_TIME, this, "reminder_time", sbf);
        stored_settings.bind (KEY_LOG_TIMER, this, "log_timer_in_txt", sbf);
        stored_settings.bind (KEY_NAME, this, "name", sbf);
    }

    private void load_schedule () {
        var sched = new Schedule ();
        sched.load_variant (stored_settings.get_value (KEY_SCHEDULE));
        if (sched.valid) {
            _schedule = sched;
        } else {
            _schedule = null;
        }
    }
    private void save_schedule () {
        if (stored_settings == null) {
            return;
        }
        Variant to_save;
        if (_schedule != null) {
            to_save = _schedule.to_variant ();
        } else {
            to_save = new Schedule ().to_variant ();
        }
        stored_settings.set_value (KEY_SCHEDULE, to_save);
    }
}
