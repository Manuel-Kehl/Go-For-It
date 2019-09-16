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

using GOFI.TXT.TxtUtils;

class GOFI.TXT.TaskRow: DragListRow {
    private Gtk.CheckButton check_button;
    private Gtk.Button delete_button;
    private TaskMarkupLabel markup_label;
    private TaskEditEntry edit_entry;
    private bool editing;
    private bool focus_cooldown_active;

    public bool is_editing {
        get {
            return editing;
        }
    }

    public TxtTask task {
        get;
        private set;
    }

    public signal void link_clicked (string uri);
    public signal void deletion_requested ();

    public TaskRow (TxtTask task) {
        this.task = task;

        edit_entry = null;
        editing = false;
        focus_cooldown_active = false;
        markup_label = new TaskMarkupLabel (task);

        check_button = new Gtk.CheckButton ();
        check_button.active = task.done;

        set_start_widget (check_button);
        set_center_widget (markup_label);

        connect_signals ();
        show_all ();
    }

    public void edit () {
        if (edit_entry != null) {
            return;
        }
        delete_button = new Gtk.Button.from_icon_name ("edit-delete", Gtk.IconSize.MENU);
        delete_button.relief = Gtk.ReliefStyle.NONE;
        delete_button.show_all ();
        delete_button.clicked.connect (on_delete_button_clicked);
        set_start_widget (delete_button);

        edit_entry = new TaskEditEntry (task.description, task.priority);
        set_center_widget (edit_entry);

        edit_entry.edit ();
        edit_entry.strings_changed.connect (on_edit_entry_strings_changed);
        edit_entry.editing_finished.connect (on_edit_entry_finished);
        editing = true;
    }

    private void on_delete_button_clicked () {
        deletion_requested ();
    }

    private void on_edit_entry_strings_changed () {
        task.description = edit_entry.description;
        task.priority = edit_entry.priority;
    }

    private void on_edit_entry_finished () {
        stop_editing ();
    }

    /**
     * Using a cooldown to work around a Gtk issue:
     * The ListBoxRow will steal focus again after activating and in addition
     * to that for a moment neither the row nor the entry may have focus.
     * We give everything a moment to settle and stop editing as soon as neither
     * this row or the entry has focus.
     */
    private bool on_focus_out () {
        if(focus_cooldown_active | !editing) {
            return false;
        }
        focus_cooldown_active = true;
        GLib.Timeout.add(
            50, focus_cooldown_end, GLib.Priority.DEFAULT_IDLE
        );
        return false;
    }

    private bool focus_cooldown_end () {
        focus_cooldown_active = false;
        if (!editing) {
            return false;
        }
        if (!has_focus && get_focus_child () == null) {
            stop_editing ();
            return false;
        }
        return GLib.Source.REMOVE;
    }

    public void stop_editing () {
        if (!editing) {
            return;
        }
        var had_focus = edit_entry.has_focus;
        set_center_widget (markup_label);
        set_start_widget (check_button);
        delete_button = null;
        edit_entry = null;
        editing = false;
        if (had_focus) {
            grab_focus();
        }
    }

    private bool on_row_key_release (Gdk.EventKey event) {
        switch (event.keyval) {
            case Gdk.Key.Delete:
                if (!editing || !edit_entry.has_focus) {
                    deletion_requested ();
                    return true;
                }
                break;
            case Gdk.Key.Escape:
                if (editing) {
                    stop_editing ();
                    return true;
                }
                break;
            default:
                return false;
        }
        return false;
    }

    private void connect_signals () {
        check_button.toggled.connect (on_check_toggled);
        task.done_changed.connect (on_task_done_changed);
        markup_label.activate_link.connect (on_activate_link);
        set_focus_child.connect (on_set_focus_child);
        focus_out_event.connect (on_focus_out);
        key_release_event.connect (on_row_key_release);
    }

    private void on_check_toggled () {
        task.done = !task.done;
    }

    private void on_task_done_changed () {
        destroy ();
    }

