/* Copyright 2018 Go For It! developers
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

class TodoListInfoRow: DragListRow {
    private Gtk.Label name_label;

    public TodoListInfo info {
        get;
        private set;
    }

    public TodoListInfoRow (TodoListInfo info) {
        this.info = info;

        name_label = new Gtk.Label (info.name);
        name_label.hexpand = true;
        set_center_widget (name_label);

        connect_signals ();
        show_all ();
    }

    private void connect_signals () {
        info.notify["name"].connect (update);
    }

    private void update () {
        name_label.label = info.name;
    }
}
