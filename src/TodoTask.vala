/* Copyright 2016-2017 Go For It! developers
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
 * This class stores all task information.
 */
public class GOFI.TodoTask : GLib.Object {
    public string description {
        public get {
            return _description;
        }
        public set {
            _description = value;
            data_changed ();
        }
    }
    string _description;

    public bool done {
        public get {
            return _done;
        }
        public set {
            if (_done != value) {
                if (value && creation_date != null) {
                    completion_date = new GLib.DateTime.now_local ();
                } else {
                    completion_date = null;
                }
                _done = value;
                done_changed ();
            }
        }
    }
    private bool _done;

    public bool valid {
        get {
            return description != "";
        }
    }

    public DateTime? creation_date {
        public get;
        public set;
    }

    public DateTime? completion_date {
        public get;
        public set;
    }

    public string? priority {
        public get;
        public set;
    }

    public signal void done_changed ();
    public signal void data_changed ();

    public TodoTask (string line, bool done) {
        creation_date = null;
        completion_date = null;
        _done = done;
        _description = line;
    }
}
