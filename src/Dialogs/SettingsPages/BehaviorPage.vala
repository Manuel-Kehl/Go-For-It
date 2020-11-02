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
    Gtk.Label timer_sect_lbl;

    Gtk.Label task_lbl1;
    Gtk.Label task_lbl2;
    Gtk.SpinButton task_spin;

    Gtk.Label break_lbl1;
    Gtk.Label break_lbl2;
    Gtk.SpinButton break_spin;

    Gtk.Label long_break_lbl1;
    Gtk.Label long_break_lbl2;
    Gtk.SpinButton long_break_spin;

    Gtk.Label long_break_period_lbl1;
    Gtk.Label long_break_period_lbl2;
    Gtk.SpinButton long_break_period_spin;

    Gtk.Label timer_mode_lbl;
    Gtk.ComboBoxText timer_mode_cbox;

    Gtk.Label resume_task_lbl;
    Gtk.Switch resume_task_switch;

    Gtk.Label reset_on_switch_lbl;
    Gtk.Switch reset_on_switch_switch;

    TimerScheduleWidget sched_widget;

    public BehaviorPage () {
        int row = 0;
        setup_task_settings_widgets (ref row);
        setup_timer_settings_widgets (ref row);

        apply_grid_spacing (this);
    }

    private void setup_timer_settings_widgets (ref int row) {
        /* Instantiation */
        timer_sect_lbl = new Gtk.Label (_("Timer"));
        task_lbl1 = new Gtk.Label (_("Task duration") + ":");
        task_lbl2 = new Gtk.Label (_("minutes"));
        break_lbl1 = new Gtk.Label (_("Break duration") + ":");
        break_lbl2 = new Gtk.Label (_("minutes"));
        long_break_lbl1 = new Gtk.Label (_("Long break duration") + ":");
        long_break_lbl2 = new Gtk.Label (_("minutes"));
        resume_task_lbl = new Gtk.Label (_("Resume task after the break") + ":");
        reset_on_switch_lbl = new Gtk.Label (_("Reset timer after switching tasks") + ":");

        /// Part of "Have a long break after # short breaks"
        var long_break_period_text1 = _("Have a long break after");
        /// Part of "Have a long break after # short breaks"
        var long_break_period_text2 = _("short breaks");

        long_break_period_lbl1 = new Gtk.Label (long_break_period_text1);
        long_break_period_lbl2 = new Gtk.Label (long_break_period_text2);
        timer_mode_lbl = new Gtk.Label (_("Timer mode") + ":");

        timer_mode_cbox = new Gtk.ComboBoxText ();

        resume_task_switch = new Gtk.Switch ();
        reset_on_switch_switch = new Gtk.Switch ();

        // No more than one day: 60 * 24 -1 = 1439
        task_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        long_break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);

        long_break_period_spin = new Gtk.SpinButton.with_range (1, 99, 1);

        sched_widget = new TimerScheduleWidget ();

        /* Configuration */
        task_spin.value = settings.task_duration / 60;
        break_spin.value = settings.break_duration / 60;
        long_break_spin.value = settings.long_break_duration / 60;
        long_break_period_spin.value = settings.pomodoro_period - 1;

        timer_mode_cbox.append (TimerMode.STR_SIMPLE, _("Simple"));
        timer_mode_cbox.append (TimerMode.STR_POMODORO, _("Pomodoro"));
        timer_mode_cbox.append (TimerMode.STR_CUSTOM, _("Custom"));
        timer_mode_cbox.active_id = settings.timer_mode.to_string ();

        resume_task_switch.active = settings.resume_tasks_after_break;
        reset_on_switch_switch.active = settings.reset_timer_on_task_switch;

        /* Signal Handling */
        task_spin.value_changed.connect ((e) => {
            settings.task_duration = task_spin.get_value_as_int () * 60;
        });
        break_spin.value_changed.connect ((e) => {
            settings.break_duration = break_spin.get_value_as_int () * 60;
        });
        long_break_spin.value_changed.connect ((e) => {
            settings.long_break_duration = long_break_spin.get_value_as_int () * 60;
        });
        long_break_period_spin.value_changed.connect ((e) => {
            settings.pomodoro_period = long_break_period_spin.get_value_as_int () + 1;
        });
        timer_mode_cbox.changed.connect ( () => {
            var timer_mode = TimerMode.from_string (timer_mode_cbox.active_id);
            settings.timer_mode = timer_mode;
            this.show_all ();
        });
        sched_widget.schedule_updated.connect ((sched) => {
            settings.schedule = sched;
        });
        resume_task_switch.notify["active"].connect (() => {
            settings.resume_tasks_after_break = resume_task_switch.active;
        });
        reset_on_switch_switch.notify["active"].connect (() => {
            settings.reset_timer_on_task_switch = reset_on_switch_switch.active;
        });

        /* Add widgets */
        add_section (this, timer_sect_lbl, ref row);
        add_option (this, timer_mode_lbl, timer_mode_cbox, ref row);
        add_option (this, resume_task_lbl, resume_task_switch, ref row);
        add_option (this, reset_on_switch_lbl, reset_on_switch_switch, ref row);
        this.attach (sched_widget, 0, row, 3, 1);
        row++;
        add_option (this, task_lbl1, task_spin, ref row, 1, task_lbl2);
        add_option (this, break_lbl1, break_spin, ref row, 1, break_lbl2);
        add_option (this, long_break_lbl1, long_break_spin, ref row, 1, long_break_lbl2);
        add_option (this, long_break_period_lbl1, long_break_period_spin, ref row, 1, long_break_period_lbl2);

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

    public override void show_all () {
        base.show_all ();
        switch (settings.timer_mode) {
            case TimerMode.SIMPLE:
                long_break_period_spin.hide ();
                long_break_period_lbl1.hide ();
                long_break_period_lbl2.hide ();

                long_break_spin.hide ();
                long_break_lbl1.hide ();
                long_break_lbl2.hide ();
                sched_widget.hide ();
                break;
            case TimerMode.POMODORO:
                sched_widget.hide ();
                break;
            default:
                task_lbl1.hide ();
                task_lbl2.hide ();
                task_spin.hide ();

                break_lbl1.hide ();
                break_lbl2.hide ();
                break_spin.hide ();

                long_break_period_spin.hide ();
                long_break_period_lbl1.hide ();
                long_break_period_lbl2.hide ();

                long_break_spin.hide ();
                long_break_lbl1.hide ();
                long_break_lbl2.hide ();

                sched_widget.load_schedule (settings.schedule);
                break;
        }
    }
}
