/* Copyright 2016-2021 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

using GOFI.TXT.TxtUtils;

enum TxtPartType {
    TAG,
    WORD,
    PROJECT,
    CONTEXT,
    URI;
}

[Compact]
class TxtPart {
    public TxtPartType part_type;
    public string content;
    public string tag_name;

    public TxtPart.word (string word) {
        this.part_type = TxtPartType.WORD;
        this.content = word;
    }

    public TxtPart.tag (string tag_name, string tag_value) {
        this.part_type = TxtPartType.TAG;
        this.tag_name= tag_name;
        this.content = tag_value;
    }

    public TxtPart.context (string context) {
        this.part_type = TxtPartType.CONTEXT;
        this.content = context;
    }

    public TxtPart.project (string project) {
        this.part_type = TxtPartType.PROJECT;
        this.content = project;
    }

    public TxtPart.uri (string? uri_scheme, string uri_content) {
        this.part_type = TxtPartType.URI;
        this.content = uri_content;
        this.tag_name = uri_scheme;
    }
}

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
                    completion_date = new GOFI.Date (new GLib.DateTime.now_local ());
                } else {
                    completion_date = null;
                }
                _done = value;
                done_changed ();
            }
        }
    }
    private bool _done;

    public GOFI.Date? creation_date {
        public get;
        public set;
        default = null;
    }

    public GOFI.Date? completion_date {
        public get;
        public set;
        default = null;
    }

    public uint8 priority {
        public get;
        public set;
        default = NO_PRIO;
    }
    public const uint8 NO_PRIO=127;

    private void set_descr_parts (owned TxtPart[] parts) {
        _parts = (owned) parts;
        description = parts_to_description ();
    }
    public unowned TxtPart[] get_descr_parts () {
        return _parts;
    }
    private TxtPart[] _parts;


    public signal void done_changed ();

    public TxtTask (string line, bool done) {
        base (line);
        creation_date = null;
        completion_date = null;
        _done = done;
        priority = NO_PRIO;
        set_descr_parts (parse_description (line.split (" "), 0));
    }

    public TxtTask.from_simple_txt (string descr, bool done) {
        Object (
            done: false,
            creation_date: new Date (new GLib.DateTime.now_local ())
        );
        update_from_simple_txt (descr);
    }

    public TxtTask.from_todo_txt (string descr, bool done) {
        base ("");
        var parts = descr.split (" ");
        assert (parts[0] != null);
        uint index = 0;

        _done = parse_done (parts, ref index);
        parse_priority (parts, ref index);
        parse_dates (parts, ref index);

        set_descr_parts (parse_description (parts, index));

        if (description == "") {
            warning ("Task does not have a description: \"%s\"", descr);
            return;
        }
    }

    private inline bool parse_done (string[] parts, ref uint index) {
        if (parts[index] == "x") {
            index++;
            return true;
        }
        return false;
    }

    private inline void parse_priority (string[] parts, ref uint index) {
        if (parts[index] != null && is_priority (parts[index])) {
            priority = parts[index][1] - 65;
            index++;
        } else {
            priority = NO_PRIO;
        }
    }

    private inline GOFI.Date? try_parse_date (string[] parts, ref uint index) {
        uint _index = index;
        if (parts[_index] != null && is_date (parts[_index])) {
            index++;
            return string_to_date (parts[_index]);
        }
        return null;
    }

    private inline void parse_dates (string[] parts, ref uint index) {
        GOFI.Date? date1 = try_parse_date (parts, ref index);
        GOFI.Date? date2 = null;

        if (date1 != null && _done && (date2 = try_parse_date (parts, ref index)) != null) {
            creation_date = date2;
            completion_date = date1;
        } else {
            creation_date = date1;
            completion_date = null;
        }
    }

    private TxtPart tokenize_descr_part (string p) {
        if (is_project_tag (p)) {
            return new TxtPart.project (p.offset (1));
        } else if (is_context_tag (p)) {
            return new TxtPart.context (p.offset (1));
        } else {
            var colon_pos = p.index_of_char (':');
            if (colon_pos > 0 && p.get_char (colon_pos + 1).isgraph ()) {
                var tag_key = p.slice (0, colon_pos);
                var tag_value = p.offset (colon_pos + 1);
                if (is_common_uri_tag (tag_key)) {
                    return new TxtPart.uri (tag_key, tag_value);
                }
                if (tag_value.data[0] == '/' &&
                    tag_value.data[1] == '/' &&
                    tag_value.data[2] != 0
                ) {
                    return new TxtPart.uri (tag_key, tag_value);
                }
                if (tag_value.index_of_char (':') == -1) {
                    return new TxtPart.tag (tag_key, tag_value);
                }
            }
        }
        return new TxtPart.word (p);
    }

    private TxtPart[] parse_description (string[] unparsed, uint offset) {
        string? p;
        TxtPart[] parsed_parts = {};

        for (p=unparsed[offset]; p != null; offset++, p=unparsed[offset]) {
            var t = tokenize_descr_part (p);
            if (t.part_type == TxtPartType.TAG) {
                switch (t.tag_name) {
                    case "timer":
                        uint new_timer_value = 0;
                        if (match_duration_value (t.content, out new_timer_value)) {
                            timer_value = new_timer_value;
                            continue;
                        }
                        break;
                    case "duration":
                        uint new_duration = 0;
                        if (match_duration_value (t.content, out new_duration)) {
                            duration = new_duration;
                            continue;
                        }
                        break;
                }
            }
            parsed_parts += (owned) t;
        }

        return parsed_parts;
    }

    public void update_from_simple_txt (string descr) {
        var parts = descr.split (" ");
        if (parts[0] == null) {
            description = "";
            priority = NO_PRIO;
            return;
        }
        uint index = 0;

        parse_priority (parts, ref index);

        duration = 0;
        set_descr_parts (parse_description (parts, index));
    }

    public string parts_to_description () {
        var descr_builder = new StringBuilder.sized (100);
        bool add_leading_space = false;
        foreach (unowned TxtPart p in _parts) {
            if (add_leading_space) {
                descr_builder.append_c (' ');
            }
            add_leading_space = true;

            // Adding tag prefix
            switch (p.part_type) {
                case TxtPartType.TAG:
                    descr_builder.append (p.tag_name);
                    descr_builder.append_c (':');
                    break;
                case TxtPartType.PROJECT:
                    descr_builder.append_c ('+');
                    break;
                case TxtPartType.CONTEXT:
                    descr_builder.append_c ('@');
                    break;
                case TxtPartType.URI:
                    if (p.tag_name != null && p.tag_name != "") {
                        descr_builder.append (p.tag_name);
                        descr_builder.append_c (':');
                    }
                    break;
                default:
                    break;
            }

            descr_builder.append (p.content);
        }
        return descr_builder.str;
    }

    private void append_duration (uint duration, StringBuilder builder) {
        uint hours, minutes, seconds;
        bool append_hyphen = false;

        Utils.uint_to_time (duration, out hours, out minutes, out seconds);

        if (hours > 0) {
            builder.append_printf ("%uh", hours);
            append_hyphen = true;
        }
        if (minutes > 0) {
            if (append_hyphen) {
                builder.append_c ('-');
            }
            builder.append_printf ("%um", minutes);
            append_hyphen = true;
        }
        if (seconds > 0) {
            if (append_hyphen) {
                builder.append_c ('-');
            }
            builder.append_printf ("%us", seconds);
        }
    }

    public string to_simple_txt () {
        StringBuilder str_builder = new StringBuilder.sized (80);
        append_priority (str_builder);
        str_builder.append (description);
        if (duration > 0) {
            str_builder.append (" duration:");
            append_duration (this.duration, str_builder);
        }

        return str_builder.str;
    }

    private void append_priority (StringBuilder builder) {
        if (priority >= NO_PRIO) {
            return;
        } else {
            builder.append_printf ("(%c) ", (char) priority + 65);
        }
    }

    public string to_txt (bool log_timer) {
        var str_builder = new StringBuilder.sized (100);
        if (done) {
            str_builder.append ("x ");
        }

        append_priority (str_builder);

        if (creation_date != null) {
            str_builder.append (dt_to_string (creation_date.dt));
            str_builder.append_c (' ');

            if (completion_date != null) {
                str_builder.append (dt_to_string (completion_date.dt));
                str_builder.append_c (' ');
            }
        }

        str_builder.append (description);

        if (log_timer && timer_value != 0) {
            str_builder.append (" timer:");
            str_builder.append (timer_to_string (timer_value));
        }

        if (duration != 0) {
            str_builder.append (" duration:");
            append_duration (duration, str_builder);
        }

        return str_builder.str;
    }

    public int cmp (TxtTask other) {
        if (other == this) {
            return 0;
        }
        if (this.priority == other.priority) {
            int cmp_tmp;

            // Sort by description, case insensitive
            cmp_tmp = this.description.ascii_casecmp (other.description);
            if (cmp_tmp != 0) {
                return cmp_tmp;
            }

            // Sort by description, case sensitive
            cmp_tmp = GLib.strcmp (this.description, other.description);
            if (cmp_tmp != 0) {
                return cmp_tmp;
            }

            // Sort by creation date
            if (this.creation_date != null) {
                if (other.creation_date != null) {
                    cmp_tmp = this.creation_date.compare (other.creation_date);
                }
            }

            // Last option: sort by memory address
            if (((void*) this) > ((void*) other)) {
                return 1;
            }

            return -1;
        }
        if (this.priority == NO_PRIO) {
            return 1;
        }
        if (other.priority == NO_PRIO) {
            return -1;
        }
        if (this.priority > other.priority) {
            return 1;
        }
        return -1;
    }
}
