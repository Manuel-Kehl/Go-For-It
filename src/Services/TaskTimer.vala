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
 * The central class for handling and coordinating timer functionality
 */
public class GOFI.TaskTimer {
    public bool running { get; private set; default = false; }
    public bool break_active {get; private set; default = false; }
    private uint update_loop_id;

    private int64 start_sys_time;
    private int64 prev_update_sys_time;
    private int64 prev_task_update_sys;
    private int64 task_time;

    private int64 iteration_duration;

    private const int64 us_c = 1000000; // μs<->s conversion

    public const int64 update_interval = 60 * us_c;

    /**
     * A proxy attribute, that does not store any data itself, but provides
     * convenient way to get the remaining duration in seconds;
     */
    public uint remaining_duration {
        // owned, so that it returns a strong reference
        get {
            int64 total_runtime;
            if (running) {
                var now_monotonic = GLib.get_monotonic_time ();
                total_runtime = now_monotonic - start_sys_time + previous_runtime;
            } else {
                total_runtime = previous_runtime;
            }
            return us_to_s (iteration_duration - total_runtime);
        }
        set {
            // Don't change, while timer is running
            if (!running) {
                iteration_duration = value * us_c + previous_runtime;
                update ();
            }
        }
    }
    private DateTime start_time;
    private int64 previous_runtime { get; set; default = 0; }

    private TodoTask? _active_task;
    public TodoTask? active_task {
        get { return _active_task; }
        internal set {
            bool was_running = running;
            stop ();
            if (settings.reset_timer_on_task_switch) {
                reset ();
            }

            if (_active_task != null) {
                _active_task.notify["description"].disconnect (on_task_notify_description);
            }
            _active_task = value;
            task_time = _active_task.timer_value * us_c;
            if (_active_task != null) {
                _active_task.notify["description"].connect (on_task_notify_description);
            }

            var task_duration = _active_task.duration;
            task_duration_exceeded_sent_already =
                task_duration == 0 || task_duration < _active_task.timer_value;

            // Emit the corresponding notifier signal
            update_active_task ();

            if (was_running && _active_task != null && !settings.reset_timer_on_task_switch) {
                start ();
            }
        }
    }
    private bool almost_over_sent_already { get; set; default = false; }
    private bool task_duration_exceeded_sent_already { get; set; default = false; }

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
            if (value == null) {
                value = settings.schedule;
            }
            if (value == _schedule) {
                return;
            }
            _schedule = value;
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
    public signal void timer_updated (uint remaining_duration);
    public signal void timer_updated_relative (double progress);
    public signal void timer_started ();
    public signal void timer_stopped (DateTime start_time, uint runtime);
    public signal void timer_almost_over (uint remaining_duration);
    public signal void timer_finished (bool break_active);
    public signal void task_time_updated (TodoTask task);
    public signal void active_task_description_changed (TodoTask task);
    public signal void active_task_changed (TodoTask? task);
    public signal void task_duration_exceeded ();

    public TaskTimer () {
        _reminder_time = -1;
        _schedule = settings.schedule;

        /* Signal Handling*/
        settings.timer_duration_changed.connect ((e) => {
            if (!running) {
                reset ();
            }
        });

        reset ();
    }

    private uint us_to_s (int64 us_val) {
        return (uint) ((us_val + 500000) / us_c);
    }

    public void toggle_running () {
        if (running) {
            stop ();
        } else {
            start ();
        }
    }

    public void start () {
        if (!running && _active_task != null) {
            start_time = new DateTime.now_utc ();
            start_sys_time = GLib.get_monotonic_time ();
            prev_task_update_sys = start_sys_time;
            almost_over_sent_already = false;

            /*
             * The TaskTimer's update loop. Actual time tracking is implemented
             * by comparing timestamps, so the update interval has no influence
             * on that.
             */
            update_loop_id = Timeout.add_full (Priority.DEFAULT, 500, update_loop);
            running = true;
            timer_started ();
            _active_task.status |= TaskStatus.TIMER_ACTIVE;
        }
    }

