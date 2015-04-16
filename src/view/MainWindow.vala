/* Copyright 2014 Manuel Kehl (mank319)
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
 * The main window of Go For It!.
 */
class MainWindow : Gtk.ApplicationWindow {
    /* Various Variables */
    private TaskManager task_manager;
    private TaskTimer task_timer;
    private SettingsManager settings;
    private bool use_header_bar;
    
    /* Various GTK Widgets */
    private Gtk.Grid main_layout;
#if HAS_GTK310
    private Gtk.Stack activity_stack;
    private Gtk.StackSwitcher activity_switcher;
    private Gtk.HeaderBar header_bar;
#else
    private Gtk.Notebook activity_stack;
    private Gtk.Box activity_switcher;
    // Flag for controlling whether the activity has been toggled by hand
    private bool activity_toggled_manually = true;
#endif
    private Gtk.Box hb_replacement;
    private TaskList todo_list;
    private TaskList done_list;
    private TimerView timer_view;
    private Gtk.ToggleToolButton menu_btn;
    // Application Menu
    private Gtk.Menu app_menu;
    private Gtk.MenuItem config_item;
    private Gtk.MenuItem clear_done_item;
    private Gtk.MenuItem refresh_item;
    private Gtk.MenuItem contribute_item;
    private Gtk.MenuItem about_item;
    /**
     * Used to determine if a notification should be sent.
     */
    private bool break_previously_active { get; set; default = false; }
    
    /**
     * The constructor of the MainWindow class.
     */
    public MainWindow (Gtk.Application app_context, TaskManager task_manager,
            TaskTimer task_timer, SettingsManager settings, 
            bool use_header_bar) {
        // Pass the applicaiton context via GObject-based construction, because
        // constructor chaining is not possible for Gtk.ApplicationWindow
        Object (application: app_context);
        this.task_manager = task_manager;
        this.task_timer = task_timer;
        this.settings = settings;
        this.use_header_bar = use_header_bar;

        setup_window ();
        setup_menu ();
        setup_widgets ();
        load_css ();
        setup_notifications ();
        // Enable Notifications for the App
        Notify.init (GOFI.APP_NAME);
    }
    
    public override bool delete_event (Gdk.EventAny event) {
        bool dont_exit = false;
        
        // Save window state upon deleting the window
        save_win_geometry ();
        
        if (task_timer.running) {
            this.show.connect (restore_win_geometry);
            hide ();
            dont_exit = true;
        }
        
        if (dont_exit == false) Notify.uninit ();
            
        return dont_exit;
    }
    
    /**
     * Configures the window's properties.
     */
    private void setup_window () {
        this.title = GOFI.APP_NAME;
        this.set_border_width (0);
        restore_win_geometry ();
    }
    
    /** 
     * Initializes GUI elements and configures their look and behavior.
     */
    private void setup_widgets () {
        /* Instantiation of the Widgets */
        main_layout = new Gtk.Grid ();
        
        todo_list = new TaskList (this.task_manager.todo_store, true);
        done_list = new TaskList (this.task_manager.done_store, false);
        timer_view = new TimerView (task_timer);
        
        /* Widget Settings */
        // Main Layout
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        
        setup_stack ();
        setup_top_bar ();
        
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
        
        if (use_header_bar)
            main_layout.add (activity_switcher);
        else
            main_layout.add (hb_replacement);
        main_layout.add (activity_stack);
        
        // Add main_layout to the window
        this.add (main_layout);
    }
    
    private void setup_stack () {
#if HAS_GTK310
        activity_stack = new Gtk.Stack ();
        activity_switcher = new Gtk.StackSwitcher ();

        // Activity Stack + Switcher
        activity_switcher.set_stack (activity_stack);
        activity_switcher.halign = Gtk.Align.CENTER;
        activity_stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        // Add widgets to the activity stack
        activity_stack.add_titled (todo_list, "todo", _("To-Do"));
        activity_stack.add_titled (timer_view, "timer", _("Timer"));
        activity_stack.add_titled (done_list, "done", _("Done"));
        
        if (task_timer.running) {
            // Otherwise no task will be displayed in the timer view
            task_timer.update_active_task ();
            // Otherwise it won't switch
            timer_view.show ();
            activity_stack.set_visible_child_name ("timer");
        }
#else
        // mimicing Gtk.Stack with Gtk.Notebook
        activity_stack = new Gtk.Notebook ();
        // mimicing Gtk.StackSwitcher with ToggleButtons
        activity_switcher = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var button1 = new Gtk.ToggleButton.with_label (_("To-Do"));
        var button2 = new Gtk.ToggleButton.with_label (_("Timer"));
        var button3 = new Gtk.ToggleButton.with_label (_("Done"));
        
        // Add widgets to the activity notebook
        activity_stack.append_page (todo_list, new Gtk.Label (_("To-Do")));
        activity_stack.append_page (timer_view, new Gtk.Label (_("Timer")));
        activity_stack.append_page (done_list, new Gtk.Label (_("Done")));
        activity_stack.show_tabs = false;
        
        // Making sure buttons are updated when user switches a page.
        activity_stack.switch_page.connect ((page, offset) => {
            if (offset == 0) {
                activity_toggled_manually = false;
                button2.set_active (false);
                button3.set_active (false);
                activity_toggled_manually = true;
            }
            else if (offset == 1) {
                activity_toggled_manually = false;
                button1.set_active (false);
                button3.set_active (false);
                activity_toggled_manually = true;
            }
            else {
                activity_toggled_manually = false;
                button1.set_active (false);
                button2.set_active (false);
                activity_toggled_manually = true;
            }
        });
        
        if (task_timer.running) {
            // Otherwise no task will be displayed in the timer view
            task_timer.update_active_task ();
            // Otherwise it won't switch
            timer_view.show ();
            activity_stack.set_current_page (1);
        }
        
        // Mimicing the look of Gtk.StackSwitcher
        activity_switcher.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        activity_switcher.get_style_context ().add_class ("raised");
        activity_switcher.set_homogeneous (true);
        
        activity_switcher.add (button1);
        activity_switcher.add (button2);
        activity_switcher.add (button3);
        
        button1.toggled.connect (() => {
            if (activity_toggled_manually) {
                if (button1.active) {
                    activity_stack.set_current_page (0);
                } else {
                    button1.set_active (true);
                }
            }
        });
        button2.toggled.connect (() => {
            if (activity_toggled_manually) {
                if (button2.active) {
                    activity_stack.set_current_page (1);
                } else {
                    button2.set_active (true);
                }
            }
        });
        button3.toggled.connect (() => {
            if (activity_toggled_manually) {
                if (button3.active) {
                    activity_stack.set_current_page (2);
                } else {
                    button3.set_active (true);
                }
            }
        });
        button1.set_active (true);
#endif
        activity_switcher.margin = 5;
    }
    
