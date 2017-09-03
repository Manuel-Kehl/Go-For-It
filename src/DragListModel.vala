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

public interface DragListModel : Object, GLib.ListModel {
    /**
     * Called when a row is moved in the widget.
     * It should only be used to synchronize the model with the widget.
     */
    public abstract void move_item (uint old_position, uint new_position);

    /**
     * Causes the row to be moved in the widget.
     */
    public signal void item_moved (uint old_position, uint new_position);
}

public delegate Gtk.Widget DragListCreateWidgetFunc (Object item);
