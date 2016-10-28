using GOFI;

/**
 * 
 * Refreshing: when the todo.txt gets refreshed the TaskStore in todo_list will 
 * attempt to fix the currently active task. If this isn't possible because the 
 * task has been renamed or removed from the todo.txt file this TaskStore will 
 * call refresh_active_task, which results in task_manager calling 
 * active_task_invalid. Here on_active_task_invalid is called which causes the
 * first task to be selected and made active.
 * 
 */
private class GOFI.Plugins.TodoTXT.TXTList : GOFI.TaskList {
    
    private TaskManager task_manager;
    private SettingsManager settings;
    
    /* Widgets */
    private TaskList todo_list;
    private TaskList done_list;
    
    // Menu items for this plugin
    private Gtk.MenuItem clear_done_item;
    private GLib.List<Gtk.MenuItem> menu_items;
    
    private Gtk.TreeSelection todo_selection;
    
    private bool refreshing;
    
    public override TodoTask? active_task {
        public get {
            return _active_task;
        }
        public set {
            _active_task = (TXTTask) value;
            task_manager.set_active_task (_active_task);
        }
    }
    private TXTTask _active_task;
    
    public TXTList (Peas.PluginInfo plugin_info, SettingsManager settings) {
        base (plugin_info, "todo.txt", "todo.txt");
        
        this.settings = settings;
    }
    
    public override void activate () {
        task_manager = new TaskManager (settings);
        
        setup_widgets ();
        setup_menu ();
        connect_signals ();
    }
    
    public override void deactivate () {
        active_task = null;
        selected_task = null;
        clear_done_item = null;
        todo_selection = null;
        todo_list = null;
        done_list = null;
        task_manager = null;
    }
    
    public override void set_active_task_done () {
        task_manager.mark_task_done (_active_task.reference);
    }
    
    public override void select_next () {
        if (active_task == null) {
            return;
        }
        
        Gtk.TreeRowReference reference = _active_task.reference;
        unowned Gtk.TreeModel model = reference.get_model ();
        Gtk.TreeIter iter;
        
        if (model.get_iter (out iter, reference.get_path ())) {
            if (model.iter_next (ref iter)) {
                todo_selection.select_iter (iter);
            } else {
                select_first ();
            }
        }
    }
    
    public override void select_previous () {
        if (active_task == null) {
            return;
        }
        
        Gtk.TreeRowReference reference = _active_task.reference;
        unowned Gtk.TreeModel model = reference.get_model ();
        Gtk.TreeIter iter;
        
        if (model.get_iter (out iter, reference.get_path ())) {
            if (model.iter_previous (ref iter)) {
                todo_selection.select_iter (iter);
            } else {
                select_last ();
            }
        }
    }
    
    public override Gtk.Widget get_primary_widget (out string page_name) {
        page_name = _("To-Do");
        return todo_list;
    }
    
    public override Gtk.Widget get_secondary_widget (out string page_name) {
        page_name = _("Done");
        return done_list;
    }
    
    /**
     * List of menu items to be added to the application menu.
     */
    public override GLib.List<unowned Gtk.MenuItem> get_menu_items () {
        return menu_items.copy ();
    }
    
    private void setup_widgets () {
        /* Instantiation of the Widgets */
        todo_list = new TaskList (this.task_manager.todo_store, true);
        done_list = new TaskList (this.task_manager.done_store, false);
        todo_selection = todo_list.task_view.get_selection ();
        
        /* 
         * If either the selection or the data itself changes, it is 
         * necessary to check if a different task is to be displayed
         * in the timer widget and thus on_selection_changed is to be called
         */
        todo_selection.changed.connect (on_selection_changed);
        task_manager.done_store.task_data_changed.connect (on_selection_changed);
        task_manager.active_task_invalid.connect (on_active_task_invalid);
        task_manager.refreshing.connect (on_refreshing);
        task_manager.refreshed.connect (on_refreshed);

        // Call once to refresh view on startup
        on_active_task_invalid ();
    }
    
    private void setup_menu () {
        /* Initialization */
        menu_items = new GLib.List<Gtk.MenuItem> ();
        clear_done_item = new Gtk.MenuItem.with_label (_("Clear Done List"));
        
        /* Add Items to Menu */
        menu_items.append (clear_done_item);
    }
    
    private void on_refreshing () {
        refreshing = true;
    }
    
    private void on_refreshed () {
        refreshing = false;
        
        if (active_task != null && active_task != selected_task) {
            todo_selection.select_path (_active_task.reference.get_path ());
        }
    }
    
    private void on_active_task_invalid () {
        select_first ();
        active_task = selected_task;
    }
    
    private void on_selection_changed () {
        unowned Gtk.TreeModel model;
        Gtk.TreeIter iter;
        Gtk.TreeRowReference reference;
        
        if (todo_selection.get_selected (out model, out iter)) {
            if (Utils.iter_to_reference (model, iter, out reference)) {
                selected_task = new TXTTask (reference);
            }
        } else {
            selected_task = null;
        }
    }
    
    private void select_first () {
        unowned Gtk.TreeModel model = todo_list.task_view.get_model();
        Gtk.TreeIter iter;
        
        if (model.get_iter_first (out iter)) {
            todo_selection.select_iter (iter);
        } else {
            selected_task = null; // List is empty
        }
    }
    
    private void select_last () {
        unowned Gtk.TreeModel model = todo_list.task_view.get_model();
        Gtk.TreeIter iter, prev;
        
        if (model.get_iter_first (out iter)) {
            do {
                prev = iter;
            } while (model.iter_next (ref iter));
            todo_selection.select_iter (iter);
        } else {
            selected_task = null; // List is empty
        }
    }
    
    private void connect_signals () {
        todo_list.add_new_task.connect ( (task) => {
           task_manager.add_new_task (task); 
        });
        clear_done_item.activate.connect ((e) => {
            task_manager.clear_done_store ();
        });
    }
}
