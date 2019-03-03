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
class GOFI.TXT.TxtList : Object {
    private TaskManager task_manager;
    private TaskList todo_list;
    private TaskList done_list;

    private Gtk.ModelButton clear_done_button;

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

    public unowned Gtk.Widget? get_menu () {
        return clear_done_button;
    }

    public void clear_done_list () {
        task_manager.clear_done_store ();
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
        clear_done_button = new Gtk.ModelButton ();
        clear_done_button.text = _("Clear Done List");
        clear_done_button.clicked.connect (clear_done_list);
        clear_done_button.show_all ();

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
        clear_done_button = null;
    }
}
