/* Copyright 2014-2016 Go For It! developers
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

class TaskStore : Object, DragListBoxModel {
    private Queue<TodoTask> tasks;
    private uint stamp;
    
    public bool done_by_default {
        public get;
        construct set;
    }
    
    /* Signals */
    public signal void task_data_changed ();
    public signal void task_done_changed (TodoTask task);
    
    /**
     * Constructor of the TaskStore class
     */
    public TaskStore (bool done_by_default) {
        this.done_by_default = done_by_default;
        tasks = new Queue<TodoTask> ();
        stamp = 0;
    }
    
    public Iterator<Object> iterator() {
        return new StoreIter (tasks.head, this);
    }
    
    public void add_new_task (TodoTask task) {
        add_task (task);
        task_data_changed ();
    }
    
    public void add_task (TodoTask task) {
        tasks.push_tail (task);
        task.status_changed.connect (on_task_done);
        items_added (tasks.length - 1, 1);
    }
    
    public void clear () {
        items_removed (0, tasks.length);
        tasks.clear ();
        task_data_changed ();
    }
    
    public void remove_task (TodoTask task) {
        stdout.printf ("remove\n");
        task.status_changed.disconnect (on_task_done);
        tasks.remove (task);
        task_data_changed ();
    }

    public Object? get_item (uint position) {
        return tasks.peek_nth (position);
    }

    public uint get_n_items () {
        return tasks.length;
    }
    
    public void move_item (uint old_position, uint new_position) {
        if (old_position == new_position) {
            return;
        } else if (new_position > old_position) {
            new_position++;
        }
        
        tasks.push_nth(tasks.pop_nth (old_position), (int) new_position);
    }
    
    public CompareDataFunc<DragListBoxRow>? get_sort_func () {
        return null;
    }
    
    private void on_task_done (TodoTask task) {
        task_done_changed (task);
    }
    
    class StoreIter : Object, Iterator<TodoTask> {
        private unowned List<TodoTask> link;
        private unowned TaskStore store;
        private uint stamp;
        private bool next_called;
        
        public bool valid {
            get {
                return link != null && stamp == store.stamp;
            }
        }
        
        public StoreIter (List<TodoTask> link, TaskStore store) {
            this.link = link;
            this.store = store;
            stamp = store.stamp;
            next_called = false;
        }
        
        public bool next () {
            if (GLib.unlikely (!next_called)) {
                next_called = true;
                return valid;
            } else if (has_next ()) {
                link = link.next;
                return true;
            }
            return false;
        }
        
        public bool has_next () {
            return valid && link.next != null;
        }
        
        public new TodoTask get () {
            assert (valid);
            return link.data;
        }
    }
}
