/* Copyright 2017-2020 Go For It! developers
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
    private DynOrientationBox label_box;
    private TaskMarkupLabel markup_label;
    private Gtk.Label status_label;
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
        markup_label.halign = Gtk.Align.START;
        status_label = new Gtk.Label (null);
        status_label.halign = Gtk.Align.END;
        status_label.use_markup = true;
        update_status_label ();

        label_box = new DynOrientationBox (2, 0);
        label_box.set_primary_widget (markup_label);
        label_box.set_secondary_widget (status_label);

        check_button = new Gtk.CheckButton ();
        check_button.active = task.done;

        set_start_widget (check_button);
        set_center_widget (label_box);

        connect_signals ();
        show_all ();
    }

    public override void show_all () {
        bool status_label_was_visible = status_label.visible;
        base.show_all ();
        if (!status_label_was_visible) {
            status_label.hide ();
        }
    }

    public void edit (bool wrestle_focus=false) {
        if (edit_entry != null) {
            return;
        }
        delete_button = new Gtk.Button.from_icon_name ("edit-delete", Gtk.IconSize.MENU);
        delete_button.relief = Gtk.ReliefStyle.NONE;
        delete_button.show_all ();
        delete_button.clicked.connect (on_delete_button_clicked);
        set_start_widget (delete_button);

        edit_entry = new TaskEditEntry (task.to_simple_txt ());
        set_center_widget (edit_entry);

        edit_entry.edit ();
        edit_entry.string_changed.connect (on_edit_entry_string_changed);
        edit_entry.editing_finished.connect (on_edit_entry_finished);
        editing = true;

        if (wrestle_focus) {
            // Ugly hack: on Gtk 3.22 the row will steal focus from the entry in
            // about 0.1s if the row has been activated using a double-click
            // we want the entry to remain in focus until the user decides
            // otherwise.
            edit_entry.hold_focus = true;
            GLib.Timeout.add(
                200, release_focus_claim, GLib.Priority.DEFAULT_IDLE
            );
        }
    }

    private void on_delete_button_clicked () {
        deletion_requested ();
    }

    private void on_edit_entry_string_changed () {
        task.update_from_simple_txt (edit_entry.text.strip ());
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

    private bool release_focus_claim () {
        edit_entry.hold_focus = false;
        return false;
    }

    public void stop_editing () {
        if (!editing) {
            return;
        }
        var had_focus = edit_entry.has_focus;
        set_center_widget (label_box);
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
        markup_label.activate_link.connect (on_activate_link);

        set_focus_child.connect (on_set_focus_child);
        focus_out_event.connect (on_focus_out);
        key_release_event.connect (on_row_key_release);

        task.done_changed.connect (on_task_done_changed);
        task.notify["status"].connect (update_status_label);
        task.notify["timer-value"].connect (update_status_label);
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

    private void update_status_label () {
        var timer_value = task.timer_value;
        if (task.done && timer_value >= 60) {
            var timer_value_str = Utils.seconds_to_pretty_string (timer_value);
            status_label.label = "<i>%s</i>".printf(timer_value_str);
            status_label.show ();
        } else if ((task.status & TaskStatus.TIMER_ACTIVE) != 0) {
            status_label.label = "⏰";
            status_label.show ();
        } else {
            status_label.hide ();
        }
    }

    class TaskEditEntry : Gtk.Entry {
        public signal void editing_finished ();
        public signal void string_changed ();
        private uint8 focus_wrestle_counter;

        public bool hold_focus {
            get {
                return focus_wrestle_counter != 0;
            }
            set {
                if (value) {
                    // 1 seems to be sufficient right now
                    focus_wrestle_counter = 1;
                } else {
                    focus_wrestle_counter = 0;
                }
            }
        }

        public TaskEditEntry (string description) {
            can_focus = true;
            text = description;
            focus_wrestle_counter = 0;
            focus_out_event.connect (() => {
                if (focus_wrestle_counter == 0) {
                    return false;
                }
                focus_wrestle_counter--;
                grab_focus ();
                return false;
            });
        }

        private void abort_editing () {
            editing_finished ();
        }

        private void stop_editing () {
            string_changed ();
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
#if HAS_GTK322
            this.xalign = 0f;
#else
            // Workaround for: "undefined symbol: gtk_label_set_xalign"
            ((Gtk.Misc) this).xalign = 0f;
#endif
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
            markup_string = make_links (task.get_descr_parts ());

            var done = task.done;
            var duration = task.duration;

            if(task.priority != TxtTask.NO_PRIO) {
                var prefix = _("priority");
                var priority = task.priority;
                char prio_char = priority + 65;
                markup_string = @"<b><a href=\"$prefix:$prio_char\">($prio_char)</a></b> $markup_string";
            }
            if (duration > 0) {
                var timer_value = task.timer_value;
                if (timer_value > 0 && !done) {
                    markup_string = "%s <i>(%u / %s)</i>".printf (markup_string, timer_value/60, Utils.seconds_to_short_string (duration));
                } else {
                    markup_string = "%s <i>(%s)</i>".printf (markup_string, Utils.seconds_to_short_string (duration));
                }
            }
            if (done) {
                markup_string = "<s>" + markup_string + "</s>";
            }
        }

        /**
         * Used to find projects and contexts and replace those parts with a
         * link.
         * @param description the string to took for contexts or projects
         */
        private string make_links (TxtPart[] description) {
            var length = description.length;
            var markup_parts = new string[length];
            string? delimiter = null, prefix = null, val = null;

            for (uint i = 0; i < length; i++) {
                unowned TxtPart part = description[i];
                val = GLib.Markup.escape_text (part.content);

                switch (part.part_type) {
                    case TxtPartType.CONTEXT:
                        prefix = _("context");
                        delimiter = "@";
                        break;
                    case TxtPartType.PROJECT:
                        prefix = _("project");
                        delimiter = "+";
                        break;
                    case TxtPartType.TAG:
                        markup_parts[i] = part.tag_name + ":" + val;
                        continue;
                    default:
                        markup_parts[i] = val;
                        continue;
                }
                markup_parts[i] = @" <a href=\"$prefix:$val\" title=\"$val\">" +
                                  @"$delimiter$val</a>";
            }

            return string.joinv (" ", markup_parts);
        }

        private void update () {
            gen_markup ();
            set_markup (markup_string);
        }

        private void connect_signals () {
            task.notify["description"].connect (update);
            task.notify["priority"].connect (update);
            task.notify["timer-value"].connect (update);
        }
    }
}
