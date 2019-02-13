class TxtList : Object {
    private TaskManager task_manager;
    private TaskList todo_list;
    private TaskList done_list;

    public ListSettings list_settings {
        public get;
        private set;
    }

    public TodoTask? selected_task {
        public get;
        private set;
    }

    public TodoTask? active_task {
        public get;
        public set;
    }

    public TodoListInfo list_info {
        public get {
            return list_settings;
        }
    }

    public TxtList (ListSettings list_settings) {
        this.list_settings = list_settings;
    }

    public TodoTask? get_next () {
        return task_manager.get_next ();
    }

    public TodoTask? get_prev () {
        return task_manager.get_prev ();
    }

    public void mark_done (TodoTask task) {
        task_manager.mark_done (task);
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

    private void on_selection_changed (TodoTask? task) {
        selected_task = task;
    }

    private void on_active_task_invalid () {
        active_task = selected_task;
    }

    public void load () {
        task_manager = new TaskManager (list_settings);
        todo_list = new TaskList (this.task_manager.todo_store, true);
        done_list = new TaskList (this.task_manager.done_store, false);

        /* Action and Signal Handling */
        todo_list.add_new_task.connect (task_manager.add_new_task);
        todo_list.selection_changed.connect (on_selection_changed);
        task_manager.active_task_invalid.connect (on_active_task_invalid);

        selected_task = todo_list.get_selected_task ();
    }

    public void unload () {
        todo_list = null;
        done_list = null;
        task_manager = null;
    }
}
