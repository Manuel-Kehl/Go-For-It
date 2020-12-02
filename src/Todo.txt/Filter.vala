/* Copyright 2017-2019 Go For It! developers
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
    private List<TxtPart> search_parts;
    private PrioConstraint? priority_constraint;

    public Filter () {
        search_parts = new List<TxtPart> ();
    }

    private enum PrioConstrType {
        LESS,
        GREATER,
        LESS_OR_EQUAL,
        GREATER_OR_EQUAL,
        EQUAL,
        BETWEEN
    }

    [Compact]
    private class PrioConstraint {
        public uint8 p1;
        public uint8 p2;
        public PrioConstrType pc_type;

        public PrioConstraint (PrioConstrType pc_type, uint8 p1, uint8 p2=0) {
            if (p1 > p2) {
                this.p1 = p1;
                this.p2 = p2;
            } else {
                this.p1 = p2;
                this.p2 = p1;
            }

            this.pc_type = pc_type;
        }
    }

    public void parse (string filter_string) {
        search_parts = new List<TxtPart> ();
        priority_constraint = null;

        string[] parts = filter_string.casefold ().split (" ");

        string project_pre = _("project").casefold () + ":";
        string context_pre = _("context").casefold () + ":";
        string priority_pre = _("priority").casefold () + ":";

        foreach (string part in parts) {
            if (part == "") {
                continue;
            }
            if (part.has_prefix (project_pre)) {
                string? project = part.split (":", 2)[1];
                if (project != null && project != "") {
                    search_parts.prepend (new TxtPart.project (project));
                }
            } else if (part.has_prefix (context_pre)) {
                string? context = part.split (":", 2)[1];
                if (context != null && context != "") {
                    search_parts.prepend (new TxtPart.context (context));
                }
            } else if (part.has_prefix (priority_pre)) {
                parse_priority_contstraint (part);
            } else {
                var key_value = part.split (":", 2);
                if (key_value[1] != null && key_value[1] != "") {
                    search_parts.prepend (new TxtPart.tag (key_value[0], key_value[1]));
                } else {
                    search_parts.prepend (new TxtPart.word (part));
                }
            }
        }
    }

    private void parse_priority_contstraint (string part) {
        string? priority = part.split (":", 2)[1];
        if (priority != null && priority[0] != '\0') {
            var offset = 0;
            var pc_type = PrioConstrType.EQUAL;
            if (priority[0] == '>') {
                if (priority[1] == '=') {
                    pc_type = PrioConstrType.GREATER_OR_EQUAL;
                    offset = 2;
                } else {
                    pc_type = PrioConstrType.GREATER;
                    offset = 1;
                }
            } else if (priority[0] == '<') {
                if (priority[1] == '=') {
                    pc_type = PrioConstrType.LESS_OR_EQUAL;
                    offset = 2;
                } else {
                    pc_type = PrioConstrType.LESS;
                    offset = 1;
                }
            }
            var offset_prio = priority.offset (offset);
            if (offset_prio[0] < 'a' || offset_prio[0] > 'z') {
                //TODO: highlight mistake?
                return;
            }
            uint8 prio1 = offset_prio[0] - 97;

            if (offset_prio[1] == '\0') {
                priority_constraint = new PrioConstraint (pc_type, prio1);
            } else if (pc_type == PrioConstrType.EQUAL && offset_prio[1] == '-') {
                if (offset_prio[2] >= 'a' && offset_prio[2] <= 'z' && offset_prio[3] == '\0') {
                    pc_type = PrioConstrType.BETWEEN;
                    uint8 prio2 = offset_prio[2] - 97;
                    priority_constraint = new PrioConstraint (pc_type, prio1, prio2);
                }
            } else {
                //TODO: highlight mistake?
                return;
            }
        }
    }

    private inline bool part_match (TxtPart search_part, TxtPart task_part) {
        if (task_part.part_type != search_part.part_type) {
            return false;
        }
        if (task_part.part_type == TxtPartType.TAG &&
            task_part.tag_name.casefold () != search_part.tag_name) {
            return false;
        }
        return task_part.content.casefold ().contains (search_part.content);
    }

    private inline bool check_prio (TxtTask task) {
        if (priority_constraint != null) {
            switch (priority_constraint.pc_type) {
                case PrioConstrType.LESS:
                    return task.priority > priority_constraint.p1;
                case PrioConstrType.GREATER:
                    return task.priority < priority_constraint.p1;
                case PrioConstrType.LESS_OR_EQUAL:
                    return task.priority >= priority_constraint.p1;
                case PrioConstrType.GREATER_OR_EQUAL:
                    return task.priority <= priority_constraint.p1;
                case PrioConstrType.BETWEEN:
                    return task.priority <= priority_constraint.p1 && task.priority >= priority_constraint.p2;
                default:
                    return task.priority == priority_constraint.p1;
            }
        }
        return true;
    }

    // Not the most efficient filtering implementation, but it should suffice
    public bool filter (DragListRow _row) {
        assert (this != null);
        var row = _row as TaskRow;
        var task = row.task;

        if (!check_prio (task)) {
            return false;
        }

        string title = task.description.casefold ();
        unowned TxtPart[] task_parts = task.get_descr_parts ();

        foreach (unowned TxtPart search_part in search_parts) {
            switch (search_part.part_type) {
                case TxtPartType.WORD:
                    if (!title.contains (search_part.content)) {
                        return false;
                    }
                    break;
                default:
                    bool matches = false;
                    foreach (unowned TxtPart task_part in task_parts) {
                        if (part_match (search_part, task_part)) {
                            matches = true;
                            break;
                        }
                    }
                    if (!matches) {
                        return false;
                    }
                    break;
            }
        }

        return true;
    }
}
