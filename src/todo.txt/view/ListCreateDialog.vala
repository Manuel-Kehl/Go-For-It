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

class ListCreateDialog : Gtk.Dialog {
    private TxtListManager list_manager;
    private ListSettings settings;

    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Label error_label;
    private Gtk.Revealer error_revealer;

    private Gtk.Label name_lbl;
    private Gtk.Label directory_lbl;
    private bool txt_showing_error;
    private bool dir_showing_error;

    private string directory_lbl_text =
            "<a href=\"http://todotxt.com\">Todo.txt</a> "
            + _("directory") + ":";
    private string name_lbl_text = _("List name") + ":";

    public signal void add_list_clicked (ListSettings settings);

    public ListCreateDialog (Gtk.Window? parent, TxtListManager list_manager) {
        this.set_transient_for (parent);
        this.list_manager = list_manager;
        settings = new ListSettings.empty ();
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
        main_layout.row_spacing = 10;
        main_layout.column_spacing = 10;

        this.title = _("New todo list");
        setup_settings_widgets ();
        this.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        this.add_button (_("Add list"), Gtk.ResponseType.ACCEPT);

        /* Action Handling */
        this.response.connect ((s, response) => {
            switch (response) {
                case Gtk.ResponseType.ACCEPT:
                    add_list_clicked (settings);
                    break;
                default:
                    this.destroy ();
                    break;
            }
        });

        set_add_sensitive ();
    }

    private bool check_valid () {
        bool is_valid = true;
        string error_msg = "";
        if (settings.todo_txt_location == null) {
            // This setting hasn't been changed by the user
            is_valid = false;
        } else if (!list_manager.location_available (settings)) {
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

        if (settings.name == null) {
            // This setting hasn't been changed by the user
            is_valid = false;
        } else if (settings.name == "") {
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

    private void add_section (Gtk.Grid grid, Gtk.Label label, ref int row) {
        label.set_markup ("<b>%s</b>".printf (label.get_text ()));
        label.halign = Gtk.Align.START;

        grid.attach (label, 0, row, 2, 1);
        row++;
    }

    private void add_option (Gtk.Grid grid, Gtk.Widget label,
                             Gtk.Widget switcher, ref int row)
    {
        label.hexpand = true;
        label.margin_start = 20; // indentation relative to the section label
        label.halign = Gtk.Align.START;

        switcher.hexpand = true;
        switcher.halign = Gtk.Align.FILL;

        if (switcher is Gtk.Switch || switcher is Gtk.Entry) {
            switcher.halign = Gtk.Align.START;
        }

        grid.attach (label, 0, row, 1, 1);
        grid.attach (switcher, 1, row, 1, 1);
        row++;
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

        grid.attach (error_revealer, 0, row, 2, 1);
        row++;
    }

    private void setup_txt_settings_widgets (Gtk.Grid grid, ref int row) {
        /* Declaration */
        Gtk.FileChooserButton directory_btn;
        Gtk.Label txt_sect_lbl;

        /* Instantiation */
        txt_sect_lbl = new Gtk.Label ("Todo.txt");

        directory_btn = new Gtk.FileChooserButton ("Todo.txt " + _("directory"),
            Gtk.FileChooserAction.SELECT_FOLDER);

        directory_lbl = new Gtk.Label (directory_lbl_text);

        /* Configuration */
        directory_lbl.set_line_wrap (false);
        directory_lbl.set_use_markup (true);
        directory_btn.create_folders = true;
        if (settings.todo_txt_location != null) {
            directory_btn.set_current_folder (settings.todo_txt_location);
        }

        /* Signal Handling */
        directory_btn.file_set.connect ((e) => {
            settings.todo_txt_location = directory_btn.get_file ().get_path ();
            set_add_sensitive ();
        });

        add_section (main_layout, txt_sect_lbl, ref row);
        add_option (main_layout, directory_lbl, directory_btn, ref row);

        name_lbl = new Gtk.Label (name_lbl_text);
        name_lbl.use_markup = true;
        Gtk.Entry name_entry = new Gtk.Entry ();

        name_entry.notify["text"].connect ( () => {
            var name = name_entry.text;
            if (name != "" || settings.name != null) {
                settings.name = name.strip ();
                set_add_sensitive ();
            }
        });

        add_option (main_layout, name_lbl, name_entry, ref row);
    }

    private void setup_timer_settings_widgets (Gtk.Grid grid, ref int row) {
        /* Declaration */
        Gtk.Label timer_sect_lbl;
        Gtk.Label task_lbl;
        Gtk.SpinButton task_spin;
        Gtk.Label break_lbl;
        Gtk.SpinButton break_spin;
        Gtk.Label reminder_lbl;
        Gtk.SpinButton reminder_spin;
        Gtk.Label timer_default_lbl;
        Gtk.Switch timer_default_switch;
        Gtk.Revealer timer_revealer;
        Gtk.Grid timer_grid;

        /* Instantiation */
        timer_sect_lbl = new Gtk.Label (_("Timer"));
        timer_default_lbl = new Gtk.Label (_("Use default settings") + (":"));
        task_lbl = new Gtk.Label (_("Task duration (minutes)") + ":");
        break_lbl = new Gtk.Label (_("Break duration (minutes)") + ":");
        reminder_lbl = new Gtk.Label (_("Reminder before task ends (seconds)") +":");

        timer_default_switch = new Gtk.Switch ();
        timer_revealer = new Gtk.Revealer ();
        timer_grid = new Gtk.Grid ();

        // No more than one day: 60 * 24 -1 = 1439
        task_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        // More than ten minutes would not make much sense
        reminder_spin = new Gtk.SpinButton.with_range (0, 600, 1);

        /* Configuration */
        task_spin.value = 25;
        break_spin.value = 5;
        reminder_spin.value = 60;
        timer_default_switch.active = true;
        timer_revealer.set_reveal_child (false);

        timer_grid.orientation = Gtk.Orientation.VERTICAL;
        timer_grid.row_spacing = 10;
        timer_grid.column_spacing = 10;

        /* Signal Handling */
        task_spin.value_changed.connect ((e) => {
            settings.task_duration = task_spin.get_value_as_int () * 60;
        });
        break_spin.value_changed.connect ((e) => {
            settings.break_duration = break_spin.get_value_as_int () * 60;
        });
        reminder_spin.value_changed.connect ((e) => {
            settings.reminder_time = reminder_spin.get_value_as_int ();
        });
        timer_default_switch.notify["active"].connect ( () => {
            if (timer_default_switch.active) {
                settings.task_duration = -1;
                settings.break_duration = -1;
                settings.reminder_time = -1;
                timer_revealer.set_reveal_child (false);
            } else {
                settings.task_duration = task_spin.get_value_as_int () * 60;
                settings.break_duration = break_spin.get_value_as_int () * 60;
                settings.reminder_time = reminder_spin.get_value_as_int ();
                timer_revealer.set_reveal_child (true);
            }
        });

        /* Add widgets */
        timer_revealer.add (timer_grid);

        add_section (grid, timer_sect_lbl, ref row);
        add_option (grid, timer_default_lbl, timer_default_switch, ref row);
        grid.attach (timer_revealer, 0, row, 2, 1);
        row++;

        int row2 = 0;
        add_option (timer_grid, task_lbl, task_spin, ref row2);
        add_option (timer_grid, break_lbl, break_spin, ref row2);
        add_option (timer_grid, reminder_lbl, reminder_spin, ref row2);
    }
}
