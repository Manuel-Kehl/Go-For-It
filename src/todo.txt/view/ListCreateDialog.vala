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
        this.add_button (_("Close"), Gtk.ResponseType.CLOSE);

        /* Action Handling */
        this.response.connect ((s, response) => {
            if (response == Gtk.ResponseType.CLOSE) {
                this.destroy ();
            }
        });
    }

    private void setup_settings_widgets () {
        int row = 0;
        setup_txt_settings_widgets (main_layout, ref row);
        setup_timer_settings_widgets (main_layout, ref row);
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
        label.margin_left = 20; // indentation relative to the section label
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

    private void setup_txt_settings_widgets (Gtk.Grid grid, ref int row) {
        /* Declaration */
        Gtk.Label txt_sect_lbl;
        Gtk.Label directory_lbl;
        Gtk.FileChooserButton directory_btn;

        /* Instantiation */
        txt_sect_lbl = new Gtk.Label ("Todo.txt");

        directory_btn = new Gtk.FileChooserButton ("Todo.txt " + _("directory"),
            Gtk.FileChooserAction.SELECT_FOLDER);

        directory_lbl = new Gtk.Label (
            "<a href=\"http://todotxt.com\">Todo.txt</a> "
            + _("directory") + ":"
        );

        /* Configuration */
        directory_lbl.set_line_wrap (false);
        directory_lbl.set_use_markup (true);
        directory_btn.create_folders = true;
        if (settings.todo_txt_location != null) {
            directory_btn.set_current_folder (settings.todo_txt_location);
        }

        /* Signal Handling */
        directory_btn.file_set.connect ((e) => {
            var todo_dir = directory_btn.get_file ().get_path ();
            settings.todo_txt_location = todo_dir;
        });

        add_section (main_layout, txt_sect_lbl, ref row);
        add_option (main_layout, directory_lbl, directory_btn, ref row);
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

        /* Instantiation */
        timer_sect_lbl = new Gtk.Label (_("Timer"));
        task_lbl = new Gtk.Label (_("Task duration (minutes)") + ":");
        break_lbl = new Gtk.Label (_("Break duration (minutes)") + ":");
        reminder_lbl = new Gtk.Label (_("Reminder before task ends (seconds)") +":");

        // No more than one day: 60 * 24 -1 = 1439
        task_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        // More than ten minutes would not make much sense
        reminder_spin = new Gtk.SpinButton.with_range (0, 600, 1);

        /* Configuration */
        task_spin.value = 25;
        break_spin.value = 5;
        reminder_spin.value = 60;

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

        /* Add widgets */
        add_section (grid, timer_sect_lbl, ref row);
        add_option (grid, task_lbl, task_spin, ref row);
        add_option (grid, break_lbl, break_spin, ref row);
        add_option (grid, reminder_lbl, reminder_spin, ref row);
    }
}
