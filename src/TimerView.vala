/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Just Do It!.
*
* Just Do It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Just Do It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Just Do It!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * The widget for selecting, displaying and controlling the active task.
 */
public class TimerView : Gtk.Grid {
    /* Various Variables */
    private TaskTimer timer;

    /* GTK Widgets */
    private Gtk.ProgressBar progress;
    private Gtk.Label task_status_lbl;
    private Gtk.Label task_description_lbl;
    private Gtk.Grid timer_grid;
    private Gtk.SpinButton h_spin;
    private Gtk.SpinButton m_spin;
    private Gtk.SpinButton s_spin;
    private Gtk.Grid action_grid;
    private Gtk.Grid action_timer_grid;
    private Gtk.Grid action_task_grid;
    private Gtk.Button run_btn;
    private Gtk.Button reset_btn;
    private Gtk.Button done_btn;
    
    public TimerView (TaskTimer timer) {
        this.timer = timer;
        
        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;
        
        setup_task_widgets ();
        setup_timer_container ();
        setup_action_container ();
        
        //this.add (progress);
        
        set_running (false);
        
        // Connect the timer's signals
        timer.timer_updated.connect (set_time);
        timer.timer_running_changed.connect (set_running);
        timer.active_task_changed.connect ((s, reference, break_active) => {
            if (reference.valid ()) {
                // Get Gtk.TreeIterator from reference
                var path = reference.get_path ();
                var model = reference.get_model ();
                Gtk.TreeIter iter;
                model.get_iter (out iter, path);
                
                // Update display
                string description;
                model.get (iter, 1, out description, -1);
                task_description_lbl.label = description;
                var style = task_description_lbl.get_style_context ();
                
                // Append correct class according to break status
                if (break_active) {
                    task_status_lbl.label = "Take a Break!";
                    style.remove_class ("task_active");
                    style.add_class ("task_break");
                } else {
                    task_status_lbl.label = "Active Task:";
                    style.remove_class ("task_break");
                    style.add_class ("task_active");
                }
            }
        });
        timer.timer_updated_relative.connect ((s, p) => {
            progress.set_fraction (p);
        });
        
        // Update timer, to refresh the view
        timer.update ();
    }
    
    public void set_time (DateTime time) {
        h_spin.value = time.get_hour ();
        m_spin.value = time.get_minute ();
        s_spin.value = time.get_second ();
    }
    
    public void set_running (bool running) {
        if (running) {
            run_btn.label = "Pau_se";
            run_btn.get_style_context ().remove_class ("suggested-action");
            run_btn.clicked.connect ((e) => {
                timer.stop ();
            });
        } else {
            run_btn.label = "_Start";
            run_btn.get_style_context ().add_class ("suggested-action");
            run_btn.clicked.connect ((e) => {
                timer.start ();
            });
        }
    }
    
    public DateTime get_timer_values ()  {
        var duration = new DateTime.from_unix_utc (0);
        duration = duration.add_hours ((int) h_spin.value);
        duration = duration.add_minutes ((int) m_spin.value);
        duration = duration.add_seconds (s_spin.value);
        return duration;
    }
    
    /**
     * Configures the widgets that indicate the active task and its progress
     */
    private void setup_task_widgets () {
        /* Instantiation */
        progress = new Gtk.ProgressBar ();
        task_status_lbl = new Gtk.Label ("Relax!");
        task_description_lbl = new Gtk.Label ("You have nothing to do");
        
        /* Configuration */
        progress.hexpand = true;
        task_status_lbl.margin_top = 30;
        task_status_lbl.get_style_context ().add_class ("task_status");
        task_description_lbl.margin = 20;
        task_description_lbl.margin_top = 30;
        task_description_lbl.lines = 3;
        task_description_lbl.wrap = true;
        
        /* Add Widgets */
        this.add (progress);
        this.add (task_status_lbl);
        this.add (task_description_lbl);
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
        // Add CSS class
        timer_grid.get_style_context ().add_class ("timerview");
        h_spin.orientation = Gtk.Orientation.VERTICAL;
        m_spin.orientation = Gtk.Orientation.VERTICAL;
        s_spin.orientation = Gtk.Orientation.VERTICAL;
        
        /* Signal Handling */
        h_spin.value_changed.connect (() => {
            timer.remaining_duration = get_timer_values ();
        });
        m_spin.value_changed.connect (() => {
            timer.remaining_duration = get_timer_values ();
        });
        s_spin.value_changed.connect (() => {
            timer.remaining_duration = get_timer_values ();
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
     * Configures the container with the action buttons.
     */
    private void setup_action_container () {
        /* Instantiation */
        action_grid = new Gtk.Grid ();
        action_timer_grid = new Gtk.Grid ();
        action_task_grid = new Gtk.Grid ();
        run_btn = new Gtk.Button ();
        reset_btn = new Gtk.Button.with_label ("_Reset");
        done_btn = new Gtk.Button.with_label ("_Done");
        
        /* Configuration */
        action_grid.orientation = Gtk.Orientation.HORIZONTAL;
        action_grid.hexpand = true;
        action_timer_grid.hexpand = true;
        action_task_grid.hexpand = true;
        action_timer_grid.halign = Gtk.Align.END;
        action_task_grid.halign = Gtk.Align.START;
        done_btn.margin = 7;
        run_btn.margin = 7;
        reset_btn.margin = 7;
        // Use Mnemonics
        done_btn.use_underline = true;
        reset_btn.use_underline = true;
        run_btn.use_underline = true;
        // Apply style
        reset_btn.get_style_context ().add_class ("destructive-action");
        
        /* Action Handling */
        reset_btn.clicked.connect ((e) => {
            timer.stop ();
            timer.reset ();
        });
        done_btn.clicked.connect ((e) => {
            timer.set_active_task_done();
        });
        
        /* Add Widgets */
        action_timer_grid.add (reset_btn);
        action_timer_grid.add (run_btn);
        action_task_grid.add (done_btn);
        action_grid.add (action_task_grid);
        action_grid.add (action_timer_grid);
        this.add (action_grid);
    }
}
