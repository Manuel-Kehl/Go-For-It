/* Copyright 2014-2017 Go For It! developers
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
    private bool refreshing = false;

    /* Various GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Stack activity_stack;
    private Gtk.StackSwitcher activity_switcher;
    private Gtk.HeaderBar header_bar;
    private Gtk.Box switcher_box;
    private TaskList todo_list;
    private TaskList done_list;
    private TimerView timer_view;
    private Gtk.ToggleToolButton menu_btn;
    // Application Menu
    private Gtk.Menu app_menu;
    private Gtk.MenuItem config_item;
    private Gtk.MenuItem clear_done_item;
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
                       TaskTimer task_timer, SettingsManager settings)
    {
        // Pass the applicaiton context via GObject-based construction, because
        // constructor chaining is not possible for Gtk.ApplicationWindow
        Object (application: app_context);
        this.task_manager = task_manager;
        this.task_timer = task_timer;
        this.settings = settings;

        apply_settings ();

        setup_window ();
        setup_menu ();
        setup_widgets ();
        setup_actions (app_context);
        load_css ();
        setup_notifications ();
        // Enable Notifications for the App
        Notify.init (GOFI.APP_NAME);
    }

    private void apply_settings () {
        this.use_header_bar = settings.use_header_bar;

        if (settings.use_dark_theme) {
            unowned Gtk.Settings gtk_settings = Gtk.Settings.get_default();
            gtk_settings.gtk_application_prefer_dark_theme = true;
        }

        settings.use_dark_theme_changed.connect ( (use_dark_theme) => {
            unowned Gtk.Settings gtk_settings = Gtk.Settings.get_default();
            gtk_settings.gtk_application_prefer_dark_theme = use_dark_theme;
            load_css ();
        });
        settings.use_header_bar_changed.connect (toggle_headerbar);
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
        todo_list.selection_changed.connect (on_selection_changed);
        task_manager.active_task_invalid.connect (on_active_task_invalid);

        // Call once to refresh view on startup
        on_active_task_invalid ();

        main_layout.add (switcher_box);
        main_layout.add (activity_stack);

        // Add main_layout to the window
        this.add (main_layout);
    }

    private void setup_actions (Gtk.Application app) {
        var filter_action = new SimpleAction ("filter", null);
        filter_action.activate.connect (() => show_search ());
        app.add_action (filter_action);
        app.set_accels_for_action ("app.filter", {"<Control>f"});
    }

    private void show_search () {
        var list = activity_stack.visible_child as TaskList;
        if (list != null) {
            list.toggle_filter_bar ();
        }
    }

    private void setup_stack () {
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
        activity_switcher.margin = 5;
    }

    private void setup_top_bar () {
        // ToolButons and their corresponding images
        var menu_img = GOFI.Utils.load_image_fallback (
            Gtk.IconSize.LARGE_TOOLBAR, "open-menu", "open-menu-symbolic",
            GOFI.ICON_NAME + "-open-menu-fallback");
        menu_btn = new Gtk.ToggleToolButton ();
        // Headerbar Items
        menu_btn.icon_widget = menu_img;
        menu_btn.label_widget = new Gtk.Label (_("Menu"));
        menu_btn.toggled.connect (menu_btn_toggled);

        switcher_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        switcher_box.pack_start (activity_switcher, true, true);

        if(use_header_bar){
            add_headerbar ();
        } else {
            switcher_box.pack_end (menu_btn, false, false);
        }
    }

    public void add_headerbar () {
        header_bar = new Gtk.HeaderBar ();

        // GTK Header Bar
        header_bar.set_show_close_button (true);
        header_bar.title = GOFI.APP_NAME;

        // Add headerbar Buttons here
        header_bar.pack_end (menu_btn);

        this.set_titlebar (header_bar);
    }

    private void toggle_headerbar () {
        hide ();
        unrealize ();
        if (use_header_bar) {
            header_bar.remove (menu_btn);
            header_bar = null;
            set_titlebar (null);
            switcher_box.pack_end (menu_btn, false, false);
        } else {
            switcher_box.remove (menu_btn);
            add_headerbar ();
            header_bar.show ();
        }
        realize ();
        show ();

        use_header_bar = !use_header_bar;
    }

    public void on_selection_changed (TodoTask? selected_task) {
        if (task_timer.running || refreshing) {
            return;
        }

        set_active_task (selected_task);
    }

    private void on_active_task_invalid () {
        var selected_task = todo_list.get_selected_task ();

        set_active_task (selected_task);
    }

    private void set_active_task (TodoTask? active_task) {
        task_manager.set_active_task (active_task);
        task_timer.active_task = active_task;
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

    private void task_timer_activated (TodoTask? task, bool break_active) {
        if (task == null) {
            return;
        }
        if (break_previously_active != break_active) {
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
                    _("Your next task is") + ": " + task.title,
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
            _("You have %s seconds left").printf (secs.to_string ()), GOFI.APP_SYSTEM_NAME);
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

        string color = settings.use_dark_theme ? "-dark" : "";
        string version = (Gtk.get_minor_version () >= 19) ? "3.20" : "3.10";

        // Pick the stylesheet that is compatible with the user's Gtk version
        string stylesheet = @"go-for-it-$version$color.css";

        // Scan potential data dirs for the corresponding css file
        foreach (var dir in Environment.get_system_data_dirs ()) {
            // The path where the file is to be located
            var path = Path.build_filename (dir, GOFI.APP_ID,
                "style", stylesheet);
            // Only proceed, if file has been found
            if (FileUtils.test (path, FileTest.EXISTS)) {
                try {
                    css_provider.load_from_path(path);
                    Gtk.StyleContext.add_provider_for_screen(
                        screen,css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
                    break;
                } catch (Error e) {
                    warning ("Cannot load CSS stylesheet: %s", e.message);
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
