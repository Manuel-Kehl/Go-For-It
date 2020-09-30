/* Copyright 2014-2020 Go For It! developers
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

/**
 * The widget for selecting, displaying and controlling the active task.
 */
class GOFI.TimerView : Gtk.Grid {
    /* Various Variables */
    private TaskTimer timer;

    /* GTK Widgets */
    private Gtk.ProgressBar progress;
    private Gtk.Label task_status_lbl;
    private Gtk.Label task_description_lbl;
    private Gtk.Label task_duration_lbl;
    private Gtk.Grid timer_grid;
    private Gtk.SpinButton h_spin;
    private Gtk.SpinButton m_spin;
    private Gtk.SpinButton s_spin;
    private Gtk.Grid action_grid;
    private Gtk.Grid action_timer_grid;
    private Gtk.Grid action_task_grid;
    private Gtk.Button run_btn;
    private Gtk.Button skip_btn;
    public Gtk.Button done_btn;

    public signal void done_btn_clicked ();

    public TimerView (TaskTimer timer) {
        this.timer = timer;

        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;

        setup_task_widgets ();
        setup_timer_container ();
        setup_action_container ();
        setup_progress_bar ();

        if (timer.running) {
            on_timer_started ();
        } else {
            on_timer_stopped ();
        }

        // Connect the timer's signals
        timer.timer_updated.connect (set_time);
        timer.timer_started.connect (on_timer_started);
        timer.timer_stopped.connect (on_timer_stopped);
        timer.active_task_changed.connect (timer_active_task_changed);
        timer.timer_updated_relative.connect ((s, p) => {
            progress.set_fraction (p);
        });
        timer.task_time_updated.connect (update_task_duration);
        timer.active_task_description_changed.connect (update_description);

        // Update timer, to refresh the view
        timer.update ();
    }

    private void timer_active_task_changed (TodoTask? task) {
        if (task == null) {
            show_no_task ();
            return;
        }

        skip_btn.visible = true;
        run_btn.visible = true;

        update_description (task);
        var style = task_description_lbl.get_style_context ();

        // Append correct class according to break status
        if (timer.break_active) {
            task_status_lbl.label = _("Take a Break") + "!";
            style.remove_class ("task_active");
            style.add_class ("task_break");
        } else {
            task_status_lbl.label = _("Active Task") + ":";
            style.remove_class ("task_break");
            style.add_class ("task_active");
            done_btn.visible = true;
        }
    }

    private void update_description (TodoTask task) {
        task_description_lbl.label = task.description;
        update_task_duration (task);
    }

    public void update_task_duration (TodoTask task) {
        var duration = task.duration;
        if (duration > 0) {
            var timer_value = task.timer_value;
            task_duration_lbl.label = "<i>%u / %s</i>".printf (
                timer_value / 60,
                Utils.seconds_to_short_string (duration)
            );
            var style = task_duration_lbl.get_style_context ();
            if (duration <= timer_value) {
                style.add_class ("task_duration_exceeded");
            } else {
                style.remove_class ("task_duration_exceeded");
            }
            task_duration_lbl.visible = true;
        } else {
            task_duration_lbl.label = "";
            task_duration_lbl.visible = false;
        }
    }

    public void set_time (uint timer_value) {
        uint hours, minutes, seconds;
        Utils.uint_to_time (timer_value, out hours, out minutes, out seconds);
        h_spin.value = hours;
        m_spin.value = minutes;
        s_spin.value = seconds;
    }

    public void on_timer_started () {
        done_btn.visible = !timer.break_active;

        run_btn.label = _("Pau_se");
        run_btn.get_style_context ().remove_class ("suggested-action");
    }

    public void on_timer_stopped () {
        done_btn.visible = !timer.break_active;

        run_btn.label = _("_Start");
        run_btn.get_style_context ().add_class ("suggested-action");
    }

    private void on_run_btn_clicked () {
        timer.toggle_running ();
    }

    public uint get_timer_value ()  {
        var hours   = (uint) h_spin.get_value_as_int ();
        var minutes = (uint) m_spin.get_value_as_int ();
        var seconds = (uint) s_spin.get_value_as_int ();
        return Utils.time_to_uint (hours, minutes, seconds);
    }

    /**
     * Configures the widgets that indicate the active task and its progress
     */
    private void setup_task_widgets () {
        /* Instantiation */
        task_status_lbl = new Gtk.Label (_("Inactive"));
        task_description_lbl = new Gtk.Label (_("No task has been selected"));
        task_duration_lbl = new Gtk.Label ("");

        /* Configuration */
        task_status_lbl.margin_top = 30;
        task_status_lbl.get_style_context ().add_class ("task_status");
        task_description_lbl.margin = 20;
        task_description_lbl.margin_top = 30;
        task_description_lbl.margin_bottom = 10;
        task_description_lbl.lines = 3;
        task_description_lbl.wrap = true;

        task_duration_lbl.use_markup = true;
        task_duration_lbl.margin_bottom = 10;

        /* Add Widgets */
        this.add (task_status_lbl);
        this.add (task_description_lbl);
        this.add (task_duration_lbl);
    }

