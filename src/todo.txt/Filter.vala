/* Copyright 2017 Go For It! developers
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

class GOFI.TXT.Filter {
    private List<string> tags;
    private List<string> sentence_pieces;
    private List<string> priority_constraints;

    public Filter () {
        tags = new List<string> ();
        sentence_pieces = new List<string> ();
    }

    public void parse (string filter_string) {
        tags = new List<string> ();
        sentence_pieces = new List<string> ();
        priority_constraints = new List<string> ();

        string sentence_piece = "";

        string[] parts = filter_string.split (" ");

        foreach (string part in parts) {
            if (part == "") {
                continue;
            }
            if (part.has_prefix (_("project") + ":")) {
                string? project = part.split (":", 2)[1];
                if (project != null && project != "") {
                    tags.prepend ("+" + project);
                    add_sentence_piece (sentence_piece);
                }
            } else if (part.has_prefix (_("context") + ":")) {
                string? context = part.split (":", 2)[1];
                if (context != null && context != "") {
                    tags.prepend ("@" + context);
                    add_sentence_piece (sentence_piece);
                }
            } else if (part.has_prefix (_("priority") + ":")) {
                string? priority = part.split (":", 2)[1];
                if (priority != null && priority[0] != '\0') {
                    if (priority[0] >= 'A' && priority[0] <= 'Z') {
                        if (priority[1] == '\0') {
                            priority_constraints.prepend(priority);
                        } else if (priority.offset(1) == "+" || priority.offset(1) == "-") {
                            priority_constraints.prepend(priority);
                        }
                    } else {
                        //TODO: highlight mistake?
                        continue;
                    }
                }

            } else {
                sentence_piece += " " + part.casefold ();
            }
        }
        add_sentence_piece (sentence_piece);
    }

    private void add_sentence_piece (string sentence_piece) {
        if (sentence_piece == "") {
            return;
        }

        sentence_pieces.prepend (sentence_piece.chug ());
    }

    /**
     * Checks if filter_string is a substring with the following extra
     * properties: if title doesn't start with filter_string a space must
     * preceed it, and if title doesn't end with it a space must succeed it.
     */
    private bool contains_tag (string title, string filter_string) {
        int index, title_length, search_length;

        index = title.index_of (filter_string);

        if (index >= 0) {
            if (index > 0) {
                if (title.get (index - 1) != ' ') {
                    return false;
                }
            }
            title_length = title.length;
            search_length = filter_string.length;
            if (index + search_length < title_length) {
                return (title.get (index + search_length) == ' ');
            }
            return true;
        }
        return false;
    }

    public bool filter (DragListRow _row) {
        assert (this != null);
        var row = _row as TaskRow;
        var task = row.task;

        foreach (string tag in tags) {
            if (!contains_tag (task.description, tag)) {
                return false;
            }
        }

        string title = task.description.casefold ();

        foreach (string sentence_piece in sentence_pieces) {
            if (!title.contains (sentence_piece)) {
                return false;
            }
        }

        foreach (string prio_constraint in priority_constraints) {
            if (prio_constraint[1] == '+') {
                if (task.priority < prio_constraint[0]) {
                    return false;
                }
            } else if (prio_constraint[1] == '-') {
                if (task.priority > prio_constraint[0]) {
                    return false;
                }
            } else if (task.priority != prio_constraint[0]) {
                return false;
            }
        }

        return true;
    }
}
