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
    private Gtk.Label active_task_lbl;
    private Gtk.Grid timer_grid;
    private Gtk.SpinButton h_spin;
    private Gtk.SpinButton m_spin;
    private Gtk.SpinButton s_spin;
    private Gtk.Grid action_grid;
    private Gtk.Button run_btn;
    private Gtk.Button reset_btn;
    private Gtk.Button done_btn;
    
    public TimerView (TaskTimer timer) {
        this.timer = timer;
        
        /* Settings of the widget itself */
        this.orientation = Gtk.Orientation.VERTICAL;
        this.expand = true;
        setup_widgets ();
        set_running (false);
        
        // Connect the timer's signals
        timer.timer_updated.connect (set_time);
        timer.timer_running_changed.connect (set_running);
        timer.active_task_changed.connect ((source, reference) => {
            if (reference.valid ()) {
                // Get Gtk.TreeIterator from reference
                var path = reference.get_path ();
                var model = reference.get_model ();
                Gtk.TreeIter iter;
                model.get_iter (out iter, path);
                // Update display
                string description;
                model.get (iter, 1, out description, -1);
                active_task_lbl.label = description;
            }
        });
        
        // Update timer, to refresh the view
        timer.update ();
    }
    
    public void set_time (Time time) {
        h_spin.value = time.hour;
        m_spin.value = time.minute;
        s_spin.value = time.second;
    }
    
    public void set_running (bool running) {
        if (running) {
            run_btn.label = "Stop";
            run_btn.clicked.connect ((e) => {
                timer.stop ();
            });
        } else {
            run_btn.label = "Start";
            run_btn.clicked.connect ((e) => {
                timer.start ();
            });
        }
    }
    
    /** 
     * Configures the widgets attachted to TimerView.
     */
    private void setup_widgets () {
        /* Instantiation */
        active_task_lbl = new Gtk.Label ("Nothing to do...");
        
        this.add (active_task_lbl);
        
        setup_timer_container ();
        setup_action_container ();
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
        h_spin.orientation = Gtk.Orientation.VERTICAL;
        m_spin.orientation = Gtk.Orientation.VERTICAL;
        s_spin.orientation = Gtk.Orientation.VERTICAL;
        
        /* Signal Handling */
        /*
         * TODO: Reduce code redundancy by connecting to a function.
         * I tried it, but for some reason the compiler keeps stating, that 
         * it's name does not exist in the given context.
         */
        h_spin.value_changed.connect (() => {
            timer.remaining_duration = JDI.Utils.hms_to_time (
                (int) h_spin.value,
                (int) m_spin.value,
                (int) s_spin.value
            );
        });
        m_spin.value_changed.connect (() => {
            timer.remaining_duration = JDI.Utils.hms_to_time (
                (int) h_spin.value,
                (int) m_spin.value,
                (int) s_spin.value
            );
        });
        s_spin.value_changed.connect (() => {
            timer.remaining_duration = JDI.Utils.hms_to_time (
                (int) h_spin.value,
                (int) m_spin.value,
                (int) s_spin.value
            );
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
        run_btn = new Gtk.Button ();
        reset_btn = new Gtk.Button.with_label ("Reset");
        done_btn = new Gtk.Button.with_label ("Done");
        
        /* Configuration */
        action_grid.orientation = Gtk.Orientation.HORIZONTAL;
        action_grid.hexpand = true;
        run_btn.margin = 7;
        reset_btn.margin = 7;
        done_btn.margin = 7;
        
        /* Action Handling */
        reset_btn.clicked.connect ((e) => {
            timer.stop ();
            timer.reset ();
        });
        done_btn.clicked.connect ((e) => {
            timer.set_active_task_done();
        });
        
        /* Add Widgets */
        action_grid.add (run_btn);
        action_grid.add (reset_btn);
        action_grid.add (done_btn);
        this.add (action_grid);
    }
}
