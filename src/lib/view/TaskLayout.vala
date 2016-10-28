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

class GOFI.TaskLayout : Gtk.Grid {
    /* Various Variables */
    private SettingsManager settings;
    private bool use_header_bar;
    
    private TaskList task_list = null;
    private TaskTimer task_timer;
    
    /* Various GTK Widgets */
    private Gtk.Stack activity_stack;
    private Gtk.StackSwitcher activity_switcher;
    
    private Gtk.Widget first_page;
    private TimerView timer_view;
    private Gtk.Widget last_page;
    
    private GLib.List<unowned Gtk.MenuItem> menu_items;
    
    public bool list_valid {
        public get;
        private set;
        default = false;
    }
    
    public signal void removing_list ();
    
    /**
     * The constructor of the MainWindow class.
     */
    public TaskLayout (SettingsManager settings, TaskTimer task_timer, 
                       bool use_header_bar)
    {
        this.task_timer = task_timer;
        this.settings = settings;
        this.use_header_bar = use_header_bar;
        
        this.orientation = Gtk.Orientation.VERTICAL;
        initial_setup ();
        task_timer.active_task_done.connect (on_task_done);
    }
    
    /**
     * Initializes everything that doesn't depend on a TodoTask.
     */
    private void initial_setup () {
        /* Instantiation of available widgets */
        activity_stack = new Gtk.Stack ();
        activity_switcher = new Gtk.StackSwitcher ();
        timer_view = new TimerView (task_timer);
        
        // Activity Stack + Switcher
        activity_switcher.set_stack (activity_stack);
        activity_switcher.halign = Gtk.Align.CENTER;
        activity_stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        );
        activity_switcher.margin = 5;
        
        if (use_header_bar) {
            this.add (activity_switcher);
        }
        
        menu_items = new GLib.List<Gtk.MenuItem> ();
        
        this.add (activity_stack);
    }
    
    /**
     * Adds the widgets from task_list as well as timer_view to the stack.
     */
    private void add_widgets () {
        string first_page_name;
        string second_page_name;
        
        /* Instantiation of the Widgets */
        first_page = task_list.get_primary_widget (out first_page_name);
        last_page = task_list.get_secondary_widget (out second_page_name);
        
        // Add widgets to the activity stack
        activity_stack.add_titled (first_page, "primary", first_page_name);
        activity_stack.add_titled (timer_view, "timer", _("Timer"));
        activity_stack.add_titled (last_page, "secondary", second_page_name);
        
        if (task_timer.running) {
            // Otherwise no task will be displayed in the timer view
            task_timer.update_active_task ();
            // Otherwise it won't switch
            timer_view.show ();
            activity_stack.set_visible_child (timer_view);
        }
        else {
            first_page.show ();
            activity_stack.set_visible_child (first_page);
        }
        activity_switcher.margin = 5;
    }
    
    /**
     * Updates this to display the new TaskList.
     */
    public void set_task_list (TaskList task_list) {
        if (this.task_list == null) {
            this.task_list = task_list;
            this.task_list.activate ();
            task_list.cleared.connect (timer_view.show_no_task);
            add_widgets ();
            this.show_all ();
            
            task_list.notify["active-task"].connect(on_active_task_changed);
            task_list.notify["selected-task"].connect(on_selected_task_changed);
            get_next_task ();
            
            menu_items = task_list.get_menu_items ();
            list_valid = true;
        } else {
            warning ("Previous list was not removed!");
        }
    }
    
    private void on_task_done () {
        task_list.set_active_task_done ();
        get_next_task ();
    }
    
    private void get_next_task () {
        TodoTask? task = task_list.selected_task;
        
        task_timer.active_task = task;
        task_list.active_task = task;
    }
    
    private void on_active_task_changed () {
        task_timer.active_task = task_list.active_task;
    }
    
    private void on_selected_task_changed () {
        // Don't change task, while timer is running
        if (!task_timer.running) {
            task_timer.active_task = task_list.selected_task;
            task_list.active_task = task_list.selected_task;
        }
    }
    
    /**
     * Restores this to its state from before set_task_list was called.
     */
    public void remove_task_list () {
        list_valid = false;
        if (task_list != null) {
            task_list.deactivate ();
            task_list.cleared.disconnect (timer_view.show_no_task);
            task_list.notify["active-task"].disconnect(on_active_task_changed);
            task_list.notify["selected-task"].disconnect(on_selected_task_changed);
        }
        foreach (Gtk.Widget widget in activity_stack.get_children()) {
            activity_stack.remove (widget);
        }
        foreach (Gtk.MenuItem item in menu_items) {
            item.destroy ();
        }
        
        first_page = null;
        last_page = null;
        
        task_timer.reset ();
        timer_view.show_no_task ();
        
        task_list = null;
    }
    
    /**
     * Returns a switcher widget to control activity_stack.
     */
    public Gtk.Widget get_switcher () {
        return activity_switcher;
    }
    
    public unowned GLib.List<unowned Gtk.MenuItem> get_menu_items () {
        assert (list_valid);
        return menu_items;
    }
    
    /**
     * Returns true if this widget has been properly initialized.
     */
    public bool ready {
        get {
            return (task_list != null);
        }
    }
}