    private void setup_top_bar () {
        // ToolButons and their corresponding images
        var menu_img = GOFI.Utils.load_image_fallback (
            Gtk.IconSize.LARGE_TOOLBAR, "open-menu", "open-menu-symbolic", 
            "go-for-it-open-menu-fallback");
        menu_btn = new Gtk.ToggleToolButton ();
        // Headerbar Items
        menu_btn.icon_widget = menu_img;
        menu_btn.label_widget = new Gtk.Label (_("Menu"));
        menu_btn.toggled.connect (menu_btn_toggled);
#if HAS_GTK310
        if (use_header_bar) {
            header_bar = new Gtk.HeaderBar ();
        
            // GTK Header Bar
            header_bar.set_show_close_button (true);
            header_bar.title = GOFI.APP_NAME;
            this.set_titlebar (header_bar);
        
            // Add headerbar Buttons here
            header_bar.pack_end (menu_btn);
        }
        else {
#endif
            use_header_bar = false;
            hb_replacement = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            hb_replacement.pack_start (activity_switcher, true, true); 
            hb_replacement.pack_end (menu_btn, false, false);
#if HAS_GTK310
        }
#endif
    }
    
    public override void show_all () {
        base.show_all ();
        // Hide done button initially, whenever the window has been shown
        timer_view.done_btn.visible = false;
        // Ensure, that the done button is shown again, if there is a task
        todo_selection_changed ();
    }
    
    public void todo_selection_changed () {
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
        config_item = new Gtk.MenuItem.with_label (_("Settings"));
        clear_done_item = new Gtk.MenuItem.with_label (_("Clear Done List"));
        refresh_item = new Gtk.MenuItem.with_label (_("Refresh"));
        contribute_item = new Gtk.MenuItem.with_label (_("Contribute / Donate"));
        about_item = new Gtk.MenuItem.with_label (_("About"));
        
        /* Signal and Action Handling */
        // Untoggle menu button, when menu is hidden
        app_menu.hide.connect ((e) => {
            menu_btn.active = false;
        });
        
        config_item.activate.connect ((e) => {
            var dialog = new SettingsDialog (this, settings);
            dialog.show ();
        });
        clear_done_item.activate.connect ((e) => {
            task_manager.clear_done_store ();
        });
        refresh_item.activate.connect ((e) => {
            task_manager.refresh ();
        });
        contribute_item.activate.connect ((e) => {
            var dialog = new ContributeDialog (this);
            dialog.show ();
        });
        about_item.activate.connect ((e) => {
            var app = get_application () as Main;
            app.show_about (this);
        });
        
        /* Add Items to Menu */
        app_menu.add (config_item);
        app_menu.add (clear_done_item);
        app_menu.add (refresh_item);
        app_menu.add (contribute_item);
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
            Notify.Notification notification;
            if (break_active) {
                notification = new Notify.Notification (
                    _("Take a Break"), 
                    _("Relax and stop thinking about your current task for a while") 
                    + " :-)",
                    GOFI.APP_SYSTEM_NAME);
            } else {
                notification = new Notify.Notification (
                    _("The Break is Over"), 
                    _("Your next task is") + ": " + task, 
                    GOFI.APP_SYSTEM_NAME);
            }
            
            try {
                notification.show ();
            } catch (GLib.Error err){
                GLib.stderr.printf(
                    "Error in notify! (break_active notification)\n");
            }
        }
        break_previously_active = break_active;
    }
    
    private void display_almost_over_notification (DateTime remaining_time) {
        int64 secs = remaining_time.to_unix ();
        Notify.Notification notification = new Notify.Notification (
            _("Prepare for your break"),
            _(@"You have $secs seconds left"), GOFI.APP_SYSTEM_NAME);
        try {
            notification.show ();
        } catch (GLib.Error err){
            GLib.stderr.printf(
                "Error in notify! (remaining_time notification)\n");
        }
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
