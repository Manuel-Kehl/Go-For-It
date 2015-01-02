/* Copyright 2014 Manuel Kehl (mank319)
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
    private Gtk.ToggleToolButton menu_btn;
    // Application Menu
    private Gtk.Menu app_menu;
    private Gtk.MenuItem clear_done_item;
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
        setup_notifications ();
    }
    
    /**
     * Configures the window's properties.
     */
    private void setup_window () {
        this.title = GOFI.APP_NAME;
        this.set_border_width (0);
        restore_win_geometry ();
        
        // Save window state upon deleting the window
        this.delete_event.connect ((e) => {
            save_win_geometry ();
            return false;
        });
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
        // ToolButons and their corresponding images
        var menu_img = GOFI.Utils.load_image_fallback (
            Gtk.IconSize.LARGE_TOOLBAR, "open-menu", "open-menu-symbolic", 
            "go-for-it-open-menu-fallback");
        menu_btn = new Gtk.ToggleToolButton ();
        
        /* Widget Settings */
        // Main Layout
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        
        // Activity Stack + Switcher
        activity_switcher.set_stack (activity_stack);
        activity_switcher.halign = Gtk.Align.CENTER;
        activity_switcher.margin = 5;
        activity_stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        // Add widgets to the activity stack
        activity_stack.add_titled (todo_list, "todo", "To-Do");
        activity_stack.add_titled (timer_view, "timer", "Timer");
        activity_stack.add_titled (done_list, "done", "Done");

        if (task_timer.running) {
            // Otherwise no task will be displayed in the timer view
            task_timer.update_active_task ();
            // Otherwise it won't switch
            timer_view.show ();
            activity_stack.set_visible_child_name ("timer");
        }
            
        // GTK Header Bar
        header_bar.set_show_close_button (true);
        header_bar.title = GOFI.APP_NAME;
        this.set_titlebar (header_bar);
        
        // Headerbar Items
        menu_btn.icon_widget = menu_img;
        menu_btn.label_widget = new Gtk.Label ("Menu");
        menu_btn.toggled.connect (menu_btn_toggled);
        // Add headerbar Buttons here
        header_bar.pack_end (menu_btn);
        
        /* Action and Signal Handling */
        todo_list.add_new_task.connect (task_manager.add_new_task);
        var todo_selection = todo_list.task_view.get_selection ();
        todo_selection.select_path (task_timer.active_task.get_path ());
        /* 
         * If either the selection or the data itself changes, it is 
         * necessary to check if a different task is to be displayed
         * in the timer widget and thus todo_selection_changed is to be called
         */
        todo_selection.changed.
            connect (todo_selection_changed);
        task_manager.done_store.task_data_changed.
            connect (todo_selection_changed);
        
        // Call once to refresh view on startup
        todo_selection_changed ();
        
        main_layout.add (activity_switcher);
        main_layout.add (activity_stack);

        // Add main_layout to the window
        this.add (main_layout);
    }

    private void todo_selection_changed () {
        Gtk.TreeModel model;
        Gtk.TreePath path;
        var todo_selection = todo_list.task_view.get_selection ();

        // If no row has been selected, select the first in the list
        if (todo_selection.count_selected_rows () == 0) {
            todo_selection.select_path (new Gtk.TreePath.first ());
        }
        
        // Check if TodoStore is empty or not
        if (task_manager.todo_store.is_empty ()) {
            timer_view.show_no_task ();
            return;
        }
        
        // Take the first selected row
        path = todo_selection.get_selected_rows (out model).nth_data (0);
        var reference = new Gtk.TreeRowReference (model, path);
        task_timer.active_task = reference;
    }

    private void menu_btn_toggled (Gtk.ToggleToolButton source) {
        if (source.active) {
            app_menu.popup (null, null, calc_menu_position, 0,
                            Gtk.get_current_event_time ());
            app_menu.select_first (true);
        } else {
            app_menu.popdown ();
        }
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
        clear_done_item = new Gtk.MenuItem.with_label ("Clear Done List");
        config_item = new Gtk.MenuItem.with_label ("Configuration");
        about_item = new Gtk.MenuItem.with_label ("About");
        
        /* Signal and Action Handling */
        // Untoggle menu button, when menu is hidden
        app_menu.hide.connect ((e) => {
            menu_btn.active = false;
        });
        
        clear_done_item.activate.connect ((e) => {
            task_manager.clear_done_store ();
        });
        config_item.activate.connect ((e) => {
            var dialog = new SettingsDialog (false, settings);
            dialog.show ();
        });
        about_item.activate.connect ((e) => {
            var app = get_application () as Main;
            app.show_about ();
        });
        
        /* Add Items to Menu */
        app_menu.add (clear_done_item);
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
        task_timer.active_task_changed.connect (task_timer_activated);
        task_timer.timer_almost_over.connect (display_almost_over_notification);
    }

    private void task_timer_activated (Gtk.TreeRowReference reference,
                                       bool break_active) {

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
    }
    
    private void display_almost_over_notification (DateTime remaining_time) {
        int64 secs = remaining_time.to_unix ();
        var notification = new Notification ("Prepare for your break");
        notification.set_body (@"You have $secs seconds left");
        application.send_notification (null, notification);
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
    
    /**
     * Restores the window geometry from settings
     */
    private void restore_win_geometry () {
        if (settings.win_x == -1 || settings.win_y == -1) {
            // Center if no position have been saved yet
            this.set_position (Gtk.WindowPosition.CENTER);
        } else {
            this.move (settings.win_x, settings.win_y);
        }
        this.set_default_size (settings.win_width, settings.win_height);
    }
    
    /**
     * Persistently store the window geometry
     */
    private void save_win_geometry () {
        int x, y, width, height;
        this.get_position (out x, out y);
        this.get_size (out width, out height);
        
        // Store values in SettingsManager
        settings.win_x = x;
        settings.win_y = y;
        settings.win_width = width;
        settings.win_height = height;
    }
}
