/* Copyright 2018-2021 GoForIt! developers
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
namespace GOFI.TXT.TxtUtils {
    /**
     * Checks whether token is a date in the todo.txt format.
     */
    public static bool is_date (string token) {
        MatchInfo info;
        return /\d\d\d\d-\d\d-\d\d/.match (token, 0, out info);
    }

    /**
     * Checks whether token is a priority in the todo.txt format.
     */
    public static bool is_priority (string token) {
        MatchInfo info;
        return /\([A-Z]\)/.match (token, 0, out info); // vala-lint=space-before-paren
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

    public static bool is_common_uri_tag (string str) {
        switch (str) {
            case "mailto":
            case "tel":
            case "sms":
              return true;
            default:
              return false;
        }
    }

    /**
     * parse value of the form /([0-9]+)h-([0-9]+)m-([0-9]+)s/ where the
     * h, m and s groups are all optional and the input string is not empty.
     */
    public static bool match_duration_value (string duration_str, out uint duration_value) {
        long index = 0;
        long lower = 0;
        duration_value = 0;

        for (; duration_str[index].isdigit (); index++) {}
        if (duration_str[index] == 'h') {
            duration_value = 3600 * (uint) int.parse (duration_str.offset (lower));
            index++;
            if (duration_str[index] == '-') {
                for (lower = ++index; duration_str[index].isdigit (); index++) {}
            } else {
                return duration_str[index] == '\0';
            }
        }
        if (duration_str[index] == 'm') {
            duration_value += 60 * (uint) int.parse (duration_str.offset (lower));
            index++;
            if (duration_str[index] == '-') {
                for (lower = ++index; duration_str[index].isdigit (); index++) {}
            } else {
                return duration_str[index] == '\0';
            }
        }
        if (duration_str[index] == 's') {
            duration_value += (uint) int.parse (duration_str.offset (lower));
            return duration_str[index + 1] == '\0';
        }
        return duration_str[index] == '\0' && index != 0;
    }

    public static Date string_to_date (string date_txt) {
        string[] date_parts = date_txt.split ("-", 3);
        return new GOFI.Date.from_ymd (
            int.parse (date_parts[0]),
            int.parse (date_parts[1]),
            int.parse (date_parts[2])
        );
    }

    public static string dt_to_string (DateTime date) {
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
        string[] parts = timer_str.split ("-", 3);
        return (uint) (
            uint64.parse (parts[0]) * 3600 +
            uint64.parse (parts[1]) * 60 +
            uint64.parse (parts[2])
        );
    }
}
