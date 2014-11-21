/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Just Do It!.
*
* Just Do It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Just Do It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Just Do It!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * The main window of Just Do It!.
 */
class MainWindow : Gtk.ApplicationWindow {
    /* Various Variables */
    private TaskManager task_manager;
    private TaskTimer task_timer;
    
    /* Various GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Stack activity_stack;
    private Gtk.StackSwitcher activity_switcher;
    private Gtk.HeaderBar header_bar;
    private TaskList todo_list;
    private TaskList done_list;
    private TimerView timer_view;
    
    /**
     * The constructor of the MainWindow class.
     */
    public MainWindow (Gtk.Application app_context, TaskManager task_manager,
            TaskTimer task_timer) {
        // Pass the applicaiton context via GObject-based construction, because
        // constructor chaining is not possible for Gtk.ApplicationWindow
        Object (application: app_context);
        this.task_manager = task_manager;
        this.task_timer = task_timer;
        
        setup_window ();
        setup_widgets ();
        load_css ();
        
        this.show_all ();
        
        setup_notifications ();
    }
    
    /**
     * Configures the window's properties.
     */
    private void setup_window () {
        this.title = JDI.APP_NAME;
        this.set_border_width (0);
        this.set_position (Gtk.WindowPosition.CENTER);
        this.set_default_size (JDI.DEFAULT_WIN_WIDTH, JDI.DEFAULT_WIN_HEIGHT);
        this.destroy.connect (Gtk.main_quit);
    }
    
    /** 
     * Initializes GUI elements and configures their look and behavior.
     */
    private void setup_widgets () {
        /* Instantiation of the Widgets */
        main_layout = new Gtk.Grid ();
        header_bar = new Gtk.HeaderBar ();
        activity_stack = new Gtk.Stack ();
        activity_switcher = new Gtk.StackSwitcher ();
        todo_list = new TaskList (this.task_manager.todo_store, true);
        done_list = new TaskList (this.task_manager.done_store, false);
        timer_view = new TimerView (task_timer);
        
        /* Widget Settings */
        // Main Layout
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        main_layout.add (activity_stack);
        
        // Activity Stack + Switcher
        activity_switcher.set_stack (activity_stack);
        activity_stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        // Add widgets to the activity stack
        activity_stack.add_titled (todo_list, "todo", "To-Do");
        activity_stack.add_titled (timer_view, "doit", "Just Do It!");
        activity_stack.add_titled (done_list, "done", "Done");
            
        // GTK Header Bar
        header_bar.set_show_close_button (true);
        header_bar.custom_title = activity_switcher;
        this.set_titlebar (header_bar);
        
        /* Action and Signal Handling */
        todo_list.add_new_task.connect (task_manager.add_new_task);
        var todo_selection = todo_list.task_view.get_selection ();
        // Change active task upon selection change
        todo_selection.changed.connect ( (source) => {
            if (todo_selection.count_selected_rows () > 0) {
                Gtk.TreeModel model;
                Gtk.TreeIter iter;
                // Get first selected row
                var path = todo_selection.
                    get_selected_rows (out model).nth_data (0);
                model.get_iter (out iter, path);
                var reference = new Gtk.TreeRowReference (model, path);
                task_timer.active_task = reference;
            }
        });
        
        // Add main_layout to the window
        this.add (main_layout);
    }
    
    private void setup_notifications () {
        task_timer.active_task_changed.
                connect ((s, reference, break_active) => {
            var task = JDI.Utils.tree_row_ref_to_task (reference);
            Notification notification;
            if (break_active) {
                notification = new Notification ("Take a Break");
                notification.set_body ("Relax and stop thinking about your "
                    + "current task for a while :-)");
            } else {
                notification = new Notification ("The Break is over");
                notification.set_body ("Start working on: " + task);
            }
            application.send_notification (null, notification);
        });
    }
    
    /**
     * Searches the system for a css stylesheet, that corresponds to just-do-it.
     * If it has been found in one of the potential data directories, it gets
     * applied to the application.
     */
    private void load_css () {
        var screen = this.get_screen();
        var css_provider = new Gtk.CssProvider();
        // Scan all potential data dirs for the corresponding css file
        foreach (var dir in Environment.get_system_data_dirs ()) {
            // The path where the file is to be located
            var path = Path.build_filename (dir, JDI.APP_SYSTEM_NAME, 
                "style", "just-do-it.css");
            // Only proceed, if file has been found
            if (FileUtils.test (path, FileTest.EXISTS)) {
                try {
                    css_provider.load_from_path(path);
                    Gtk.StyleContext.add_provider_for_screen(screen,css_provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_USER);
                } catch (Error e) {
                    error ("Cannot load CSS stylesheet: %s", e.message);
                }
            }
        }
    }
}
