/* Copyright 2017 Go For It! developers
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
 * Data structure used to implement DragListModel.
 * It keeps track of the last accessed link to provide sequential access in O(1).
 * This class doesn't use generics as valac (0.36.7) generated invalid c code
 * for the code responsible for freeing the internal Queue.
 */
class GOFI.SequentialList {
    private Queue<Object> items;
    private unowned List<Object> iter_link;
    private int iter_link_index;
    private Type item_type;

    public uint length {
        get {
            return items.length;
        }
    }

    public SequentialList (Type item_type) {
        this.item_type = item_type;
        items = new Queue<Object> ();
        iter_link = null;
    }

    private void move_iter_link_to_index (int index) {
        unowned List<Object> closest_link;
        int distance;
        int distance_head = index;
        int distance_tail = index - (int)items.length + 1;
        int distance_iter;

        if (-distance_tail < distance_head) {
            closest_link = items.tail;
            distance = distance_tail;
        } else {
            closest_link = items.head;
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

    public void append_item (Object item) {
        iter_link = null;
        items.push_tail (item);
    }

    public void prepend_item (Object item) {
        iter_link = null;
        items.push_head (item);
    }

    public uint remove_item (Object item) {
        iter_link = null;
        uint i = 0;
        unowned List<Object> iter = items.head;
        while (iter != null && iter.data != item) {
            iter = iter.next;
            i++;
        }
        assert (iter != null);
        iter.data.unref ();
        items.delete_link (iter);
        return i;
    }

    public uint search_remove_item<T> (T data, GLib.SearchFunc<Object, T> func) {
        iter_link = null;
        uint i = 0;
        unowned List<Object> iter = items.head;
        while (iter != null && func(iter.data, data) != 0) {
            iter = iter.next;
            i++;
        }
        assert (iter != null);
        iter.data.unref ();
        items.delete_link (iter);
        return i;
    }

    public void move_item (uint old_position, uint new_position) {
        assert (((int)old_position) >= 0 && ((int)new_position) >= 0);
        iter_link = null;
        items.push_nth (items.pop_nth (old_position), (int) new_position);
    }

    public Object? get_item (uint position) {
        assert (((int)position) >= 0);
        if (position < items.length) {
            move_iter_link_to_index ((int)position);
            return iter_link.data;
        }
        return null;
    }

    public uint get_item_position (Object item) {
        int index = items.index(item);
        if (index >= 0) {
            return index;
        } else {
            error ("Item not found");
        }
    }

    public Type get_item_type () {
        return item_type;
    }

    public void clear () {
        iter_link = null;
        items.clear ();
    }
}
