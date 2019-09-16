/* Copyright 2016-2019 Go For It! developers
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
    public virtual string description {
        public get {
            return _description;
        }
        public set {
            _description = value;
        }
    }
    string _description;

    public virtual bool valid {
        get {
            return description != "";
        }
    }

    public virtual uint timer_value {
        public get;
        public set;
    }

    public TodoTask (string line) {
        _description = line;
        timer_value = 0;
    }
}
