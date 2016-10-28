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

class GOFI.ListChooser : Gtk.ScrolledWindow {
    
    private Gtk.ListBox layout;
    private Gtk.Label place_holder;
    private PluginManager plugin_manager;
    
    public signal void list_selected (TaskList list);
    
    public ListChooser (PluginManager plugin_manager) {
        this.plugin_manager = plugin_manager;
        setup_layout ();
        update ();
        plugin_manager.task_lists_added.connect ( (lists) => {
            foreach (TaskList list in lists) {
                add_list (list);
            }
        });
        layout.row_activated.connect (on_row_activated);
    }
    
    private void setup_layout () {
        layout = new Gtk.ListBox ();
        layout.set_sort_func(sort_func);
        layout.expand = true;
        
        place_holder = new Gtk.Label ("No plugins are currently loaded");
        // else it won't be shown, even if this.show_all () is called.
        place_holder.show ();
        
        layout.set_placeholder (place_holder);
        
        this.add (layout);
    }
    
    public void update () {
        reset ();
        var lists = plugin_manager.get_lists ();
        foreach (TaskList list in lists) {
            add_list (list);
        }
    }
    
    public void add_list (TaskList list) {
        var new_row = new ListChooserRow (list);
        layout.add(new_row);
        
        list.remove.connect ( () => {
            new_row.destroy ();
        });
    }
    
    /**
     * Removes all plugins.
     */
    public void reset () {
        var rows = layout.get_children();
        foreach (Gtk.Widget row in rows) {
            row.destroy ();
        }
    }
    
    private void on_row_activated (Gtk.ListBoxRow row) {
        list_selected (((ListChooserRow)row).list);
    }
    
    private int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var _row1 = (ListChooserRow) row1;
        var _row2 = (ListChooserRow) row2;
        
        return _row1.compare (_row2);
    }
}

class GOFI.ListChooserRow : Gtk.ListBoxRow {
    
    private Gtk.Grid layout;
    private Gtk.Box label_layout;
    private Gtk.Label title_label;
    private Gtk.Label plugin_label;
    
    public TaskList list {
        public get;
        private set;
    }
    
    public ListChooserRow (TaskList list) {
        this.list = list;
        setup_layout ();
        
        this.list.notify["name"].connect ( () => {
            title_label.label = this.list.name;
        });
        
        this.activatable = true;
        this.show_all ();
    }
    
    /**
     * Initializes GUI elements.
     */
    private void setup_layout () {
        layout = new Gtk.Grid ();
        label_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        title_label = new Gtk.Label(list.name);
        plugin_label = new Gtk.Label(list.plugin_name);
        
        title_label.hexpand = true;
        
        label_layout.pack_start (title_label);
        label_layout.pack_end (plugin_label);
        
        layout.add (label_layout);
        
        this.add (layout);
    }
    
    public int compare (ListChooserRow other_row) {
        if (other_row.list.plugin_name < list.plugin_name) {
            return 1;
        } else if (other_row.list.plugin_name > list.plugin_name) {
            return -1;
        } else {
            if (other_row.list.name < list.name) {
                return 1;
            } else if (other_row.list.name > list.name) {
                return -1;
            } else {
                return 0;
            }
        }
    }
}
