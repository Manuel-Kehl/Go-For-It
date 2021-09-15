/* Copyright 2017 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * GLib.ListModel extended with support for moving items from a widget or other
 * object.
 * See documentation of GLib.ListModel for more detailed information.
 * Because versions of GLib older than 2.44 are supported right now,
 * GLib.ListModel can't be inherited from.
 */
public interface GOFI.DragListModel : Object {
    /**
     * Called when a row is moved in the widget.
     * It should only be used to synchronize the model with the widget.
     */
    public abstract void move_item (uint old_position, uint new_position);

    /**
     * This signal is emitted whenever an item is moved when this wasn't caused
     * by move_item.
     */
    public signal void item_moved (uint old_position, uint new_position);

    /**
     * Get the item at position.
     */
    public abstract Object? get_item (uint position);
    /**
     * Gets the type of the items in this.
     */
    public abstract Type get_item_type ();
    /**
     * Gets the number of items in this.
     */
    public abstract uint get_n_items ();
    /**
     * This signal is emitted whenever items were added or removed to list.
     */
    public signal void items_changed (uint position, uint removed, uint added);
}
