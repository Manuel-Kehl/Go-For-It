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
public class TodoTask : GLib.Object {
    public string title {
        public get {
            return _title;
        }
        public set {
            _title = value;
            data_changed ();
        }
    }
    string _title;

    public bool done {
        public get {
            return _done;
        }
        public set {
            if (_done != value) {
                if (value) {
                    _title = GOFI.Utils.prepend_today(GOFI.Utils.remove_priority(_title));
                } else {
                    string[] parts = _title.split(" ");
                    if (GOFI.Utils.is_date(parts[0])) {
                        _title = string.joinv(" ", parts[1:parts.length]);
                    }
                }
                _done = value;
                done_changed ();
            }
        }
    }
    private bool _done;

    public bool valid {
        get {
            return title != "";
        }
    }

    public signal void done_changed ();
    public signal void data_changed ();

    public TodoTask (string title, bool done) {
        _title = title;
        _done = done;
    }
}
