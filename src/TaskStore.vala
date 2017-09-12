/* Copyright 2014-2017 Go For It! developers
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

class TaskStore : Object, DragListModel {
    private Queue<TodoTask> tasks;
    private unowned List<TodoTask> iter_link;
    private unowned int iter_link_index;

    public bool done_by_default {
        public get;
        private set;
    }

    /* Signals */
    // Emitted when the properties of a task, excluding done, have changed
    public signal void task_data_changed ();
    public signal void task_done_changed (TodoTask task);

    /**
     * Constructor of the TaskStore class
     */
    public TaskStore (bool done_by_default) {
        this.done_by_default = done_by_default;
        tasks = new Queue<TodoTask> ();
    }

    private void move_iter_link_to_index (int index) {
        unowned List<TodoTask> closest_link;
        int distance;
        int distance_head = index;
        int distance_tail = (int)tasks.length - 1;
        int distance_iter;

        if (distance_tail < distance_head) {
            closest_link = tasks.tail;
            distance = -distance_tail;
        } else {
            closest_link = tasks.head;
            distance = distance_head;
        }
        if (iter_link != null) {
            distance_iter = index - iter_link_index;
            if (distance.abs () > distance_iter.abs ()) {
                distance = distance_iter;
                closest_link = iter_link;
            }
        }

        if (distance > 0) {
            iter_link = closest_link.nth (distance);
        } else {
            iter_link = closest_link.nth_prev (distance.abs ());
        }
        iter_link_index = index;
    }

    public void add_task (TodoTask task) {
        iter_link = null;
        tasks.push_tail (task);
        task.done_changed.connect (on_task_done);
        task.data_changed.connect (on_task_data_changed);
        items_changed (tasks.length - 1, 0, 1);
    }

    public void clear () {
        iter_link = null;
        items_changed (0, tasks.length, 0);
        tasks.clear ();
    }

    public void remove_task (TodoTask task) {
        iter_link = null;
        uint i = 0;
        unowned List<TodoTask> iter = tasks.head;
        while (iter != null && iter.data != task) {
            iter = iter.next;
            i++;
        }
        assert (iter != null);
        task.done_changed.disconnect (on_task_done);
        task.data_changed.disconnect (on_task_data_changed);
        tasks.delete_link (iter);
        items_changed (i, 1, 0);
    }

    public Type get_item_type () {
        return typeof (TodoTask);
    }

    public Object? get_item (uint position) {
        assert (((int)position) >= 0);
        if (position < tasks.length) {
            move_iter_link_to_index ((int)position);
            return iter_link.data;
        }
        return null;
    }

    public uint get_n_items () {
        return tasks.length;
    }

    public void move_item (uint old_position, uint new_position) {
        assert (((int)old_position) >= 0 && ((int)new_position) >= 0);
        if (old_position == new_position) {
            return;
        }
        iter_link = null;
        tasks.push_nth(tasks.pop_nth (old_position), (int) new_position);
        task_data_changed ();
    }

    private void on_task_done (TodoTask task) {
        task_done_changed (task);
    }

    private void on_task_data_changed () {
        task_data_changed ();
    }
}