    public void stop () {
        if (running) {
            var now_monotonic = GLib.get_monotonic_time ();
            _stop (now_monotonic);
        }
    }

    private void _stop (int64 last_measurement) {
        var runtime = last_measurement - start_sys_time;
        previous_runtime += runtime;

        update_task_time (last_measurement, true);

        GLib.Source.remove (update_loop_id);
        running = false;
        timer_stopped (start_time, us_to_s (runtime));
        _active_task.status ^= TaskStatus.TIMER_ACTIVE;
    }

    private void stop_with_inconsistent_time () {
        if (running) {
            _stop (prev_update_sys_time);
        }
    }

    public void reset () {
        int64 default_duration;
        if (break_active) {
            default_duration = schedule.get_break_duration (iteration);
        } else {
            default_duration = schedule.get_task_duration (iteration);
        }
        iteration_duration = default_duration * us_c;
        previous_runtime = 0;
        update ();
    }

    private bool update_loop () {
        update ();
        return true;
    }

    /**
     * Used to initiate a timer_updated signal from outside of this class.
     */
    public void update () {
        int64 total_runtime, remaining_us, now_monotonic;

        now_monotonic = GLib.get_monotonic_time ();

        if (running) {
            if (prev_update_sys_time - now_monotonic > 60 * us_c) {
                stdout.printf (
                    "The monotonic system time has jumped by more than a minute!" +
                        " (~0.5s was expected)\n" +
                    "The system was either suspended or is starved for resources.\n" +
                    "Stopping the timer!\n"
                );
                stop_with_inconsistent_time ();
                return;
            }

            total_runtime = now_monotonic - start_sys_time + previous_runtime;
            remaining_us = iteration_duration - total_runtime;

            if (remaining_us <= 0) {
                end_iteration ();
                return;
            }
        } else {
            total_runtime = previous_runtime;
            remaining_us = iteration_duration - total_runtime;
        }

        timer_updated (us_to_s (remaining_us));
        double progress = ((double) total_runtime) / ((double) iteration_duration);
        timer_updated_relative (progress);

        if (!running || break_active) {
            return;
        }

        prev_update_sys_time = now_monotonic;

        update_task_time (now_monotonic, false);

        check_almost_over (total_runtime);
    }

    // Check if "almost over" signal is to be send
    private void check_almost_over (int64 total_runtime) {
        if (!almost_over_sent_already &&
            iteration_duration - total_runtime <= reminder_time * us_c ) {
            if (settings.reminder_active) {
                timer_almost_over (remaining_duration);
            }
            almost_over_sent_already = true;
        }
    }

    private void update_task_time (int64 now_monotonic, bool force_update) {
        var time_diff = now_monotonic - prev_task_update_sys;

        if (force_update || time_diff >= update_interval) {
            prev_task_update_sys = now_monotonic;
            task_time += time_diff;

            _active_task.timer_value = us_to_s (task_time);
            task_time_updated (_active_task);

            if (!task_duration_exceeded_sent_already &&
                task_time >= _active_task.duration * us_c) {
                task_duration_exceeded ();
                task_duration_exceeded_sent_already = true;
            }
        }
    }

    /**
     * Used to initate an active_task_changed signal
     */
    public void update_active_task () {
        active_task_changed (_active_task);
    }

    /**
     * Used to signal that the task description has changed.
     */
    private void on_task_notify_description () {
        active_task_description_changed (_active_task);
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
        active_task_changed (_active_task);
    }

    /**
     * Ends the current iteration of the timer (either active task or break)
     * Is to be executed when the timer finishes, or skip has been initiated.
     * Handles switchting between breaks and active tasks as well as
     * emitting all corresponding signals.
     */
    public void end_iteration () {
        // Emit the "timer_finished" signal
        timer_finished (break_active);
        stop ();
        toggle_break ();
    }
}
