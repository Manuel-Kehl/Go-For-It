/* Copyright 2019-2020 Go For It! developers
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

using GOFI.DialogUtils;

class GOFI.TXT.TxtListEditDialog : Gtk.Dialog {
    private TxtListManager list_manager;
    private ListSettings lsettings;
    private string? old_todo_uri;
    private string? old_done_uri;

    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Label error_label;
    private Gtk.Revealer error_revealer;

    private Gtk.StackSwitcher stack_switcher;
    private Gtk.Stack settings_stack;

    private Gtk.Switch timer_default_switch;
    private Gtk.SpinButton reminder_spin;
    private Gtk.Label reminder_lbl1;
    private Gtk.Label reminder_lbl2;
    private Gtk.Label timer_default_lbl;
    private TimerScheduleWidget sched_widget;

    private SynchronizedWLabel log_total_timer_lbl;
    private Gtk.Switch log_total_timer_switch;

    private SynchronizedWLabel name_lbl;
    private Gtk.Entry name_entry;

    private SynchronizedWLabel activity_logging_lbl;
    private Gtk.Switch activity_logging_switch;
    private Gtk.Revealer log_file_lbl_revealer;
    private SynchronizedWLabel log_file_lbl;
    private Gtk.Revealer log_file_chooser_revealer;
    private FileChooserWidget log_file_chooser;

    private SynchronizedWLabel done_uri_lbl;
    private FileChooserWidget done_uri_chooser;

    private SynchronizedWLabel todo_uri_lbl;
    private FileChooserWidget todo_uri_chooser;

    private FileConflictDialogWrapper conflict_dialog_wrapper;

    private bool showing_name_error;
    private bool showing_todo_uri_error;
    private bool showing_done_uri_error;

    private string todo_uri_text = _("Store to-do tasks in") + ":";
    private string done_uri_text = _("Store completed tasks in") + ":";
    private string name_lbl_text = _("List name") + ":";


    string todo_replace_info = _("Task list location has been changed to \"%s\" (was \"%s\"), but this file already exists."); // vala-lint=line-length
    string done_replace_info = _("The location to store completed tasks in has been changed to \"%s\" (was \"%s\"), but this file already exists."); // vala-lint=line-length

    public signal void add_list_clicked (ListSettings lsettings, ConflictChoices? file_operations);

    public TxtListEditDialog (
        Gtk.Window? parent, TxtListManager list_manager,
        ListSettings? lsettings = null
    ) {
        this.set_transient_for (parent);
        this.list_manager = list_manager;
        if (lsettings == null) {
            this.lsettings = new ListSettings.empty ();
            this.lsettings.log_timer_in_txt = true;
            this.title = _("New to-do list");
            this.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            this.add_button (_("Add list"), Gtk.ResponseType.ACCEPT);
            old_todo_uri = null;
            old_done_uri = null;
        } else {
            this.lsettings = lsettings;
            this.title = _("Edit to-do list properties");
            this.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            this.add_button (_("Apply"), Gtk.ResponseType.ACCEPT);
            this.old_todo_uri = lsettings.todo_uri;
            this.old_done_uri = lsettings.done_uri;
        }

        /* Initalization */
        main_layout = new Gtk.Grid ();

        /* General Settigns */
        // Default to minimum possible size
        this.set_default_size (1, 1);
        this.get_content_area ().margin = 10;
        this.get_content_area ().pack_start (main_layout);
        this.set_modal (true);
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        main_layout.row_spacing = 10;
        main_layout.visible = true;

        setup_settings_widgets ();

        /* Action Handling */
        this.response.connect (on_response);

        set_add_sensitive ();
    }

    private void on_response (int response_id) {
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                var conflicts = collect_file_conflicts ();
                handle_conflicts (conflicts);
                break;
            default:
                this.destroy ();
                break;
        }
    }

    private void set_add_sensitive () {
        set_response_sensitive (Gtk.ResponseType.ACCEPT, check_valid ());
    }

    private void setup_settings_widgets () {
        settings_stack = new Gtk.Stack ();
        stack_switcher = new Gtk.StackSwitcher ();

        stack_switcher.stack = settings_stack;
        stack_switcher.halign = Gtk.Align.CENTER;

        settings_stack.set_transition_type (
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        );

        var txt_page = new Gtk.Box (Gtk.Orientation.VERTICAL, DialogUtils.SPACING_SETTINGS_ROW * 2);
        txt_page.halign = Gtk.Align.CENTER;
        var timer_page = new Gtk.Box (Gtk.Orientation.VERTICAL, DialogUtils.SPACING_SETTINGS_ROW * 2);
        timer_page.halign = Gtk.Align.CENTER;

        settings_stack.add_titled (txt_page, "txt_page", _("General"));
        settings_stack.add_titled (timer_page, "timer_page", _("Timer"));

        var wcont = new SynchronizedWCont ();
        txt_page.add (create_general_settings_section (wcont));
        txt_page.add (create_txt_settings_section (wcont));
        txt_page.add (create_error_widget ());

        timer_page.add (create_timer_settings_section ());

        main_layout.add (stack_switcher);
        main_layout.add (settings_stack);
    }

    /**
     * Generates a red error message
     */
    private string gen_error_markup (string error) {
        return @"<span foreground=\"red\">$error*</span>";
    }

    private Gtk.Widget create_error_widget () {
        showing_todo_uri_error = false;
        showing_name_error = false;
        error_label = new Gtk.Label ("");
        error_revealer = new Gtk.Revealer ();

        error_label.hexpand = true;
        error_label.wrap = true;
        error_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        error_label.width_request = 200;
        error_label.use_markup = true;
        error_label.halign = Gtk.Align.START;

        error_revealer.add (error_label);
        error_revealer.set_reveal_child (false);

        return error_revealer;
    }

    private Gtk.Widget create_general_settings_section (SynchronizedWCont wcont) {
        /* Instantiation */
        name_lbl = new SynchronizedWLabel (wcont, name_lbl_text);
        name_entry = new Gtk.Entry ();

        activity_logging_lbl = new SynchronizedWLabel (wcont, _("Log timer usage") + ":");
        activity_logging_switch = new Gtk.Switch ();
        var activity_logging_expl_widget = DialogUtils.get_explanation_widget (
            _("Keep track of when you used the timer and what tasks you worked on while doing this.") +
            "\n" +
            _("This log will be saved as a CSV file.")
        );

        log_file_lbl = new SynchronizedWLabel (wcont, _("Log file") + ":");
        var log_uri = lsettings.activity_log_uri;
        File activity_log_file = null;
        if (log_uri != null && log_uri != "") {
            activity_log_file = File.new_for_uri (log_uri);
            activity_logging_switch.active = true;
        } else {
            activity_logging_switch.active = false;
        }
        log_file_chooser = new FileChooserWidget (
            activity_log_file, _("Select file to log timer usage in"), "timer_log.csv"
        );
        log_file_lbl_revealer = new Gtk.Revealer ();
        log_file_chooser_revealer = new Gtk.Revealer ();

        /* Configuration */
        name_lbl.label.use_markup = true;
        if (lsettings.name == null) {
            name_entry.text = "";
        } else {
            name_entry.text = lsettings.name;
        }

        /* Signal Handling */
        name_entry.notify["text"].connect (on_name_entry_update);
        activity_logging_switch.notify["active"].connect (
            () => enable_timer_logging (activity_logging_switch.active)
        );
        log_file_chooser.notify["selected-file"].connect (on_log_file_changed);

        /* Placement */
        log_file_lbl_revealer.add (log_file_lbl);
        log_file_chooser_revealer.add (log_file_chooser);

        enable_timer_logging (activity_log_file != null);

        var grid = create_page_grid ();
        int row = 0;
        add_option (grid, ref row, name_lbl, name_entry);
        add_option (grid, ref row, activity_logging_lbl, activity_logging_switch, activity_logging_expl_widget);
        add_option (grid, ref row, log_file_lbl_revealer, log_file_chooser_revealer);
        return create_section_box (_("General"), grid);
    }

    private void on_log_file_changed () {
        var selected_file = log_file_chooser.selected_file;
        if (selected_file != null) {
            lsettings.activity_log_uri = selected_file.get_uri ();
        } else {
            lsettings.activity_log_uri = "";
        }
    }

    private void enable_timer_logging (bool enable) {
        log_file_lbl_revealer.set_reveal_child (enable);
        log_file_chooser_revealer.set_reveal_child (enable);
        if (enable) {
            on_log_file_changed ();
        } else {
            lsettings.activity_log_uri = "";
        }
    }

    private Gtk.Widget create_txt_settings_section (SynchronizedWCont wcont) {
        /* Declaration */
        Gtk.Widget log_total_timer_expl_widget;

        /* Instantiation */
        File todo_file = null;
        if (old_todo_uri != null && old_todo_uri != "") {
            todo_file = File.new_for_uri (old_todo_uri);
        }
        todo_uri_chooser = new FileChooserWidget (todo_file, _("Select file to store to-do tasks in"), "todo.txt");
        todo_uri_lbl = new SynchronizedWLabel (wcont, todo_uri_text);

        File done_file = null;
        if (old_done_uri != null && old_done_uri != "") {
            done_file = File.new_for_uri (old_done_uri);
        }
        done_uri_chooser = new FileChooserWidget (todo_file, _("Select file to store completed tasks in"), "done.txt");
        done_uri_lbl = new SynchronizedWLabel (wcont, done_uri_text);

        log_total_timer_lbl = new SynchronizedWLabel (wcont, _("Log the time spent working on each task") + ":");
        log_total_timer_expl_widget = DialogUtils.get_explanation_widget (
            _("Log the total time spent working on a task using the timer.") +
            "\n" +
            _("This information will be stored in the todo.txt files.")
        );
        log_total_timer_switch = new Gtk.Switch ();

        /* Configuration */
        todo_uri_lbl.label.set_line_wrap (false);
        todo_uri_lbl.label.set_use_markup (true);
        done_uri_lbl.label.set_line_wrap (false);
        done_uri_lbl.label.set_use_markup (true);

        log_total_timer_switch.active = lsettings.log_timer_in_txt;

        /* Signal Handling */
        todo_uri_chooser.notify["selected-file"].connect (on_todo_file_changed);
        done_uri_chooser.notify["selected-file"].connect (on_done_file_changed);
        log_total_timer_switch.notify["active"].connect (() => {
            lsettings.log_timer_in_txt = log_total_timer_switch.active;
        });

        /* Placement */
        var grid = create_page_grid ();
        int row = 0;
        add_option (grid, ref row, todo_uri_lbl, todo_uri_chooser);
        add_option (grid, ref row, done_uri_lbl, done_uri_chooser);
        add_option (grid, ref row, log_total_timer_lbl, log_total_timer_switch, log_total_timer_expl_widget);
        return create_section_box ("Todo.txt", grid);
    }

    private void on_todo_file_changed () {
        var selected_file = todo_uri_chooser.selected_file;
        if (selected_file != null) {
            update_todo_uri (selected_file.get_uri ());
            if (
                (lsettings.done_uri == null || lsettings.done_uri == "") &&
                selected_file.get_basename () == "todo.txt" &&
                selected_file.has_parent (null)
            ) {
                // We can guess what the other file should be:
                done_uri_chooser.selected_file =
                    selected_file.get_parent ().get_child ("done.txt");
            }
        } else {
            update_todo_uri (null);
        }
    }

    private void on_done_file_changed () {
        var selected_file = done_uri_chooser.selected_file;
        if (selected_file != null) {
            update_done_uri (selected_file.get_uri ());
            if (
                (lsettings.todo_uri == null || lsettings.todo_uri == "") &&
                selected_file.get_basename () == "done.txt" &&
                selected_file.has_parent (null)
            ) {
                // We can guess what the other file should be:
                todo_uri_chooser.selected_file =
                    selected_file.get_parent ().get_child ("todo.txt");
            }
        } else {
            update_done_uri (null);
        }
    }

    private void update_todo_uri (string? uri) {
        lsettings.todo_uri = uri;
        set_add_sensitive ();
    }

    private void update_done_uri (string? uri) {
        lsettings.done_uri = uri;
        set_add_sensitive ();
    }

    private void on_name_entry_update () {
        var name = name_entry.text;
        if (name != "" || lsettings.name != null) {
            lsettings.name = name.strip ();
            set_add_sensitive ();
        }
    }

    private Gtk.Widget create_timer_settings_section () {
        /* Instantiation */
        timer_default_lbl = new Gtk.Label (_("Use default settings") + ":");
        reminder_lbl1 = new Gtk.Label (_("Reminder before task ends") + ":");
        reminder_lbl2 = new Gtk.Label (_("seconds"));

        timer_default_switch = new Gtk.Switch ();

        sched_widget = new TimerScheduleWidget ();

        // More than ten minutes would not make much sense
        reminder_spin = new Gtk.SpinButton.with_range (0, 600, 1);

        /* Configuration */
        if (lsettings.reminder_time < 0 || lsettings.schedule == null) {
            reminder_spin.value = settings.reminder_time;
            sched_widget.load_schedule (settings.schedule);
            timer_default_switch.active = true;
            reminder_spin.sensitive = false;
            sched_widget.sensitive = false;
        } else {
            reminder_spin.value = lsettings.reminder_time;
            sched_widget.load_schedule (lsettings.schedule);
            timer_default_switch.active = false;
            reminder_spin.sensitive = true;
            sched_widget.sensitive = true;
        }

        /* Signal Handling */
        reminder_spin.value_changed.connect (on_reminder_value_changed);
        timer_default_switch.notify["active"].connect (toggle_timer_settings);
        sched_widget.schedule_updated.connect ((sched) => {
            lsettings.schedule = sched;
        });

        /* Add widgets */
        var grid = create_page_grid ();
        int row = 0;
        add_option (grid, ref row, timer_default_lbl, timer_default_switch);
        add_option (grid, ref row, reminder_lbl1, reminder_spin, reminder_lbl2);
        grid.attach (sched_widget, 0, row, 3, 1);
        return create_section_box (null, grid);
    }

    private void on_reminder_value_changed () {
        lsettings.reminder_time = reminder_spin.get_value_as_int ();
    }

    private void toggle_timer_settings () {
        if (timer_default_switch.active) {
            lsettings.reminder_time = -1;
            lsettings.schedule = null;
            reminder_spin.sensitive = false;
            sched_widget.sensitive = false;
        } else {
            lsettings.reminder_time = reminder_spin.get_value_as_int ();
            lsettings.schedule = sched_widget.generate_schedule ();
            reminder_spin.sensitive = true;
            sched_widget.sensitive = true;
        }
    }

    private bool check_valid () {
        bool is_valid = true;
        string[] error_msgs = {};
        if (lsettings.todo_uri == null || lsettings.done_uri == null) {
            // This setting hasn't been changed by the user
            is_valid = false;
        } else {
            if (!list_manager.todo_uri_available (lsettings)) {
                // The user has selected an invalid directory, so we show an error.
                error_msgs += gen_error_markup (
                    _("The configured to-do file is already in use by another list.")
                );
                is_valid = false;
                if (!showing_todo_uri_error) {
                    todo_uri_lbl.label.label = gen_error_markup (todo_uri_text);
                    showing_todo_uri_error = true;
                }
            } else if (showing_todo_uri_error) {
                // Restore the label text
                todo_uri_lbl.label.label = todo_uri_text;
                showing_todo_uri_error = false;
            }

            if (!list_manager.done_uri_available (lsettings)) {
                // The user has selected an invalid directory, so we show an error.
                error_msgs += gen_error_markup (
                    _("Another todo.txt list archives its completed tasks to the selected file.")
                );
                is_valid = false;
                if (!showing_done_uri_error) {
                    done_uri_lbl.label.label = gen_error_markup (done_uri_text);
                    showing_done_uri_error = true;
                }
            } else if (showing_done_uri_error) {
                // Restore the label text
                done_uri_lbl.label.label = done_uri_text;
                showing_done_uri_error = false;
            }
        }

        if (lsettings.name == null) {
            // This setting hasn't been changed by the user
            is_valid = false;
        } else if (lsettings.name == "") {
            // The user entered an empty string (or just whitespace)
            error_msgs += gen_error_markup (
                _("Please assign a name to the list.")
            );
            is_valid = false;
            if (!showing_name_error) {
                name_lbl.label.label = gen_error_markup (name_lbl_text);
                showing_name_error = true;
            }
        } else if (showing_name_error) {
            // Restore the label text
            name_lbl.label.label = name_lbl_text;
            showing_name_error = false;
        }
        error_revealer.set_reveal_child (!is_valid);
        if (is_valid) {
            return true;
        }
        error_label.label = string.joinv ("\n", error_msgs);
        return false;
    }

    private ConflictChoices? collect_file_conflicts () {
        string new_done_uri = lsettings.done_uri;
        string new_todo_uri = lsettings.todo_uri;

        if (old_done_uri == null && old_todo_uri == null) {
            return null;
        }

        bool todo_txt_updated = old_todo_uri != new_todo_uri;
        bool done_txt_updated = old_done_uri != new_done_uri;

        if (!todo_txt_updated && !done_txt_updated) {
            return null;
        }

        var conflicts = new ConflictChoices ();

        if (old_todo_uri == new_done_uri && old_done_uri == new_todo_uri) {
            conflicts.add_simple_swap (new FileConflict (null, old_todo_uri, new_todo_uri));
            return conflicts;
        }

        if (todo_txt_updated) {
            var txt_conflict_info = todo_replace_info.printf (new_todo_uri, old_todo_uri);
            var conflict = new FileConflict (txt_conflict_info, old_todo_uri, new_todo_uri);
            var todo_txt = File.new_for_uri (new_todo_uri);
            bool todo_exists = todo_txt.query_exists ();
            if (todo_exists) {
                conflicts.add_conflict (conflict);
            } else {
                conflicts.add_simple_replace (conflict);
            }
        }

        if (done_txt_updated) {
            var done_conflict_info = done_replace_info.printf (new_done_uri, old_done_uri);
            var conflict = new FileConflict (done_conflict_info, old_done_uri, new_done_uri);
            var done_txt = File.new_for_uri (new_done_uri);
            bool done_exists = done_txt.query_exists ();
            if (done_exists) {
                conflicts.add_conflict (conflict);
            } else {
                conflicts.add_simple_replace (conflict);
            }
        }

        return conflicts;
    }

    private void handle_conflicts (ConflictChoices? conflicts) {
        if (conflicts == null || conflicts.get_next_conflict () == null) {
            add_list_clicked (lsettings, null);
            return;
        }

        conflict_dialog_wrapper = new FileConflictDialogWrapper ();
        conflict_dialog_wrapper.show_conflict_dialog (this, conflicts);
        conflict_dialog_wrapper.aborted.connect (clean_up_conflict_dialog);
        conflict_dialog_wrapper.choices_made.connect (on_conflict_choices_made);
    }

    private void on_conflict_choices_made (ConflictChoices choices) {
        clean_up_conflict_dialog ();
        add_list_clicked (lsettings, choices);
    }

    private void clean_up_conflict_dialog () {
        conflict_dialog_wrapper.aborted.disconnect (clean_up_conflict_dialog);
        conflict_dialog_wrapper.choices_made.disconnect (on_conflict_choices_made);
        conflict_dialog_wrapper = null;
    }
}
