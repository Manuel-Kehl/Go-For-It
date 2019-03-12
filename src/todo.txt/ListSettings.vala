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

    public int task_duration {
        get;
        set;
        default = -1;
    }
    public int break_duration {
        get;
        set;
        default = -1;
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

    public ListSettings (string id, string name, string location) {
        this._id = id;
        this.name = name;
        this.todo_txt_location = location;
    }

    public ListSettings.empty () {
        this._id = null;
        this._name = null;
        this.todo_txt_location = null;
    }

    public ListSettings copy (string? new_id = null) {
        if(new_id == null) {
            new_id = _id;
        }
        var copied = new ListSettings (new_id, _name, todo_txt_location);
        copied.task_duration = task_duration;
        copied.break_duration = break_duration;
        copied.reminder_time = reminder_time;
        copied.add_default_todos = add_default_todos;
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
