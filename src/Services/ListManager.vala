/* Copyright 2014-2018 Go For It! developers
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

using GOFI.TXT;

class GOFI.ListManager : Object, DragListModel {
    private SequentialList todolist_infos;
    private TxtListManager txt_manager;

    /* Signals */
    public signal void lists_changed ();
    public signal void list_removed (string provider, string id);

    /**
     * Constructor of the ListManager class
     */
    public ListManager () {
        string txt_config_file = GOFI.Utils.get_module_config_dir ("Todo.txt");

        if (settings.first_start) {
            txt_manager = new TxtListManager (txt_config_file);
        } else {
            txt_manager = new TxtListManager (null);
        }

        todolist_infos = new SequentialList (typeof (TodoListInfo));

        populate_items ();

        txt_manager.lists_added.connect (add_new_lists);
        txt_manager.lists_removed.connect (remove_lists);
    }

    private void add_new_lists (List<TodoListInfo> to_add) {
        uint n = 0;
        foreach (TodoListInfo info in to_add) {
            todolist_infos.prepend_item (info);
            n++;
        }
        items_changed (0, 0, n);
    }

    private void remove_lists (List<string> to_remove) {
        foreach (string id in to_remove) {
            uint index = todolist_infos.search_remove_item<string> (id, (
                (info_obj, search_id) => {
                    var info_id = ((TodoListInfo) info_obj).id;
                    return strcmp (info_id, search_id);
                })
            );
            items_changed (index, 1, 0);
            list_removed (GOFI.TXT.PROVIDER_NAME, id);
        }
    }

    public TxtListManager get_txt_manager () {
        return txt_manager;
    }

    private unowned List<TodoListInfo> search_list_link (
        List<TodoListInfo> lists, string id
    ) {
        return lists.search<string> (id, (info, _id) => {
            return strcmp (info.id, _id);
        });
    }

    public TxtList? get_list (string provider, string id) {
        if (provider != "Todo.txt") {
            return null;
        }
        return txt_manager.get_list (id);
    }

    public TodoListInfo? get_list_info (string provider, string id) {
        if (provider != "Todo.txt") {
            return null;
        }
        return txt_manager.get_list_info (id);
    }

    public TodoListInfo[] get_list_infos () {
        uint infos_length = todolist_infos.length;
        var infos = new TodoListInfo[infos_length];
        for (uint i = 0; i < infos_length; i++) {
            infos[i] = (TodoListInfo) todolist_infos.get_item (i);
        }
        return infos;
    }

    public void delete_list (TodoListInfo list_info, Gtk.Window? window) {
        txt_manager.delete_list (list_info.id, window);
    }

    public void edit_list (TodoListInfo list_info, Gtk.Window? window) {
        txt_manager.edit_list (list_info.id, window);
    }

    private void populate_items () {
        var txt_lists = txt_manager.get_list_infos ();
        var stored_lists = settings.lists;

        foreach (unowned ListIdentifier identifier in stored_lists) {
            unowned List<TodoListInfo> link = search_list_link (txt_lists, identifier.id);
            if (link != null) {
                todolist_infos.append_item (link.data);
                link.data.unref ();
                txt_lists.delete_link (link);
            } else {
                warning ("Couldn't find list '%s:%s'\n", identifier.provider, identifier.id);
            }
        }
        foreach (TodoListInfo info in txt_lists) {
            todolist_infos.append_item (info);
        }
        items_changed (0, 0, todolist_infos.length);
    }

    public void add_list_info (TodoListInfo list_info) {
        todolist_infos.append_item (list_info);
        items_changed (todolist_infos.length - 1, 0, 1);
    }

    public void remove_list_info (TodoListInfo list_info) {
        items_changed (todolist_infos.remove_item (list_info), 1, 0);
    }

    public Type get_item_type () {
        return todolist_infos.get_item_type ();
    }

    public Object? get_item (uint position) {
        return todolist_infos.get_item (position);
    }

    public uint get_n_items () {
        return todolist_infos.length;
    }

    public void move_item (uint old_position, uint new_position) {
        if (old_position == new_position) {
            return;
        }
        todolist_infos.move_item (old_position, new_position);
        on_list_change ();
    }

    public void on_list_change () {
        var set_lists = new List<ListIdentifier?> ();
        uint n_lists = todolist_infos.length;
        for (uint i = 0; i < n_lists; i++) {
            var info = (TodoListInfo) todolist_infos.get_item (i);
            set_lists.prepend (new ListIdentifier (info.provider_name, info.id));
        }
        settings.lists = set_lists;
        lists_changed ();
    }
}
