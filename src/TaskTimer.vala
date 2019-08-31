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

/**
 * The central class for handling and coordinating timer functionality
 */
class GOFI.TaskTimer {
    public bool running { get; private set; default = false; }
    public bool break_active {get; private set; default = false; }
    /**
     * The duration till the end, since the last start of the timer
     */
    private DateTime duration_till_end;
    /**
     * A proxy attribute, that does not store any data itself, but provides
     * convenient access to duration_till_end considering the current runtime.
     */
    public DateTime remaining_duration {
        // owned, so that it returns a strong reference
        owned get {
            var diff = duration_till_end.difference (get_runtime ());
            return new DateTime.from_unix_utc (0).add (diff);
        }
        set {
            // Don't change, while timer is running
            if (!running) {
                TimeSpan diff = value.difference (remaining_duration);
                duration_till_end = duration_till_end.add (diff);
                update ();
            }
        }
    }
    public DateTime start_time;
    private int64 previous_runtime { get; set; default = 0; }
    private TodoTask? _active_task;
    public TodoTask? active_task {
        get { return _active_task; }
        set {
            bool was_running = running;
            stop ();
            if (settings.reset_timer_on_task_switch) {
                reset ();
            }

            if (_active_task != null) {
                _active_task.notify["description"].disconnect (on_task_notify_description);
            }
            _active_task = value;
            if (_active_task != null) {
                _active_task.notify["description"].connect (on_task_notify_description);
            }

            // Emit the corresponding notifier signal
            update_active_task ();

            if (was_running && _active_task != null && !settings.reset_timer_on_task_switch) {
                start ();
            }
        }
    }
    private bool almost_over_sent_already { get; set; default = false; }

    /**
     * These properies provide access to the timer values that should be used.
     * These properies will generally just return the value set in settings, but
     * can be used to set different timer values for specific lists or tasks.
     * Setting a property to null or -1 will reset the value to the global settings
     * value.
     */
    public Schedule? schedule {
        public get {
            return _schedule;
        }
        public set {
            if (value == _schedule) {
                return;
            }
            _schedule = value;
            if (_schedule == null) {
                _schedule = settings.schedule;
            }
            iteration = 0;
            reset ();
        }
    }
    public int reminder_time {
        public get {
            if (_reminder_time < 0) {
                return settings.reminder_time;
            }
            return _reminder_time;
        }
        public set {
            _reminder_time = value;
            update ();
        }
    }
    private int _reminder_time;
    private Schedule _schedule;
    private uint iteration;

    /* Signals */
    public signal void timer_updated (DateTime remaining_duration);
    public signal void timer_updated_relative (double progress);
    public signal void timer_running_changed (bool running);
    public signal void timer_almost_over (DateTime remaining_duration);
    public signal void timer_finished (bool break_active);
    public signal void active_task_done (TodoTask task);
    public signal void active_task_description_changed (TodoTask task);
    public signal void active_task_changed (TodoTask? task, bool break_active);

    public TaskTimer () {
        _reminder_time = -1;
        _schedule = settings.schedule;

        /* Signal Handling*/
        settings.timer_duration_changed.connect ((e) => {
            if (!running) {
                reset ();
            }
        });

        /*
         * The TaskTimer's update loop. Actual time tracking is implemented
         * by comparing timestamps, so the update interval has no influence
         * on that.
         */
        Timeout.add_full (Priority.DEFAULT, 500, () => {
            if (running) {
                if (has_finished ()) {
                    end_iteration ();
                }
                update ();
            }
            // TODO: Check if it may make sense to check for program exit state
            return true;
        });
        reset ();
    }

    public void toggle_running () {
        if (running) {
            stop ();
        } else {
            start ();
        }
    }

    public void start () {
        if (!running && active_task != null) {
            start_time = new DateTime.now_utc ();
            running = true;
            timer_running_changed (running);
        }
    }

    public void stop () {
        if (running) {
            duration_till_end = remaining_duration;
            var runtime = get_runtime ().to_unix ();
            previous_runtime += runtime;
            if (_active_task != null && !break_active) {
                _active_task.timer_value += (uint) runtime;
            }
            running = false;
            timer_running_changed (running);
        }
    }

    public void reset () {
        int64 default_duration;
        if (break_active) {
            default_duration = schedule.get_break_duration (iteration);
        } else {
            default_duration = schedule.get_task_duration (iteration);
        }
        duration_till_end = new DateTime.from_unix_utc (default_duration);
        previous_runtime = 0;
        update ();
    }

    /**
     * Used to initiate a timer_updated signal from outside of this class.
     */
    public void update () {
        timer_updated (remaining_duration);

        double runtime =
            (double) (get_runtime ().to_unix () + previous_runtime);
        double total =
            (double) (duration_till_end.to_unix () + previous_runtime);
        double progress = runtime / total;
        timer_updated_relative (progress);

        // Check if "almost over" signal is to be send
        if (remaining_duration.to_unix () <= reminder_time) {
            if (settings.reminder_active
                    && !almost_over_sent_already
                    && running
                    && !break_active) {

                timer_almost_over (remaining_duration);
                almost_over_sent_already = true;
            }
        } else {
            almost_over_sent_already = false;
        }
    }

    /**
     * Used to initate an active_task_changed signal
     */
    public void update_active_task () {
        active_task_changed (_active_task, break_active);
    }

    /**
     * Used to signal that the task description has changed.
     */
    private void on_task_notify_description () {
        active_task_description_changed (_active_task);
    }

    /**
     * Used to emit an "active_task_done" signal from outside of this class.
     */
    public void set_active_task_done () {
        bool was_running = running;
        stop ();
        active_task_done (_active_task);
        // Resume break, only keep stopped when a task is active
        if ((break_active || !settings.reset_timer_on_task_switch) && was_running) {
            start ();
        }
    }

    /**
     * Determines if the running timer has finished, according to runtime and
     * duration.
     */
    private bool has_finished () {
        return (get_runtime ().compare (duration_till_end) >= 0);
    }

    public DateTime get_runtime () {
        if (running) {
            var diff = new DateTime.now_utc ().difference (start_time);
            return new DateTime.from_unix_utc (0).add (diff);
        } else {
            return new DateTime.from_unix_utc (0);
        }
    }

    /**
     * Used to toggle between break and work state.
     */
    private void toggle_break () {
        if (break_active) {
            iteration++;
        }
        break_active = !break_active;

        reset ();
        if (break_active || settings.resume_tasks_after_break) {
            start ();
        }
        active_task_changed (_active_task, break_active);
    }

    /**
     * Ends the current iteration of the timer (either active task or break)
     * Is to be executed when the timer finishes, or skip has been initiated.
     * Handles switchting between breaks and active tasks as well as
     * emitting all corresponding signals.
     */
    public void end_iteration ()  {
        // Emit the "timer_finished" signal
        timer_finished (break_active);
        stop ();
        toggle_break ();
    }
}
