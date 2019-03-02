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

using GOFI;

class GOFI.TXT.TaskStore : Object, DragListModel {
    private SequentialList tasks;

    public bool done_by_default {
        public get;
        private set;
    }

    /* Signals */
    // Emitted when the properties of a task (including position), excluding done, have changed
    public signal void task_data_changed ();
    public signal void task_done_changed (TodoTask task);
    public signal void task_became_invalid (TodoTask task);

    /**
     * Constructor of the TaskStore class
     */
    public TaskStore (bool done_by_default) {
        this.done_by_default = done_by_default;
        tasks = new SequentialList (typeof (TodoTask));
    }

    public void add_task (TodoTask task) {
        tasks.append_item (task);
        task.done_changed.connect (on_task_done);
        task.data_changed.connect (on_task_data_changed);
        items_changed (tasks.length - 1, 0, 1);
        task_data_changed ();
    }

    public void clear () {
        uint length = tasks.length;
        tasks.clear ();
        items_changed (0, length, 0);
        task_data_changed ();
    }

    public void remove_task (TodoTask task) {
        task.done_changed.disconnect (on_task_done);
        task.data_changed.disconnect (on_task_data_changed);
        items_changed (tasks.remove_item (task), 1, 0);
        task_data_changed ();
    }

    public Type get_item_type () {
        return tasks.get_item_type ();
    }

    public Object? get_item (uint position) {
        return tasks.get_item (position);
    }

    public uint get_task_position (TodoTask task) {
        return tasks.get_item_position (task);
    }

    public uint get_n_items () {
        return tasks.length;
    }

    public void move_item (uint old_position, uint new_position) {
        if (old_position == new_position) {
            return;
        }
        tasks.move_item (old_position, new_position);
        task_data_changed ();
    }

    private void on_task_done (TodoTask task) {
        task_done_changed (task);
    }

    private void on_task_data_changed (TodoTask task) {
        if (task.valid) {
            task_data_changed ();
        } else {
            task_became_invalid (task);
        }
    }
}
