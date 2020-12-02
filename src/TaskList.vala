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

public interface GOFI.TaskList : Object {

    /**
     * @param sched schedule of task and break durations
     * @param reminder_t when to show the reminder before the task ends in seconds
     */
    public signal void timer_values_changed (Schedule? sched, int reminder_t);

    /**
     * Returns the task that is currently selected in the widget returned by
     * get_primary_page.
     */
    public abstract TodoTask? selected_task {
        public get;
        protected set;
    }

    /**
     * Returns the task the user is currently working on.
     * This property will generally be set externally and should only be set
     * from this class when the current value is no longer valid.
     */
    public abstract TodoTask? active_task {
        public get;
        public set;
    }

    public abstract TodoListInfo list_info {
        public get;
    }

    /**
     * Returns file in which to log the timer activity for the active_task
     */
    public virtual File? get_log_file () {
        return null;
    }

    /**
     * Returns the next task relative to active_task.
     */
    public abstract TodoTask? get_next ();

    /**
     * Returns the previous task relative to active_task.
     */
    public abstract TodoTask? get_prev ();

    /**
     * Called when the user has finished working on this task.
     */
    public abstract void mark_done (TodoTask task);

    /**
     * Tasks that the user should currently work on
     */
    public abstract unowned Gtk.Widget get_primary_page (out string? page_name);

    /**
     * Can be future recurring tasks or tasks that are already done
     */
    public abstract unowned Gtk.Widget get_secondary_page (out string? page_name);

    public abstract unowned Gtk.Widget? get_menu ();

    /**
     * Returns the schedule of task and break times specific to this list.
     */
    public abstract Schedule? get_schedule ();

    /**
     * Returns the duration (in seconds) of the break the user should take
     * before resuming work on the task.
     * If no value is configured -1 should be returned.
     */
    public abstract int get_reminder_time ();

    public abstract void add_task_shortcut ();

    /**
     * Called when this list has been selected by the user.
     * This function should be used to initialize the widgets and other objects.
     */
    public abstract void load ();

    /**
     * This function is called when this list is no longer in use but may be
     * loaded again in the future.
     * Widgets and other objects should be freed to preserver resources.
     */
    public abstract void unload ();
}
