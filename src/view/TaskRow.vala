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

using GOFI.TxtUtils;

class TaskRow: DragListRow {
    private Gtk.CheckButton check_button;
    private TaskLabel description_label;

    public TodoTask task {
        get;
        private set;
    }

    public signal void link_clicked (string uri);

    public TaskRow (TodoTask task) {
        this.task = task;

        check_button = new Gtk.CheckButton ();
        check_button.active = task.done;

        description_label = new TaskLabel (task.description, task.done, task.priority);
        description_label.hexpand = true;

        set_start_widget (check_button);
        set_center_widget (description_label);

        connect_signals ();
        show_all ();
    }

    public void edit () {
        description_label.edit ();
    }

    private void connect_signals () {
        check_button.toggled.connect (() => {
            task.done = !task.done;
        });
        task.done_changed.connect (() => {
            destroy ();
        });
        task.notify["description"].connect (update);
        task.notify["priority"].connect (update);
        description_label.activate_link.connect ((uri) => {
            link_clicked (uri);
            return true;
        });
        description_label.string_changed.connect (() => {
            task.description = description_label.description;
        });
        description_label.single_click.connect (() => {
            Gtk.ListBox? parent = this.get_parent () as Gtk.ListBox;
            if (parent != null) {
                parent.select_row (this);
            }
            grab_focus ();
        });
    }

    private void update () {
        description_label.description = task.description;
    }

    /**
     * An editable label that supports wrapping and markup
     */
    class TaskLabel : Gtk.Stack {
        private Gtk.Label label;
        private Gtk.Entry entry;

        private bool task_done;
        private bool double_click;
        private bool entry_visible;

        private string markup_string;

        private string _description;
        public string description {
            public get {
                return _description;
            }
            public set {
                _description = value;
                update ();
            }
        }

        private string? _priority;
        public string? priority {
            public get {
                return _priority;
            }
            public set {
                _priority = value;
                update ();
            }
        }

        public signal bool activate_link (string uri);
        public signal void string_changed ();
        public signal void single_click ();

        public TaskLabel (string description, bool task_done, string? priority) {
            _description = description;
            _priority = priority;
            this.task_done = task_done;
            double_click = false;
            entry_visible = false;
            setup_widgets ();
        }

        public void setup_widgets () {
            label = new Gtk.Label(null);

            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            label.width_request = 200;
            // Workaround for: "undefined symbol: gtk_label_set_xalign"
            ((Gtk.Misc) label).xalign = 0f;

            update ();

            label.activate_link.connect ( (uri) => {
                return activate_link (uri);
            });

            // Workaround for Gtk.ListBox stealing focus after activating a row
            // by double clicking it, which would cause editing to be aborted.
            button_press_event.connect ((event_button) => {
                if (event_button.type == Gdk.EventType.2BUTTON_PRESS) {
                    double_click = true;
                }
                return true;
            });
            button_release_event.connect ((event_button) => {
                if (entry_visible) {
                    return true;
                }
                if (double_click) {
                    double_click = false;
                    edit ();
                } else {
                    single_click ();
                }
                return true;
            });

            add (label);
        }

        public void edit () {
            if (entry != null) {
                return;
            }
            entry = new Gtk.Entry ();
            entry.can_focus = true;
            if(priority == null) {
                entry.text = _description;
            } else {
                entry.text = _priority + " " + _description;
            }

            add (entry);
            entry.show ();
            set_visible_child (entry);
            entry.grab_focus ();
            entry.activate.connect(stop_editing);
            entry.focus_out_event.connect (on_entry_focus_out);
            entry_visible = true;
        }

        private bool on_entry_focus_out () {
            abort_editing ();
            return false;
        }

        private void abort_editing () {
            if (entry != null) {
                var _entry = entry;
                entry = null;
                set_visible_child (label);
                remove (_entry);
            }
            entry_visible = false;
        }

        private void stop_editing () {
            split_pseudo_description (entry.text.strip ());
            string_changed ();
            abort_editing ();
        }

        private void update () {
            gen_markup ();
            label.set_markup (markup_string);
        }

        private void gen_markup () {
            markup_string = make_links (GLib.Markup.escape_text (_description));
            if(_priority != null) {
                markup_string = "<b>" + _priority + "</b> " + markup_string;
            }
            if (task_done) {
                markup_string = "<s>" + markup_string + "</s>";
            }
        }

        private void split_pseudo_description (string pseudo_description) {
            string _pseudo_description = pseudo_description;
            _priority = consume_priority (ref _pseudo_description);
            description = _pseudo_description;
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
                    val = part.split (delimiter, 2)[1];
                }
                if (is_project_tag (part)) {
                    prefix = _("project");
                    delimiter = "+";
                    val = part.split (delimiter, 2)[1];
                }
                if (val != null) {
                    parsed += @" <a href=\"$prefix$val\" title=\"$val\">" +
                              @"$delimiter$val</a>";
                } else {
                    parsed += " " + part;
                }
            }

            return parsed.chug ();
        }
    }
}
