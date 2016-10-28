/* Copyright 2016 Go For It! developers
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

public abstract class GOFI.TaskListProvider : Peas.ExtensionBase, Peas.Activatable {
    
    internal GLib.List<TaskList> lists;
    
    /**
     * The plugin interface, an allias of object.
     */
    public Interface plugin_iface {
        public owned get {
            return (Interface) object;
        }
    }
    
    /**
     * The plugin interface.
     */
    public Object object { owned get; construct; }
    
    internal string plugin_name {
        public get {
            return plugin_info.get_name ();
        }
    }
    
    public string module_name {
        public get {
            return plugin_info.get_module_name ();
        }
    }
    
    /**
     * Signal that is emited when this gets unloaded.
     */
    internal signal void remove ();
    
    /**
     * Signal called whenever a TaskList is removed from this.
     */
    public signal void list_removed (TaskList list);
    
    /**
     * Signal called whenever a new TaskList is added to this.
     */
    public signal void list_added (TaskList list);
    
    /**
     * Implementation of Peas.Activatable.activate, this function should 
     * only be called by the main application.
     */
    public void Peas.Activatable.activate () {
        activate ();
        plugin_iface.register_list_provider (this);
    }
    
    /**
     * Implementation of Peas.Activatable.deactivate, this function should 
     * only be called by the main application.
     */
    public void Peas.Activatable.deactivate () {
        deactivate ();
        this.remove ();
    }
    
    /**
     * Implementation of Peas.Activatable.update_state, this function should 
     * only be called by the main application.
     */
    public void update_state () {

    }
    
    /**
     * Function called when a TodoPluginProvider gets deactivated.
     */
    public abstract new void deactivate ();
    
    /**
     * Function called when a TodoPluginProvider gets activated.
     */
    public abstract new void activate ();
    
    protected void add_list (TaskList list) {
        lists.append (list);
        list_added (list);
    }
    
    protected void remove_list (TaskList list) {
        lists.remove (list);
        list_removed (list);
    }
    
    /**
     * Returns the list corresponding to the id.
     * 
     */
    public TaskList? get_list (string id) {
        unowned List<TaskList>? element = lists.search<string> (
            id, (id, list) => GLib.strcmp (id, list.id)
        );
        if (element != null) {
            return element.data;
        }
        return null;
    }
    
    public GLib.List<unowned TaskList> get_lists () {
        return lists.copy ();
    }
}

public abstract class GOFI.TaskList : GLib.Object {
    
    /**
     * Id of the list, the id will often be the name of the list.
     * The id must be unique.
     */
    public string id {
        public get;
        protected set;
    }
    
    /**
     * Name of the list, the name should be both unique and human readable as 
     * the user distinguishes the lists based on this property. 
     */
    public string name {
        public get;
        protected set;
    }
    
    internal string plugin_name {
        public get {
            return plugin_info.get_name ();
        }
    }
    
    internal string module_name {
        public get {
            return plugin_info.get_module_name ();
        }
    }
    
    /**
     * PluginInfo from the plugin this list is from. 
     */
    public Peas.PluginInfo plugin_info {
        public get;
        construct set;
    }
    
    /**
     * The task that is currently selected in the primary widget.
     */
    public virtual TodoTask? selected_task {
        public get;
        protected set;
    }
    
    /**
     * The task the user is working on.
     * 
     * This property should only be changed by the TaskList if the task is no 
     * longer available.
     */
    public virtual TodoTask? active_task {
        public get;
        public set;
    }
    
    /**
     * Signal that is emited when there are no tasks left.
     */
    public signal void cleared ();
    
    /**
     * Signals that all holders of a reference to the list should release the 
     * reference that they hold. 
     */
    internal signal void remove ();
    
    /**
     * Constructor of TodoPlugin, should always be called by sub classes.
     */
    public TaskList (Peas.PluginInfo plugin_info, string name, string id) {
        this.plugin_info = plugin_info;
        this.name = name;
        this.id = id;
    }
    
    /**
     * This function is called when this list is chosen, this function should be
     * used to initialize all objects like widgets, tasks, etc...
     */
    public abstract void activate ();
    
    /**
     * A function called when this TodoPlugin is about to get removed from 
     * the application. Stops all activity and saves all tasks.
     */
    public abstract void deactivate ();
    
    /**
     * Called when the task has been marked as done in the timer. The task 
     * that is currently the active_task should be removed from the list and 
     * selected_task should be set to the next task in the list. selected_task 
     * should be set to null if active_task was the last task in the list.
     */
    public abstract void set_active_task_done ();
    
    /**
     * List of menu items to be added to the application menu.
     */
    public virtual GLib.List<unowned Gtk.MenuItem> get_menu_items () {
        return new GLib.List<unowned Gtk.MenuItem> ();
    }
    
    /**
     * Sets selected_task to the the task that follows after active_task in the 
     * list. If active_task is the last task the first task should be selected.
     */
    public abstract void select_next ();
    
    /**
     * Sets selected_task to the the task that comes before active_task in the 
     * list. If active_task is the first task the last task should be selected.
     */
    public abstract void select_previous ();
    
    /**
     * Primary widget showing all tasks that need to be done.
     * 
     * If this widget contains one or multiple selectable tasks, one task should
     * always be selected.
     * @param page_name name of the page
     */
    public abstract Gtk.Widget get_primary_widget (out string page_name);
    
    /**
     * Secondary widget that can be used for things like showing all tasks
     * that have been done.
     */
    public abstract Gtk.Widget get_secondary_widget (out string page_name);
}