    /**
     * Configures the container with the timer elements.
     */
    private void setup_timer_container () {
        /* Instantiation */
        timer_grid = new Gtk.Grid ();
        h_spin = new Gtk.SpinButton.with_range (0, 59, 1);
        m_spin = new Gtk.SpinButton.with_range (0, 59, 1);
        s_spin = new Gtk.SpinButton.with_range (0, 59, 1);

        /* Configuration */
        timer_grid.expand = true;
        timer_grid.orientation = Gtk.Orientation.HORIZONTAL;
        timer_grid.halign = Gtk.Align.CENTER;
        timer_grid.valign = Gtk.Align.CENTER;
        timer_grid.margin_top = 10;
        // Add CSS class
        timer_grid.get_style_context ().add_class ("timerview");
        h_spin.orientation = Gtk.Orientation.VERTICAL;
        m_spin.orientation = Gtk.Orientation.VERTICAL;
        s_spin.orientation = Gtk.Orientation.VERTICAL;

        use_leading_zeros (h_spin);
        use_leading_zeros (m_spin);
        use_leading_zeros (s_spin);

        /* Signal Handling */
        h_spin.value_changed.connect (() => {
            timer.remaining_duration = get_timer_value ();
        });
        m_spin.value_changed.connect (() => {
            timer.remaining_duration = get_timer_value ();
        });
        s_spin.value_changed.connect (() => {
            timer.remaining_duration = get_timer_value ();
        });

        /* Add Widgets */
        timer_grid.add (h_spin);
        timer_grid.add (new Gtk.Label (" : "));
        timer_grid.add (m_spin);
        timer_grid.add (new Gtk.Label (" : "));
        timer_grid.add (s_spin);
        this.add (timer_grid);
    }

    /**
     * Makes the passed Gtk.SpinButton fill the display with a leading zero.
     */
    private void use_leading_zeros (Gtk.SpinButton spin) {
        spin.output.connect ((s) => {
            var val = spin.get_value_as_int ();
            // If val <= 10, it's a single digit, so a leading zero is necessary
            if (val < 10) {
                spin.text = "0" + val.to_string ();
                return true;
            }
            return false;
        });
    }

    /**
     * Configures the container with the action buttons.
     */
    private void setup_action_container () {
        /* Instantiation */
        action_grid = new Gtk.Grid ();
        action_timer_grid = new Gtk.Grid ();
        action_task_grid = new Gtk.Grid ();
        run_btn = new Gtk.Button ();
        skip_btn = new Gtk.Button.with_label (_("S_kip"));
        done_btn = new Gtk.Button.with_label (_("_Done"));

        /* Configuration */
        action_grid.orientation = Gtk.Orientation.HORIZONTAL;
        action_grid.hexpand = true;
        action_timer_grid.hexpand = true;
        action_task_grid.hexpand = true;
        action_timer_grid.halign = Gtk.Align.END;
        action_task_grid.halign = Gtk.Align.START;
        done_btn.margin = 7;
        run_btn.margin = 7;
        skip_btn.margin = 7;
        // Use Mnemonics
        done_btn.use_underline = true;
        skip_btn.use_underline = true;
        run_btn.use_underline = true;

        /* Action Handling */
        skip_btn.clicked.connect ((e) => {
            timer.end_iteration ();
        });
        done_btn.clicked.connect ((e) => {
            done_btn_clicked ();
        });
        run_btn.clicked.connect (on_run_btn_clicked);

        /* Add Widgets */
        action_timer_grid.add (skip_btn);
        action_timer_grid.add (run_btn);
        action_task_grid.add (done_btn);
        action_grid.add (action_task_grid);
        action_grid.add (action_timer_grid);
        this.add (action_grid);
    }

    private void setup_progress_bar () {
        progress = new Gtk.ProgressBar ();
        progress.hexpand = true;
        this.add (progress);
    }

    /**
     * This funciton is to be called, when the to-do list is empty
     */
    public void show_no_task () {
        task_status_lbl.label = _("Relax") + "." ;
        task_description_lbl.label = _("You have nothing to do.");
        skip_btn.visible = false;
        run_btn.visible = false;
        done_btn.visible = false;
        task_duration_lbl.label = "";
        task_duration_lbl.visible = false;
    }

    public override void show_all () {
        base.show_all ();
        if (timer.active_task == null) {
            skip_btn.visible = false;
            run_btn.visible = false;
            done_btn.visible = false;
        } else if (timer.break_active) {
            done_btn.visible = false;
        }
        if (task_duration_lbl.label == "") {
            task_duration_lbl.visible = false;
        }
    }

    /**
     * We want to have something to focus on so keybindings of parent widgets
     * can work.
     */
    public void set_focus () {
        run_btn.has_focus = true;
    }
}
