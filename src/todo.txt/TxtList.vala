class TxtList {
    private TaskManager task_manager;
    private TaskList todo_list;
    private TaskList done_list;

    private string path;

    public string list_name {
        public get;
        public set;
    }

    public string id {
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

    public TxtList (string id, string path, string list_name) {
        this.id = id;
        this.path = path;
        this.list_name = list_name;
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
    public unowned Gtk.Widget get_primary_page () {
        return todo_list;
    }

    /**
     * Can be future recurring tasks or tasks that are already done
     */
    public unowned Gtk.Widget get_secondary_page () {
        return done_list;
    }

    public void load () {
        task_manager = new TaskManager
        todo_list = new TaskList (this.task_manager.todo_store, true);
        done_list = new TaskList (this.task_manager.done_store, false);

        /* Action and Signal Handling */
        todo_list.add_new_task.connect (task_manager.add_new_task);
        todo_list.selection_changed.connect (on_selection_changed);
        task_manager.active_task_invalid.connect (on_active_task_invalid);
    }

    public void unload () {
        todo_list = null;
        done_list = null;
        task_manager = null;
    }
}
