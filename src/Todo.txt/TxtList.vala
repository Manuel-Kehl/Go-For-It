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
class GOFI.TXT.TxtList : GOFI.TaskList, Object {
    private TaskManager task_manager;
    private TaskListWidget todo_list;
    private TaskListWidget done_list;

    private Gtk.ModelButton clear_done_button;

    public ListSettings list_settings {
        public get;
        private set;
    }

    /**
     * Returns the task that is currently selected in the widget returned by
     * get_primary_page.
     */
    public TodoTask? selected_task {
        public get;
        protected set;
    }

    /**
     * Returns the task the user is currently working on.
     * This property will generally be set externally and should only be set
     * from this class when the current value is no longer valid.
     */
    public TodoTask? active_task {
        public get {
            return _active_task;
        }
        public set {
            _active_task = (TxtTask) value;
            task_manager.set_active_task (_active_task);
            if (_active_task != null) {
                todo_list.select_task (_active_task);
            }
        }
    }
    private TxtTask? _active_task;

    public TodoListInfo list_info {
        public get {
            return list_settings;
        }
    }

    public TxtList (ListSettings list_settings) {
        this.list_settings = list_settings;

        list_settings.notify.connect (on_list_settings_notify);
    }

    private void on_list_settings_notify (ParamSpec pspec) {
        switch (pspec.get_name ()) {
            case "schedule":
                signal_timer_values ();
                break;
            case "reminder_time":
                signal_timer_values ();
                break;
            default:
                break;
        }
    }

    private void signal_timer_values () {
        timer_values_changed (
            list_settings.schedule,
            list_settings.reminder_time
        );
    }

    /**
     * Returns the next task relative to active_task.
     */
    public TodoTask? get_next () {
        return task_manager.get_next ();
    }

    /**
     * Returns the previous task relative to active_task.
     */
    public TodoTask? get_prev () {
        return task_manager.get_prev ();
    }

    /**
     * Called when the user has finished working on this task.
     */
    public void mark_done (TodoTask task) {
        task_manager.mark_done ((TxtTask) task);
    }

    /**
     * Tasks that the user should currently work on
     */
    public unowned Gtk.Widget get_primary_page (out string? page_name) {
        page_name = null;
        return todo_list;
    }

    /**
     * Can be future recurring tasks or tasks that are already done
     */
    public unowned Gtk.Widget get_secondary_page (out string? page_name) {
        page_name = null;
        return done_list;
    }

    public unowned Gtk.Widget? get_menu () {
        return clear_done_button;
    }

    public void clear_done_list () {
        task_manager.clear_done_store ();
    }

    private void on_selection_changed (TxtTask? task) {
        selected_task = task;
    }

    private void on_active_task_invalid () {
        active_task = selected_task;
    }

    /**
     * Returns the schedule of task and break times specific to this list.
     */
    public Schedule? get_schedule () {
        return list_settings.schedule;
    }

    /**
     * Returns the duration (in seconds) of the break the user should take
     * before resuming work on the task.
     * If no value is configured -1 should be returned.
     */
    public int get_reminder_time () {
        return list_settings.reminder_time;
    }

    public void add_task_shortcut () {
        todo_list.entry_focus ();
    }

    /**
     * Called when this todo.txt list has been selected by the user.
     * This function should be used to initialize the widgets and other objects.
     */
    public void load () {
        task_manager = new TaskManager (list_settings);
        todo_list = new TaskListWidget (this.task_manager.todo_store, true);
        done_list = new TaskListWidget (this.task_manager.done_store, false);
        clear_done_button = new Gtk.ModelButton ();
        clear_done_button.text = _("Clear Done List");
        clear_done_button.clicked.connect (clear_done_list);
        clear_done_button.show_all ();

        /* Action and Signal Handling */
        todo_list.add_new_task.connect (task_manager.add_new_task);
        todo_list.selection_changed.connect (on_selection_changed);
        task_manager.active_task_invalid.connect (on_active_task_invalid);

        selected_task = todo_list.get_selected_task ();
        active_task = selected_task;
    }

    /**
     * This function is called when this list is no longer in use but may be
     * loaded again in the future.
     * Widgets and other objects should be freed to preserver resources.
     */
    public void unload () {
        task_manager.save_queued_lists ();
        todo_list = null;
        done_list = null;
        // stdout.printf ("task_manager %u!\n", task_manager.ref_count);
        task_manager = null;
        clear_done_button = null;
    }
}
