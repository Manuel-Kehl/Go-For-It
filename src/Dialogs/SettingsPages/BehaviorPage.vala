/* Copyright 2014-2020 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

using GOFI.DialogUtils;

class GOFI.BehaviorPage : Gtk.Box {
    SynchronizedWLabel task_lbl1;
    Gtk.Label task_lbl2;
    Gtk.SpinButton task_spin;

    SynchronizedWLabel break_lbl1;
    Gtk.Label break_lbl2;
    Gtk.SpinButton break_spin;

    SynchronizedWLabel long_break_lbl1;
    Gtk.Label long_break_lbl2;
    Gtk.SpinButton long_break_spin;

    SynchronizedWLabel long_break_period_lbl1;
    Gtk.Label long_break_period_lbl2;
    Gtk.SpinButton long_break_period_spin;

    SynchronizedWLabel timer_mode_lbl;
    Gtk.ComboBoxText timer_mode_cbox;

    Gtk.Label resume_task_lbl;
    Gtk.Switch resume_task_switch;

    Gtk.Label reset_on_switch_lbl;
    Gtk.Switch reset_on_switch_switch;

    TimerScheduleWidget cust_sched_widget;

    public BehaviorPage () {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 12);
        var wcont = new SynchronizedWCont ();
        this.add (create_task_settings_section (wcont));
        this.add (create_timer_settings_section (wcont));
    }

    private Gtk.Widget create_timer_settings_section (SynchronizedWCont wcont) {
        timer_mode_lbl = new SynchronizedWLabel (wcont, _("Timer mode") + ":");
        timer_mode_cbox = new Gtk.ComboBoxText ();
        timer_mode_cbox.append (TimerMode.STR_SIMPLE, _("Simple"));
        timer_mode_cbox.append (TimerMode.STR_POMODORO, _("Pomodoro"));
        timer_mode_cbox.append (TimerMode.STR_CUSTOM, _("Custom"));
        timer_mode_cbox.active_id = settings.timer_mode.to_string ();
        timer_mode_cbox.changed.connect ( () => {
            var timer_mode = TimerMode.from_string (timer_mode_cbox.active_id);
            settings.timer_mode = timer_mode;
            this.show_all ();
        });

        task_lbl1 = new SynchronizedWLabel (wcont, _("Task duration") + ":");
        task_lbl2 = new Gtk.Label (_("minutes"));
        task_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        task_spin.value = settings.task_duration / 60;
        task_spin.value_changed.connect ((e) => {
            settings.task_duration = task_spin.get_value_as_int () * 60;
        });

        break_lbl1 = new SynchronizedWLabel (wcont, _("Break duration") + ":");
        break_lbl2 = new Gtk.Label (_("minutes"));
        break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        break_spin.value = settings.break_duration / 60;
        break_spin.value_changed.connect ((e) => {
            settings.break_duration = break_spin.get_value_as_int () * 60;
        });

        long_break_lbl1 = new SynchronizedWLabel (wcont, _("Long break duration") + ":");
        long_break_lbl2 = new Gtk.Label (_("minutes"));
        long_break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        long_break_spin.value = settings.long_break_duration / 60;
        long_break_spin.value_changed.connect ((e) => {
            settings.long_break_duration = long_break_spin.get_value_as_int () * 60;
        });

        /// Part of "Have a long break after # short breaks"
        var long_break_period_text1 = _("Have a long break after");
        /// Part of "Have a long break after # short breaks"
        var long_break_period_text2 = _("short breaks");
        long_break_period_lbl1 = new SynchronizedWLabel (wcont, long_break_period_text1);
        long_break_period_lbl2 = new Gtk.Label (long_break_period_text2);
        long_break_period_spin = new Gtk.SpinButton.with_range (1, 99, 1);
        long_break_period_spin.value = settings.pomodoro_period - 1;
        long_break_period_spin.value_changed.connect ((e) => {
            settings.pomodoro_period = long_break_period_spin.get_value_as_int () + 1;
        });

        cust_sched_widget = new TimerScheduleWidget ();
        cust_sched_widget.schedule_updated.connect ((sched) => {
            settings.schedule = sched;
        });

        var schedule_grid = create_page_grid ();
        int pos = 0;
        add_option (schedule_grid, ref pos, timer_mode_lbl, timer_mode_cbox);
        add_option (schedule_grid, ref pos, task_lbl1, task_spin, task_lbl2);
        add_option (schedule_grid, ref pos, break_lbl1, break_spin, break_lbl2);
        add_option (schedule_grid, ref pos, long_break_lbl1, long_break_spin, long_break_lbl2);
        add_option (schedule_grid, ref pos, long_break_period_lbl1, long_break_period_spin, long_break_period_lbl2);
        schedule_grid.attach (cust_sched_widget, 0, pos, 3, 1);

        resume_task_lbl = new Gtk.Label ( _("Resume task after the break") + ":");
        resume_task_switch = new Gtk.Switch ();
        resume_task_switch.active = settings.resume_tasks_after_break;
        resume_task_switch.notify["active"].connect (() => {
            settings.resume_tasks_after_break = resume_task_switch.active;
        });

        reset_on_switch_lbl = new Gtk.Label (_("Reset timer after switching tasks") + ":");
        reset_on_switch_switch = new Gtk.Switch ();
        reset_on_switch_switch.active = settings.reset_timer_on_task_switch;
        reset_on_switch_switch.notify["active"].connect (() => {
            settings.reset_timer_on_task_switch = reset_on_switch_switch.active;
        });

        var misc_grid = create_page_grid ();
        pos = 0;

        add_option (misc_grid, ref pos, resume_task_lbl, resume_task_switch);
        add_option (misc_grid, ref pos, reset_on_switch_lbl, reset_on_switch_switch);

        var timer_box = new Gtk.Box (Gtk.Orientation.VERTICAL, SPACING_SETTINGS_ROW);
        timer_box.add (schedule_grid);
        timer_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        timer_box.add (misc_grid);

        return create_section_box (_("Timer"), timer_box);
    }

    private Gtk.Widget create_task_settings_section (SynchronizedWCont wcont) {
        SynchronizedWLabel placement_lbl = new SynchronizedWLabel (wcont, _("Placement of new tasks") + ":");
        Gtk.ComboBoxText placement_cbox = new Gtk.ComboBoxText ();

        placement_cbox.append ("top", _("Top of the list"));
        placement_cbox.append ("bottom", _("Bottom of the list"));
        placement_cbox.active_id =
            settings.new_tasks_on_top ? "top" : "bottom";

        placement_cbox.changed.connect ( () => {
            settings.new_tasks_on_top =
                placement_cbox.active_id == "top";
        });

        int pos = 0;
        var task_grid = create_page_grid ();
        add_option (task_grid, ref pos, placement_lbl, placement_cbox);
        return create_section_box (_("Tasks"), task_grid);
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
                cust_sched_widget.hide ();
                break;
            case TimerMode.POMODORO:
                cust_sched_widget.hide ();
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

                cust_sched_widget.load_schedule (settings.schedule);
                break;
        }
    }
}
