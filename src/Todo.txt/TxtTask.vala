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

using GOFI.TXT.TxtUtils;

/**
 * This class stores all task information.
 */
class GOFI.TXT.TxtTask : TodoTask {

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

    public DateTime? creation_date {
        public get;
        public set;
    }

    public DateTime? completion_date {
        public get;
        public set;
    }

    public char priority {
        public get;
        public set;
    }
    public const char NO_PRIO=127;

    public signal void done_changed ();

    public TxtTask (string line, bool done) {
        base (line);
        creation_date = null;
        completion_date = null;
        _done = done;
        priority = NO_PRIO;
    }

    public TxtTask.from_simple_txt (string descr, bool done) {
        base ("");
        creation_date = new GLib.DateTime.now_local ();
        completion_date = null;
        update_from_simple_txt (descr);
    }

    public TxtTask.from_todo_txt (string descr, bool done) {
        base ("");
        var parts = descr.split (" ");
        assert (parts.length != 0);
        var last = parts.length - 1;
        uint index = 0;

        if (parts[0] == "x") {
            done = true;
            index++;
        }
        _done = done;

        if (index <= last && is_priority (parts[index])) {
            priority = parts[index][1];
            index++;
        } else {
            priority = NO_PRIO;
        }

        if (index <= last && is_date (parts[index])) {
            if (done && index + 1 <= last && is_date (parts[index + 1])) {
                completion_date = string_to_date (parts[index]);
                creation_date = string_to_date (parts[index + 1]);
                index += 2;
            } else {
                completion_date = null;
                creation_date = string_to_date (parts[index]);
                index++;
            }
        } else {
            completion_date = null;
            creation_date = null;
        }

        if (index > last) {
            warning ("Task does not have a description: \"%s\"", descr);
            description = "";
            return;
        }

        (unowned string)[] unparsed = parts[index:parts.length];
        timer_value = consume_timer_value (unparsed);
        duration = consume_duration_value (unparsed);
        if (unparsed[0] == null) {
            warning ("Task does not have a description: \"%s\"", descr);
            description = "";
        } else {
            description = string.joinv (" ", unparsed).strip ();
        }
    }

    public void update_from_simple_txt (string descr) {
        var descr_parts = descr.split (" ");
        (unowned string)[] unparsed;

        if (descr_parts[0] != null && is_priority (descr_parts[0])) {
            priority = descr_parts[0][1];
            unparsed = descr_parts[1:descr_parts.length];
        } else {
            priority = NO_PRIO;
            unparsed = descr_parts;
        }

        // If descr_parts.length == 1 then unparsed will be null
        if (unparsed != null) {
          duration = consume_duration_value (unparsed);
        }

        description = string.joinv (" ", unparsed).strip ();
    }

    public string to_simple_txt () {
        string prio_str = (priority != NO_PRIO) ?  @"($priority) " : "";
        string duration_str = duration != 0 ? " duration:%um".printf (duration/60) : "";

        return prio_str + description + duration_str;
    }

    public string to_txt (bool log_timer) {
        string status_str = done ? "x " : "";
        string prio_str = (priority != NO_PRIO) ?  @"($priority) " : "";
        string comp_str = (completion_date != null) ? date_to_string (completion_date) + " " : "";
        string crea_str = (creation_date != null) ? date_to_string (creation_date) + " " : "";
        string timer_str = (log_timer && timer_value != 0) ? " timer:" + timer_to_string (timer_value) : "";
        string duration_str = duration != 0 ? " duration:%um".printf (duration/60) : "";

        return status_str + prio_str + comp_str + crea_str + description + timer_str + duration_str;
    }
}