    private bool on_activate_link (string uri) {
        link_clicked (uri);
        return true;
    }

    private void on_set_focus_child (Gtk.Widget? widget) {
        if(widget == null && !has_focus) {
            on_focus_out ();
        }
    }

    class TaskEditEntry : Gtk.Entry {
        private string _description;
        public string description {
            public get {
                return _description;
            }
            public set {
                _description = value;
            }
        }

        private char _priority;
        public char priority {
            public get {
                return _priority;
            }
            public set {
                _priority = value;
            }
        }

        public signal void editing_finished ();
        public signal void strings_changed ();

        public TaskEditEntry (string description, char priority = TxtTask.NO_PRIO) {
            this.description = description;
            this.priority = priority;

            can_focus = true;
            if(priority == TxtTask.NO_PRIO) {
                text = _description;
            } else {
                text = @"($_priority) $_description";
            }
        }

        private void split_pseudo_description (string pseudo_description) {
            string _pseudo_description = pseudo_description;
            _priority = consume_priority (ref _pseudo_description);
            description = _pseudo_description;
        }

        private void abort_editing () {
            editing_finished ();
        }

        private void stop_editing () {
            split_pseudo_description (text.strip ());
            strings_changed ();
            abort_editing ();
        }

        public void edit () {
            show ();
            grab_focus ();
            activate.connect(stop_editing);
        }
    }

    class TaskMarkupLabel : Gtk.Label {
        private TxtTask task;

        private string markup_string;

        public TaskMarkupLabel (TxtTask task) {
            this.task = task;

            update ();

            hexpand = true;
            wrap = true;
            wrap_mode = Pango.WrapMode.WORD_CHAR;
            width_request = 200;
            // Workaround for: "undefined symbol: gtk_label_set_xalign"
            ((Gtk.Misc) this).xalign = 0f;

            update_tooltip ();

            connect_signals ();
            show_all ();
        }

        public void update_tooltip () {
            DateTime completion_date = task.completion_date;
            DateTime creation_date = task.creation_date;

            /// see https://valadoc.org/glib-2.0/GLib.DateTime.format.html for
            // formatting of DateTime
            string date_format = _("%Y-%m-%d");

            if(task.done && completion_date != null) {
                set_tooltip_text (
                    _("Task completed at %s, created at %s").printf (
                        completion_date.format (date_format),
                        creation_date.format (date_format)
                    )
                );
            } else if (creation_date != null) {
                set_tooltip_text (
                    _("Task created at %s").printf (
                        creation_date.format (date_format)
                    )
                );
            }
        }

        private void gen_markup () {
            markup_string = make_links (GLib.Markup.escape_text (task.description));
            if(task.priority != TxtTask.NO_PRIO) {
                var prefix = _("priority");
                var priority = task.priority;
                markup_string = @"<b><a href=\"$prefix:$priority\">($priority)</a></b> $markup_string";
            }
            if (task.done) {
                markup_string = "<s>" + markup_string + "</s>";
            }
        }

        /**
         * Used to find projects and contexts and replace those parts with a
         * link.
         * @param description the string to took for contexts or projects
         */
        private string make_links (string description) {
            string parsed = "";
            string delimiter = null, prefix = null;

            foreach (string part in description.split (" ")) {
                string? val = null;
                if(part == "") {
                    parsed += " ";
                    continue;
                }

                if (is_context_tag (part)) {
                    prefix = _("context");
                    delimiter = "@";
                    val = part.offset(1);
                }
                if (is_project_tag (part)) {
                    prefix = _("project");
                    delimiter = "+";
                    val = part.offset(1);
                }
                if (val != null) {
                    parsed += @" <a href=\"$prefix:$val\" title=\"$val\">" +
                              @"$delimiter$val</a>";
                } else {
                    parsed += " " + part;
                }
            }

            return parsed.chug ();
        }

        private void update () {
            gen_markup ();
            set_markup (markup_string);
        }

        private void connect_signals () {
            task.notify["description"].connect (update);
            task.notify["priority"].connect (update);
        }
    }
}
