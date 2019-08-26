/* Copyright 2014-2019 Go For It! developers
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

class GOFI.BehaviorPage : Gtk.Grid {

    public BehaviorPage () {
        int row = 0;
        setup_task_settings_widgets (ref row);
        setup_timer_settings_widgets (ref row);

        apply_grid_spacing (this);
    }

    private void setup_timer_settings_widgets (ref int row) {
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
        task_spin.value = settings.task_duration / 60;
        break_spin.value = settings.break_duration / 60;
        reminder_spin.value = settings.reminder_time;

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
        add_section (this, timer_sect_lbl, ref row);
        add_option (this, task_lbl, task_spin, ref row);
        add_option (this, break_lbl, break_spin, ref row);
        add_option (this, reminder_lbl, reminder_spin, ref row);
    }

    private void setup_task_settings_widgets (ref int row) {
        /* Declaration */
        Gtk.Label task_sect_lbl;
        Gtk.Label placement_lbl;
        Gtk.ComboBoxText placement_cbox;

        /* Instantiation */
        task_sect_lbl = new Gtk.Label (_("Tasks"));
        placement_lbl = new Gtk.Label (_("Placement of new tasks") + ":");
        placement_cbox = new Gtk.ComboBoxText ();

        placement_cbox.append ("top", _("Top of the list"));
        placement_cbox.append ("bottom", _("Bottom of the list"));
        placement_cbox.active_id =
            settings.new_tasks_on_top ? "top" : "bottom";

        placement_cbox.changed.connect ( () => {
            settings.new_tasks_on_top =
                placement_cbox.active_id == "top";
        });

        /* Add widgets */
        add_section (this, task_sect_lbl, ref row);
        add_option (this, placement_lbl, placement_cbox, ref row);
    }
}
