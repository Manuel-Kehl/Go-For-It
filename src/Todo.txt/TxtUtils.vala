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
namespace GOFI.TXT.TxtUtils {
    /**
     * Checks whether token is a date in the todo.txt format.
     */
    public static bool is_date (string token) {
        MatchInfo info;
        return /\d\d\d\d-\d\d-\d\d/.match(token, 0, out info);
    }

    /**
     * Checks whether token is a priority in the todo.txt format.
     */
    public static bool is_priority (string token) {
        MatchInfo info;
        return /\([A-Z]\)/.match(token, 0, out info);
    }

    /**
     * Checks whether token is a project tag in the todo.txt format.
     */
    public static bool is_project_tag (string token) {
        return token.get (0) == '+' && token.get_char (1).isgraph ();
    }

    /**
     * Checks whether token is a context tag in the todo.txt format.
     */
    public static bool is_context_tag (string token) {
        return token.get (0) == '@' && token.get_char (1).isgraph ();
    }

    public static bool is_timer_value (string token) {
        MatchInfo info;
        return /timer:([0-9]+)h-([0-9]+)m-([0-9]+)s/.match(token, 0, out info);
    }

    /**
     * Removes x from the start of finished tasks
     */
    public static bool consume_status (ref string txt_line) {
        bool done = txt_line.has_prefix ("x ");

        if (done) {
            // Remove "x " from displayed string
            txt_line = txt_line.substring (2);
        }

        return done;
    }

    /**
     * Removes and returns the priority from pseudo descriptions (task lines
     * consisting of at most a priority and a description)
     */
    public static char consume_priority (ref string pseudo_description) {
        string[] parts = pseudo_description.split(" ", 2);
        if (parts[1] != null && is_priority(parts[0])) {
            pseudo_description = parts[1];
            return parts[0][1];
        } else {
            return TxtTask.NO_PRIO;
        }
    }

    /**
     * Parses a timer value if present in the description parts.
     * If a timer value is encountered it is removed from the description by
     * clearing that part of the description.
     */
    public static uint consume_timer_value (string[] description) {
        uint timer_val = 0;
        for (int i = 0; description[i] != null; i++) {
            if (is_timer_value (description[i])) {
                timer_val = string_to_timer (description[i].offset(6));
                description[i] = "";
                return timer_val;
            }
        }
        return timer_val;
    }

    public static DateTime string_to_date (string date_txt) {
        string[] date_parts = date_txt.split ("-", 3);
        return new DateTime.local (
            int.parse(date_parts[0]),
            int.parse(date_parts[1]),
            int.parse(date_parts[2]),
            0, 0, 0
        );
    }

    public static string date_to_string (DateTime date) {
        return date.format ("%Y-%m-%d");
    }

    public static string timer_to_string (uint timer_val) {
        uint secs, mins, hours;

        secs = timer_val % 60;
        timer_val = timer_val / 60;
        mins = timer_val % 60;
        timer_val = timer_val / 60;
        hours = timer_val;

        return "%uh-%um-%us".printf (hours, mins, secs);
    }

    public static uint string_to_timer (string timer_str) {
        string[] parts = timer_str.split("-", 3);
        return (uint) (
            uint64.parse(parts[0]) * 3600 +
            uint64.parse(parts[1]) * 60 +
            uint64.parse(parts[2])
        );
    }
}
