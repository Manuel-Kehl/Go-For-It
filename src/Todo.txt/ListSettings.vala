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

    public string id {
        get {
            return _id;
        }
    }
    string _id;

    public string provider_name {
        get {
            return GOFI.TXT.PROVIDER_NAME;
        }
    }

    public string name {
        get;
        set;
    }

    public string todo_txt_location {
        get;
        set;
    }

    public Schedule? schedule {
        get;
        set;
    }
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

    public ListSettings (string id, string name, string location) {
        this._id = id;
        this.name = name;
        this.todo_txt_location = location;
        this.schedule = null;
    }

    public ListSettings.empty () {
        this._id = null;
        this._name = null;
        this.todo_txt_location = null;
        this.schedule = null;
    }

    public ListSettings copy (string? new_id = null) {
        if(new_id == null) {
            new_id = _id;
        }
        var copied = new ListSettings (new_id, _name, todo_txt_location);
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
        this.todo_txt_location = lsettings.todo_txt_location;

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
}
