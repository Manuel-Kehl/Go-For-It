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
class GOFI.TXT.ListSettings : Object, TodoListInfo {

    public string id {
        get {
            return _id;
        }
    }
    string _id;

    public string plugin_name {
        get {
            return GOFI.TXT.PLUGIN_NAME;
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

    public int task_duration {
        get;
        set;
    }
    public int break_duration {
        get;
        set;
    }
    public int reminder_time {
        get;
        set;
    }

    public ListSettings (string id, string name, string location) {
        this._id = id;
        this.name = name;
        this.todo_txt_location = location;

        this.task_duration = -1;
        this.break_duration = -1;
        this.reminder_time = -1;
    }

    public ListSettings.empty () {
        this._id = null;
        this._name = null;
        this.todo_txt_location = null;

        this.task_duration = -1;
        this.break_duration = -1;
        this.reminder_time = -1;
    }

    public ListSettings copy () {
        var copied = new ListSettings (_id, _name, todo_txt_location);
        copied.task_duration = task_duration;
        copied.break_duration = break_duration;
        copied.reminder_time = reminder_time;
        return copied;
    }

    public void apply (ListSettings settings) {
        this.name = settings.name;
        this.todo_txt_location = settings.todo_txt_location;

        this.task_duration = settings.task_duration;
        this.break_duration = settings.break_duration;
        this.reminder_time = settings.reminder_time;
    }
}
