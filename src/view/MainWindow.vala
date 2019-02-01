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
    private ListManager list_manager;
    private TaskTimer task_timer;
    private SettingsManager settings;
    private bool use_header_bar;

    /* Various GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.HeaderBar header_bar;
    private Gtk.Box hb_replacement;
    // Stack and pages
    private Gtk.Stack top_stack;
    private SelectionPage selection_page;
    private TaskListPage task_page;
    private Gtk.MenuButton menu_btn;
    private Gtk.ToolButton switch_btn;
    private Gtk.Image switch_img;
    // Application Menu
    private Gtk.Menu app_menu;
    private Gtk.MenuItem config_item;

    private Gtk.Settings gtk_settings;
    /**
     * Used to determine if a notification should be sent.
     */
    private bool break_previously_active { get; set; default = false; }

    /**
     * The constructor of the MainWindow class.
     */
    public MainWindow (Gtk.Application app_context, ListManager list_manager,
                       TaskTimer task_timer, SettingsManager settings)
    {
        // Pass the applicaiton context via GObject-based construction, because
        // constructor chaining is not possible for Gtk.ApplicationWindow
        Object (application: app_context);
        this.list_manager = list_manager;
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

        gtk_settings = Gtk.Settings.get_default();

        gtk_settings.gtk_application_prefer_dark_theme = settings.use_dark_theme;

        settings.use_dark_theme_changed.connect ( (use_dark_theme) => {
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

        /* Widget Settings */
        // Main Layout
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        main_layout.get_style_context ().add_class ("main_layout");

        selection_page = new SelectionPage (list_manager);
        task_page = new TaskListPage (task_timer);

        selection_page.list_chosen.connect (load_list);

        setup_stack ();
        setup_top_bar ();

        main_layout.add (top_stack);

        // Add main_layout to the window
        this.add (main_layout);
    }

    private void load_list (TodoListInfo selected_info) {
        if (task_page.ready) {
            task_page.remove_task_list ();
        }

        task_page.set_task_list (list_manager.get_list (selected_info.id));
        top_stack.set_visible_child (task_page);
        switch_btn.sensitive = true;
        switch_img.set_from_icon_name ("go-previous", Gtk.IconSize.LARGE_TOOLBAR);
    }

    private void setup_actions (Gtk.Application app) {
        var filter_action = new SimpleAction ("filter", null);
        filter_action.activate.connect (() => show_search ());
        app.add_action (filter_action);
        app.set_accels_for_action ("app.filter", {"<Control>f"});
    }

    private void show_search () {
        var visible_page = top_stack.visible_child;
        if (visible_page == task_page) {
            task_page.toggle_filter_bar ();
        }
    }

    private void setup_stack () {
        top_stack = new Gtk.Stack ();
        top_stack.add (selection_page);
        top_stack.add (task_page);
    }

    private void setup_top_bar () {
        // Butons and their corresponding images
        var menu_img = GOFI.Utils.load_image_fallback (
            Gtk.IconSize.LARGE_TOOLBAR, "open-menu", "open-menu-symbolic",
            GOFI.ICON_NAME + "-open-menu-fallback");
        menu_btn = new Gtk.MenuButton ();
        menu_btn.set_popup (app_menu);
        menu_btn.image = menu_img;
        menu_btn.tooltip_text = _("Menu");
        app_menu.halign = Gtk.Align.END;

        switch_img = new Gtk.Image.from_icon_name ("go-next", Gtk.IconSize.LARGE_TOOLBAR);
        switch_btn = new Gtk.ToolButton (switch_img, _("_Back"));
        switch_btn.sensitive = false;
        switch_btn.clicked.connect (switch_top_stack);

        if (use_header_bar){
            add_headerbar ();
        } else {
            add_hb_replacement ();
        }
    }

    private void switch_top_stack () {
        if (top_stack.visible_child == task_page) {
            top_stack.set_visible_child (selection_page);
            switch_img.set_from_icon_name ("go-next", Gtk.IconSize.LARGE_TOOLBAR);
        } else if (task_page.ready) {
            top_stack.set_visible_child (task_page);
            switch_img.set_from_icon_name ("go-previous", Gtk.IconSize.LARGE_TOOLBAR);
        }
    }

    public void add_hb_replacement () {
//        header_bar = new Gtk.HeaderBar ();

//        // GTK Header Bar
//        header_bar.set_show_close_button (true);
//        header_bar.title = GOFI.APP_NAME;

//        // Add headerbar Buttons here
//        header_bar.pack_end (menu_btn);

//        this.set_titlebar (header_bar);
    }

    public void add_headerbar () {
        header_bar = new Gtk.HeaderBar ();

        // GTK Header Bar
        header_bar.set_show_close_button (true);
        header_bar.title = GOFI.APP_NAME;

        // Add headerbar Buttons here
        header_bar.pack_start (switch_btn);
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
        } else {
            add_headerbar ();
            header_bar.show ();
        }
        realize ();
        show ();

        use_header_bar = !use_header_bar;
    }

    private void setup_menu () {
        /* Initialization */
        app_menu = new Gtk.Menu ();
        config_item = new Gtk.MenuItem.with_label (_("Settings"));

        /* Signal and Action Handling */
        config_item.activate.connect ((e) => {
            var dialog = new SettingsDialog (this, settings);
            dialog.show ();
        });

        /* Add Items to Menu */
        app_menu.add (config_item);
#if !NO_CONTRIBUTE_DIALOG
        var contribute_item = new Gtk.MenuItem.with_label (_("Contribute / Donate"));
        contribute_item.activate.connect ((e) => {
            var dialog = new ContributeDialog (this);
            dialog.show ();
        });
        app_menu.add (contribute_item);
#endif
#if SHOW_ABOUT
        var about_item = new Gtk.MenuItem.with_label (_("About"));
        about_item.activate.connect ((e) => {
            var app = get_application () as Main;
            app.show_about (this);
        });
        app_menu.add (about_item);
#endif

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
                    GOFI.EXEC_NAME);
            } else {
                notification = new Notify.Notification (
                    _("The Break is Over"),
                    _("Your next task is") + ": " + task.description,
                    GOFI.EXEC_NAME);
            }

            try {
                notification.show ();
            } catch (GLib.Error err){
                GLib.stderr.printf (
                    "Error in notify! (break_active notification)\n");
            }
        }
        break_previously_active = break_active;
    }

    private void display_almost_over_notification (DateTime remaining_time) {
        int64 secs = remaining_time.to_unix ();
        Notify.Notification notification = new Notify.Notification (
            _("Prepare for your break"),
            _("You have %s seconds left").printf (secs.to_string ()), GOFI.EXEC_NAME);
        try {
            notification.show ();
        } catch (GLib.Error err){
            GLib.stderr.printf (
                "Error in notify! (remaining_time notification)\n");
        }
    }

    /**
     * Searches the system for a css stylesheet, that corresponds to go-for-it.
     * If it has been found in one of the potential data directories, it gets
     * applied to the application.
     */
    private void load_css () {
        var screen = this.get_screen ();
        var css_provider = new Gtk.CssProvider ();

        string color = settings.use_dark_theme ? "-dark" : "";
        string version = (Gtk.get_minor_version () >= 19) ? "3.20" : "3.10";

        // Pick the stylesheet that is compatible with the user's Gtk version
        string stylesheet = @"go-for-it-$version$color.css";

        // Scan potential data dirs for the corresponding css file
        foreach (var dir in Environment.get_system_data_dirs ()) {
            // The path where the file is to be located
            var path = Path.build_filename (dir, GOFI.APP_SYSTEM_NAME,
                "style", stylesheet);
            // Only proceed, if file has been found
            if (FileUtils.test (path, FileTest.EXISTS)) {
                try {
                    css_provider.load_from_path (path);
                    Gtk.StyleContext.add_provider_for_screen (
                        screen,css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
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
