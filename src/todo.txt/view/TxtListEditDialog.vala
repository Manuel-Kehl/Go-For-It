/* Copyright 2019 Go For It! developers
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

    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Label error_label;
    private Gtk.Revealer error_revealer;

    private Gtk.Switch timer_default_switch;
    private Gtk.SpinButton reminder_spin;
    private Gtk.Label timer_sect_lbl;
    private Gtk.Label reminder_lbl1;
    private Gtk.Label reminder_lbl2;
    private Gtk.Label timer_default_lbl;
    private TimerScheduleWidget sched_widget;

    private Gtk.Label log_timer_lbl;
    private Gtk.Switch log_timer_switch;

    private Gtk.Label name_lbl;
    private Gtk.Entry name_entry;
    private Gtk.Label directory_lbl;
    private Gtk.FileChooserButton directory_btn;
    private bool txt_showing_error;
    private bool dir_showing_error;

    private string directory_lbl_text =
            "<a href=\"http://todotxt.com\">Todo.txt</a> "
            + _("directory") + ":";
    private string name_lbl_text = _("List name") + ":";

    public signal void add_list_clicked (ListSettings lsettings);

    public TxtListEditDialog (
        Gtk.Window? parent, TxtListManager list_manager,
        ListSettings? lsettings = null
    ) {
        this.set_transient_for (parent);
        this.list_manager = list_manager;
        if (lsettings == null) {
            this.lsettings = new ListSettings.empty ();
            this.title = _("New to-do list");
            this.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            this.add_button (_("Add list"), Gtk.ResponseType.ACCEPT);
        } else {
            this.lsettings = lsettings;
            this.title = _("Edit to-do list properties");
            this.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            this.add_button (_("Apply"), Gtk.ResponseType.ACCEPT);
        }

        /* Initalization */
        main_layout = new Gtk.Grid ();

        /* General Settigns */
        // Default to minimum possible size
        this.set_default_size (1, 1);
        this.get_content_area ().margin = 10;
        this.get_content_area ().pack_start (main_layout);
        this.set_modal (true);
        main_layout.visible = true;
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        apply_grid_spacing (main_layout);

        setup_settings_widgets ();

        /* Action Handling */
        this.response.connect (on_response);

        set_add_sensitive ();
    }

    private void on_response (int response_id) {
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                add_list_clicked (lsettings);
                break;
            default:
                this.destroy ();
                break;
        }
    }

    private bool check_valid () {
        bool is_valid = true;
        string error_msg = "";
        if (lsettings.todo_txt_location == null) {
            // This setting hasn't been changed by the user
            is_valid = false;
        } else if (!list_manager.location_available (lsettings)) {
            // The user has selected an invalid directory, so we show an error.
            if (error_msg != "") {error_msg += "\n";}
            error_msg += gen_error_markup (
                _("The configured directory is already in use by another list.")
            );
            is_valid = false;
            if (!dir_showing_error) {
                directory_lbl.label = gen_error_markup (directory_lbl_text);
                dir_showing_error = true;
            }
        } else if (dir_showing_error) {
            // Restore the label text
            directory_lbl.label = directory_lbl_text;
            dir_showing_error = false;
        }

        if (lsettings.name == null) {
            // This setting hasn't been changed by the user
            is_valid = false;
        } else if (lsettings.name == "") {
            // The user entered an empty string (or just whitespace)
            if (error_msg != "") {error_msg += "\n";}
            error_msg += gen_error_markup (
                _("Please assign a name to the list.")
            );
            is_valid = false;
            if (!txt_showing_error) {
                name_lbl.label = gen_error_markup (name_lbl_text);
                txt_showing_error = true;
            }
        } else if (txt_showing_error) {
            // Restore the label text
            name_lbl.label = name_lbl_text;
            txt_showing_error = false;
        }
        error_revealer.set_reveal_child (!is_valid);
        if (is_valid) {
            return true;
        }
        error_label.label = error_msg;
        return false;
    }

    private void set_add_sensitive () {
        set_response_sensitive (Gtk.ResponseType.ACCEPT, check_valid ());
    }

    private void setup_settings_widgets () {
        int row = 0;
        dir_showing_error = false;
        txt_showing_error = false;
        error_label = new Gtk.Label ("");
        setup_txt_settings_widgets (main_layout, ref row);
        setup_timer_settings_widgets (main_layout, ref row);
        setup_error_widgets (main_layout, ref row);
    }

    /**
     * Generates a red error message
     */
    private string gen_error_markup (string error) {
        return @"<span foreground=\"red\">$error*</span>";
    }

    private void setup_error_widgets (Gtk.Grid grid, ref int row) {
        error_revealer = new Gtk.Revealer ();

        error_label.hexpand = true;
        error_label.wrap = true;
        error_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        error_label.width_request = 200;
        error_label.use_markup = true;
        error_label.halign = Gtk.Align.START;

        error_revealer.add (error_label);
        error_revealer.set_reveal_child (false);

        grid.attach (error_revealer, 0, row, 3, 1);
        row++;
    }

    private void setup_txt_settings_widgets (Gtk.Grid grid, ref int row) {
        /* Declaration */
        Gtk.Label txt_sect_lbl;

        /* Instantiation */
        txt_sect_lbl = new Gtk.Label ("Todo.txt");

        directory_btn = new Gtk.FileChooserButton (
            "Todo.txt " + _("directory"), Gtk.FileChooserAction.SELECT_FOLDER
        );

        directory_lbl = new Gtk.Label (directory_lbl_text);

        name_lbl = new Gtk.Label (name_lbl_text);
        name_entry = new Gtk.Entry ();

        log_timer_lbl = new Gtk.Label (_("Log the time spent working on each task") + ":");
        log_timer_switch = new Gtk.Switch ();

        /* Configuration */
        directory_lbl.set_line_wrap (false);
        directory_lbl.set_use_markup (true);
        directory_btn.create_folders = true;
        if (lsettings.todo_txt_location != null) {
            directory_btn.set_current_folder (lsettings.todo_txt_location);
        }

        name_lbl.use_markup = true;
        if (lsettings.name == null) {
            name_entry.text = "";
        } else {
            name_entry.text = lsettings.name;
        }

        log_timer_switch.active = lsettings.log_timer_in_txt;

        /* Signal Handling */
        directory_btn.file_set.connect (on_directory_changed);
        name_entry.notify["text"].connect (on_name_entry_update);
        log_timer_switch.notify["active"].connect (() => {
            lsettings.log_timer_in_txt = log_timer_switch.active;
        });

        add_section (main_layout, txt_sect_lbl, ref row);
        add_option (main_layout, directory_lbl, directory_btn, ref row);
        add_option (main_layout, name_lbl, name_entry, ref row);
        add_option (main_layout, log_timer_lbl, log_timer_switch, ref row);
    }

    private void on_directory_changed () {
        lsettings.todo_txt_location = directory_btn.get_file ().get_path ();
        set_add_sensitive ();
    }

    private void on_name_entry_update () {
        var name = name_entry.text;
        if (name != "" || lsettings.name != null) {
            lsettings.name = name.strip ();
            set_add_sensitive ();
        }
    }

    private void setup_timer_settings_widgets (Gtk.Grid grid, ref int row) {
        /* Instantiation */
        timer_sect_lbl = new Gtk.Label (_("Timer"));
        timer_default_lbl = new Gtk.Label (_("Use default settings") + (":"));
        reminder_lbl1 = new Gtk.Label (_("Reminder before task ends") +":");
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
        } else {
            reminder_spin.value = lsettings.reminder_time;
            sched_widget.load_schedule (lsettings.schedule);
            timer_default_switch.active = false;
        }

        /* Signal Handling */
        reminder_spin.value_changed.connect (on_reminder_value_changed);
        timer_default_switch.notify["active"].connect (toggle_timer_settings);
        sched_widget.schedule_updated.connect ((sched) => {
            lsettings.schedule = sched;
        });

        /* Add widgets */
        add_section (grid, timer_sect_lbl, ref row);
        add_option (grid, timer_default_lbl, timer_default_switch, ref row);
        add_option (grid, reminder_lbl1, reminder_spin, ref row, 1, reminder_lbl2);
        grid.attach (sched_widget, 0, row, 3, 1);
        row++;
    }

    private void on_reminder_value_changed () {
        lsettings.reminder_time = reminder_spin.get_value_as_int ();
    }

    public override void show_all () {
        base.show_all ();
        if (timer_default_switch.active) {
            reminder_lbl1.hide ();
            reminder_lbl2.hide ();
            reminder_spin.hide ();
            sched_widget.hide ();
        }
    }

    private void toggle_timer_settings () {
        if (timer_default_switch.active) {
            lsettings.reminder_time = -1;
            lsettings.schedule = null;
            reminder_lbl1.hide ();
            reminder_lbl2.hide ();
            reminder_spin.hide ();
            sched_widget.hide ();
        } else {
            lsettings.reminder_time = reminder_spin.get_value_as_int ();
            lsettings.schedule = sched_widget.generate_schedule ();
            reminder_lbl1.show ();
            reminder_lbl2.show ();
            reminder_spin.show ();
            sched_widget.show();
        }
    }
}
