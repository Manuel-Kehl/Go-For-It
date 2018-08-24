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
     * A list of available plugins the user can choose from.
     */
    public class ListSelector : Gtk.ScrolledWindow {
        
        private Gtk.ListBox layout;
        private Gtk.Label place_holder;
        private ListManager list_manager;
        
        public signal void list_selected (TaskList list);
        
        public ListSelector (ListManager list_manager) {
            this.list_manager = list_manager;
            setup_layout ();
            update ();
            list_manager.task_lists_added.connect ( (lists) => {
                foreach (TaskList list in lists) {
                    add_list (list);
                }
            });
            layout.row_activated.connect (on_row_activated);
        }
        
        private void setup_layout () {
            layout = new Gtk.ListBox ();
            layout.expand = true;
            
            place_holder = new Gtk.Label ("No plugins are currently loaded");
            // else it won't be shown, even if this.show_all () is called.
            place_holder.show ();
            
            layout.set_placeholder (place_holder);
            
            this.add (layout);
        }
        
        public void update () {
            reset ();
            var lists = list_manager.get_lists ();
            foreach (TaskList list in lists) {
                add_list (list);
            }
        }
        
        public void add_list (TaskList list) {
            var new_row = new ListSelectorRow (list);
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
            list_selected (((ListSelectorRow)row).list);
        }
    }
    
    /**
     * A row in PluginSelector, used to select a TodoPlugin to load, also stores
     * a TodoPluginProvider for the timebeing.
     */
    class ListSelectorRow : Gtk.ListBoxRow {
        private Gtk.Box layout;
        private Gtk.Label label;
        
        public TaskList list {
            public get;
            private set;
        }

        public ListSelectorRow (TaskList list) {
            this.list = list;
            setup_layout ();
            
            this.list.notify["name"].connect ( () => {
                label.label = this.list.name;
            });
            
            this.activatable = true;
            this.show_all ();
        }
        
        /**
         * Initializes GUI elements.
         */
        private void setup_layout () {
            layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            label = new Gtk.Label(list.name);
            layout.pack_start (label);
            this.add (layout);
        }
    }
}
