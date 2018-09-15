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

class ListManager : Object, DragListModel {
    private SettingsManager settings;
    private SequentialList todolist_infos;
    private TxtListManager txt_manager;

    /* Signals */
    public signal void lists_changed ();

    /**
     * Constructor of the ListManager class
     */
    public ListManager (SettingsManager settings) {
        this.settings = settings;

        string txt_config_file = Path.build_filename (
            GOFI.Utils.get_module_config_dir ("Todo.txt"), "list"
        );

        txt_manager = new TxtListManager (txt_config_file);
        todolist_infos = new SequentialList (typeof (TodoListInfo));

        populate_items ();
    }

    private unowned List<TodoListInfo> search_list_link (
                                            List<TodoListInfo> lists, string id)
    {
        return lists.search<string> (id, (info, _id) => {
            return strcmp (info.id, _id);
        });
    }

    private void populate_items () {
        List<TodoListInfo> txt_lists = txt_manager.get_list_infos ();
        var stored_lists = settings.lists;

        foreach (ListIdentifier identifier in stored_lists) {
            var link = search_list_link (txt_lists, identifier.id);
            if (link != null) {
                todolist_infos.append_item (link.data);
                txt_lists.delete_link (link);
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
        uint n_lists = todolist_infos.length;
        var set_lists = new ListIdentifier[n_lists];
        for (uint i = 0; i < n_lists; i++) {
            var info = (TodoListInfo) todolist_infos.get_item (i);
            set_lists[i] = {info.plugin_name, info.id};
        }
        settings.lists = set_lists;
        lists_changed ();
    }
}
