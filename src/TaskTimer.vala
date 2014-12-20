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
 * The central class for handling and coordinating timer functionality
 */
public class TaskTimer {
    public bool running { get; private set; default = false; }
    public bool break_active {get; private set; default = false; }
    private Time total_duration;
    /**
     * A proxy attribute, that does not store any data itself, but provides
     * convenient access to total_duration considering the current runtime.
     */
    public Time remaining_duration {
        get {
            var diff = total_duration.mktime () - get_runtime ().mktime ();
            return Time.gm (diff);
        }
        set {
            // Don't change, while timer is running
            if (!running) {
                var diff = value.mktime () - remaining_duration.mktime ();
                var new_total_duration = total_duration.mktime () + diff;
                total_duration = Time.gm (new_total_duration);
                timer_updated (remaining_duration);
            }
        }
    }
    public Time start_time;
    private Gtk.TreeRowReference _active_task;
    public Gtk.TreeRowReference active_task {
        get { return _active_task; }
        set {
            // Don't change task, while timer is running
            if (!running) {
                _active_task = value;
                // Emit the corresponding notifier signal
                active_task_changed (_active_task, break_active);
            }
        }
    }
    
    /* Signals */
    public signal void timer_updated (Time remaining_duration);
    public signal void timer_running_changed (bool running);
    public signal void timer_finished (bool break_active);
    public signal void active_task_done (Gtk.TreeRowReference task);
    public signal void active_task_changed (Gtk.TreeRowReference task, 
        bool break_active);
    
    public TaskTimer () {
       /*
        * The TaskTimer's update loop. Actual time tracking is implemnted
        * by comparing timestamps, so the update interval has no influence 
        * on that.
        */
        Timeout.add_full (Priority.DEFAULT, 500, () => {
            if (running) {
                if (has_finished ()) {
                    on_timer_finished ();
                }
                timer_updated (remaining_duration);
            }
            // TODO: Check if it may make sense to check for program exit state
            return true;
        });
        reset ();
    }
     
    public void start () {
        if (!running) {
            start_time = Time.gm (time_t ());
            running = true;
            timer_running_changed (running);
        }
    }
    
    public void stop () {
        if (running) {
            total_duration = remaining_duration;
            running = false;
            timer_running_changed (running);
        }
    }
    
    public void reset () {
        // TODO: Replace hardcoded value by user's settings
        time_t default_duration;
        if (break_active) {
            default_duration = 5 * 60;
        } else {
            default_duration = 25 * 60;
        }
        total_duration = Time.gm (default_duration);
        timer_updated (remaining_duration);
    }
    
    /**
     * Used to initiate a timer_updated signal from outside of this class.
     */
    public void update () {
        timer_updated (remaining_duration);
    }
    
    /**
     * Used to emit an "active_task_done" signal from outside of this class.
     */
    public void set_active_task_done () {
        stop ();
        active_task_done (_active_task);
    }
    
    /**
     * Determines if the running timer has finished, according to runtime and
     * duration.
     */
    private bool has_finished () {
        return (get_runtime ().mktime () >= total_duration.mktime ());
    }
    
    public Time get_runtime () {
        if (running) {
            var current_time = Time.gm (time_t ());
            var diff = current_time.mktime () - start_time.mktime ();
            return Time.gm (diff);
        } else {
            return Time.gm (0);
        }
    }
    
    /**
     * Used to toggle between break and work state.
     */
    public void toggle_break () {
        break_active = !break_active;
        reset ();
        if (break_active) {
            start ();
        }
        active_task_changed (_active_task, break_active);
    }
    
    /** 
     * The routine, that is to be executed when the timer has finished.
     * Handles switchting between breaks and active tasks as well as
     * emitting all corresponding signals.
     */
    private void on_timer_finished ()  {
        // Emit the "timer_finished" signal
        timer_finished (break_active);
        stop ();
        toggle_break ();
    }
}
