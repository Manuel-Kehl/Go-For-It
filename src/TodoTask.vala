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
 * This class stores all task information that should be known to the timer.
 */
public class TodoTask : GLib.Object {
    public string title {
        public get;
        public set;
    }

    public bool done {
        public get {
            return _done;
        }
        public set {
            if (_done != value) {
                _done = value;
                status_changed ();
            }
        }
    }
    private bool _done;

    public signal void status_changed ();

    public TodoTask (string title, bool done) {
        this.title = title;
        this._done = done;
    }

    public string to_string () {
        return (done ? "x " : "") + title;
    }
}
