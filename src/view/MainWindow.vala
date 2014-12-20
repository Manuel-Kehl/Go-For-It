/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
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
 * The main window of Go For It!.
 */
class MainWindow : Gtk.ApplicationWindow {
    /* Various Variables */
    private TaskManager task_manager;
    private TaskTimer task_timer;
    private SettingsManager settings;
    
    /* Various GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Stack activity_stack;
    private Gtk.StackSwitcher activity_switcher;
    private Gtk.HeaderBar header_bar;
    private TaskList todo_list;
    private TaskList done_list;
    private TimerView timer_view;
    private Gtk.Toolbar toolbar;
    private Gtk.ToggleToolButton menu_btn;
    // Application Menu
    private Gtk.Menu app_menu;
    private Gtk.MenuItem config_item;
    private Gtk.MenuItem about_item;
    /**
     * Used to determine if a notification should be sent.
     */
    private bool break_previously_active { get; set; default = false; }
    
    /**
     * The constructor of the MainWindow class.
     */
    public MainWindow (Gtk.Application app_context, TaskManager task_manager,
            TaskTimer task_timer, SettingsManager settings) {
        // Pass the applicaiton context via GObject-based construction, because
        // constructor chaining is not possible for Gtk.ApplicationWindow
        Object (application: app_context);
        this.task_manager = task_manager;
        this.task_timer = task_timer;
        this.settings = settings;
        
        setup_window ();
        setup_menu ();
        setup_widgets ();
        load_css ();
        
        this.show_all ();
        
        setup_notifications ();
    }
    
    /**
     * Configures the window's properties.
     */
    private void setup_window () {
        this.title = GOFI.APP_NAME;
        this.set_border_width (0);
        this.set_position (Gtk.WindowPosition.CENTER);
        this.set_default_size (GOFI.DEFAULT_WIN_WIDTH, GOFI.DEFAULT_WIN_HEIGHT);
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
        toolbar = new Gtk.Toolbar ();
        // ToolButons and their corresponding images
        var menu_img = new Gtk.Image.from_icon_name ("open-menu",
            Gtk.IconSize.LARGE_TOOLBAR);
        menu_btn = new Gtk.ToggleToolButton ();
        
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
        activity_stack.add_titled (timer_view, "doit", GOFI.APP_NAME);
        activity_stack.add_titled (done_list, "done", "Done");
            
        // GTK Header Bar
        header_bar.set_show_close_button (true);
        header_bar.custom_title = activity_switcher;
        this.set_titlebar (header_bar);
        
        // Toolbar Items
        var space = new Gtk.SeparatorToolItem ();
        space.draw = false;
        menu_btn.label_widget = menu_img;
        // Add Toolbar Buttons here
        toolbar.add (space);
        toolbar.add (menu_btn);
        
        // Toolbar
        toolbar.orientation = Gtk.Orientation.HORIZONTAL;
        main_layout.add (toolbar);
        toolbar.child_set(space, expand:true);
        
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
        
        menu_btn.toggled.connect ((s) => {
            if (s.active) {
                app_menu.popup (null, null, calc_menu_position, 0,
                    Gtk.get_current_event_time ());
                app_menu.select_first (true);
            } else {
                app_menu.popdown ();
            }
        });
        
        // Add main_layout to the window
        this.add (main_layout);
    }
    
    private void calc_menu_position (Gtk.Menu menu, out int x, out int y) {
        /* Get relevant position values */
        int win_x, win_y;
        this.get_position (out win_x, out win_y);
        Gtk.Allocation btn_alloc, menu_alloc;
        menu_btn.get_allocation (out btn_alloc);
        app_menu.get_allocation (out menu_alloc);
        
        /*
         * The menu located below the app menu button.
         * Its right border is algined to the right side of the menu button,
         * because the button is the rightmost element of the toolbar.
         * This way the menu never overlaps the right side of the app's window.
         */
        x = win_x + btn_alloc.x - menu_alloc.width + btn_alloc.width;
        y = win_y + btn_alloc.y + btn_alloc.height;
    }
    
    private void setup_menu () {
        /* Initialization */
        app_menu = new Gtk.Menu ();
        config_item = new Gtk.MenuItem.with_label ("Configuration");
        about_item = new Gtk.MenuItem.with_label ("About");
        
        /* Signal and Action Handling */
        // Untoggle menu button, when menu is hidden
        app_menu.hide.connect ((e) => {
            menu_btn.active = false;
        });
        config_item.activate.connect ((e) => {
            var dialog = new SettingsDialog (false, settings);
            dialog.show ();
        });
        
        /* Add Items to Menu */
        app_menu.add (config_item);
        app_menu.add (about_item);
        
        /* And make all children visible */
        foreach (var child in app_menu.get_children ()) {
            child.visible = true;
        }
    }
    
    /**
     * Configures the emission of notifications when tasks/breaks are over
     */
    private void setup_notifications () {
        task_timer.active_task_changed.
                connect ((s, reference, break_active) => {
            if (break_previously_active != break_active) {
                var task = GOFI.Utils.tree_row_ref_to_task (reference);
                Notification notification;
                if (break_active) {
                    notification = new Notification ("Take a Break");
                    notification.set_body ("Relax and stop thinking about your "
                        + "current task for a while :-)");
                } else {
                    notification = new Notification ("The Break is Over");
                    notification.set_body ("Your next task is: " + task);
                }
                application.send_notification (null, notification);
            }
            break_previously_active = break_active;
        });
    }
    
    /**
     * Searches the system for a css stylesheet, that corresponds to go-for-it.
     * If it has been found in one of the potential data directories, it gets
     * applied to the application.
     */
    private void load_css () {
        var screen = this.get_screen();
        var css_provider = new Gtk.CssProvider();
        // Scan all potential data dirs for the corresponding css file
        foreach (var dir in Environment.get_system_data_dirs ()) {
            // The path where the file is to be located
            var path = Path.build_filename (dir, GOFI.APP_SYSTEM_NAME, 
                "style", "go-for-it.css");
            // Only proceed, if file has been found
            if (FileUtils.test (path, FileTest.EXISTS)) {
                try {
                    css_provider.load_from_path(path);
                    Gtk.StyleContext.add_provider_for_screen(
                        screen,css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
                } catch (Error e) {
                    error ("Cannot load CSS stylesheet: %s", e.message);
                }
            }
        }
    }
}
