namespace GOFI.TxtUtils {
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
        return token.get (0) == '+' && token.get (1) > 33;
    }

    /**
     * Checks whether token is a context tag in the todo.txt format.
     */
    public static bool is_context_tag (string token) {
        return token.get (0) == '@' && token.get (1) > 33;
    }

    /**
     * Removes x from the start of finished tasks
     */
    public static bool consume_status (ref string txt_line) {
        bool done = txt_line.has_prefix ("x ");

        if (done) {
            // Remove "x " from displayed string
            txt_line = txt_line.split ("x ", 2)[1];
        }

        return done;
    }

    /**
     * Removes and returns the priority from pseudo descriptions (task lines 
     * consisting of at most a priority and a description)
     */
    public static string? consume_priority (ref string pseudo_description) {
        string[] parts = pseudo_description.split(" ", 2);
        if (parts[1] != null && is_priority(parts[0])) {
            pseudo_description = parts[1];
            return parts[0];
        } else {
            return null;
        }
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
}
