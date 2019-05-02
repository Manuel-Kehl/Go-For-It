/* Copyright 2014-2019 Go For It! developers
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

using GOFI.TXT;

/**
 * The main window of Go For It!.
 */
class GOFI.MainWindow : Gtk.ApplicationWindow {
    /* Various Variables */
    private ListManager list_manager;
    private TaskTimer task_timer;
    private SettingsManager settings;
    private bool use_header_bar;

    private Gtk.CssProvider palette_css;
    private Gtk.CssProvider stylesheet_css;

    /* Various GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.HeaderBar header_bar;

    // Stack and pages
    private Gtk.Stack top_stack;
    private SelectionPage selection_page;
    private TaskListPage task_page;
    private Gtk.MenuButton menu_btn;
    private Gtk.ToolButton switch_btn;
    private Gtk.Image switch_img;

    // Application Menu
    private Gtk.Popover menu_popover;
    private Gtk.Box menu_container;
    private Gtk.Box list_menu_container;

    private Gtk.Settings gtk_settings;

    private TodoListInfo? current_list_info;
    private Gtk.Widget? list_menu;

    public const string ACTION_PREFIX = "win";
    public const string ACTION_ABOUT = "about";
    public const string ACTION_CONTRIBUTE = "contribute";
    public const string ACTION_FILTER = "filter";
    public const string ACTION_SETTINGS = "settings";
    public const string ACTION_NEW = "new_todo";
    public const string ACTION_TIMER = "toggle_timer";
    public const string ACTION_TASK_DONE = "task_mark_done";
    public const string ACTION_TASK_NEXT = "task_next";
    public const string ACTION_TASK_PREV = "task_prev";
    public const string ACTION_ROW_MOVE_UP = "row_move_up";
    public const string ACTION_ROW_MOVE_DOWN = "row_move_down";
    public const string ACTION_SWITCH_PAGE_LEFT = "switch_page_left";
    public const string ACTION_SWITCH_PAGE_RIGHT = "switch_page_right";

    private const string switch_btn_overview_text = _("Go to overview");
    private const string switch_btn_list_text = _("Go back to the to-do list");

    private const ActionEntry[] action_entries = {
        { ACTION_ABOUT, show_about_dialog },
#if !NO_CONTRIBUTE_DIALOG
        { ACTION_CONTRIBUTE, show_contribute_dialog },
#endif
        { ACTION_FILTER, toggle_search },
        { ACTION_SETTINGS, show_settings },
        { ACTION_NEW, action_create_new },
        { ACTION_TIMER, action_toggle_timer },
        { ACTION_TASK_DONE, action_mark_task_done },
        { ACTION_TASK_NEXT, action_task_switch_next },
        { ACTION_TASK_PREV, action_task_switch_prev },
        { ACTION_ROW_MOVE_UP, action_row_move_up },
        { ACTION_ROW_MOVE_DOWN, action_row_move_down },
        { ACTION_SWITCH_PAGE_LEFT, action_switch_page_left },
        { ACTION_SWITCH_PAGE_RIGHT, action_switch_page_right }
    };

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
        Object (application: app_context, title: APP_NAME);
        this.list_manager = list_manager;
        this.task_timer = task_timer;
        this.settings = settings;

        apply_settings ();

        setup_window ();
        setup_actions (app_context);
        setup_menu ();
        setup_widgets ();
        init_css ();
        setup_notifications ();
        // Enable Notifications for the App
        Notify.init (GOFI.APP_NAME);

        load_last ();

        list_manager.list_removed.connect (on_list_removed);
    }

    private void on_list_removed (string provider, string id) {
        if (current_list_info != null &&
            current_list_info.provider_name == provider &&
            current_list_info.id == id
        ) {
            switch_top_stack (true);
            switch_btn.sensitive = false;
        }
    }

    public override void show_all () {
        base.show_all ();
        if (top_stack.visible_child != task_page) {
            task_page.show_switcher (false);
        }
    }

    private void load_last () {
        var last_loaded = settings.list_last_loaded;
        if (last_loaded != null) {
            var list = list_manager.get_list (last_loaded.id);
            load_list (list);
        } else {
            current_list_info = null;
            list_menu_container.hide ();
        }
    }

    private void apply_settings () {
        this.use_header_bar = settings.use_header_bar;

        gtk_settings = Gtk.Settings.get_default();

        gtk_settings.gtk_application_prefer_dark_theme = settings.use_dark_theme;

        settings.use_dark_theme_changed.connect ( (use_dark_theme) => {
            gtk_settings.gtk_application_prefer_dark_theme = use_dark_theme;
            load_css ();
        });
        settings.theme_changed.connect ( (use_dark_theme) => {
            load_css ();
        });
        settings.toolbar_icon_size_changed.connect (on_icon_size_changed);
    }

    private void on_icon_size_changed (Gtk.IconSize size) {
        ((Gtk.Image) menu_btn.image).icon_size = size;
        switch_img.icon_size = size;
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
        task_page = new TaskListPage (settings, task_timer);

        selection_page.list_chosen.connect (on_list_chosen);

        setup_stack ();
        setup_top_bar ();

        main_layout.add (top_stack);

        // Add main_layout to the window
        this.add (main_layout);
    }

    private void on_list_chosen (TodoListInfo selected_info) {
        if (selected_info == current_list_info) {
            switch_top_stack (false);
            return;
        }
        var list = list_manager.get_list (selected_info.id);
        assert (list != null);
        load_list (list);
        settings.list_last_loaded = ListIdentifier.from_info (selected_info);
        current_list_info = selected_info;
    }

    private void load_list (TxtList list) {
        current_list_info = list.list_info;
        task_page.set_task_list (list);
        switch_btn.sensitive = true;
        switch_top_stack (false);
        if (list_menu != null) {
            list_menu_container.remove (list_menu);
        }
        list_menu = list.get_menu ();
        list_menu_container.pack_start (list_menu);
    }

    private void setup_actions (Gtk.Application app) {
        var actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        insert_action_group (ACTION_PREFIX, actions);
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_FILTER, {"<Control>F"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_NEW, {"<Control>N"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_TIMER, {"<Control>P"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_TASK_DONE, {"<Control>Return"});
//        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_TASK_NEXT, {"K"});
//        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_TASK_PREV, {"J"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_ROW_MOVE_UP, {"<Control>K"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_ROW_MOVE_DOWN, {"<Control>J"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_SWITCH_PAGE_LEFT, {"<Shift>J"});
        app.set_accels_for_action (ACTION_PREFIX + "." + ACTION_SWITCH_PAGE_RIGHT, {"<Shift>K"});
    }

    private void toggle_search () {
        if (top_stack.visible_child == task_page) {
            task_page.toggle_filtering ();
        }
    }

    private void action_create_new () {
        if (top_stack.visible_child == task_page) {
            task_page.action_add_task ();
        } else {
            selection_page.show_list_creation_dialog ();
        }
    }

    private void action_toggle_timer () {
        if (task_page.ready && task_timer.active_task != null) {
            task_timer.toggle_running ();
        }
    }

    private void action_mark_task_done () {
        if (top_stack.visible_child == task_page) {
            task_page.action_mark_task_done ();
        }
    }

    private void action_task_switch_next () {
        if (top_stack.visible_child == task_page) {
            task_page.action_task_switch_next ();
        } else {
            selection_page.move_cursor (1);
        }
    }

    private void action_task_switch_prev () {
        if (top_stack.visible_child == task_page) {
            task_page.action_task_switch_prev ();
        } else {
            selection_page.move_cursor (-1);
        }
    }

    private void action_row_move_up () {
        if (top_stack.visible_child == task_page) {
            task_page.action_row_move_up ();
        } else {
            selection_page.move_selected_row (1);
        }
    }

    private void action_row_move_down () {
        if (top_stack.visible_child == task_page) {
            task_page.action_row_move_down ();
        } else {
            selection_page.move_selected_row (-1);
        }
    }

    private void action_switch_page_left () {
        if (top_stack.visible_child != task_page || !task_page.ready) {
            return;
        }
        if (task_page.switch_page_left ()) {
            switch_top_stack (true);
        }
    }

    private void action_switch_page_right () {
        if (!task_page.ready) {
            return;
        }
        if (top_stack.visible_child != task_page) {
            switch_top_stack (false);
        } else {
            task_page.switch_page_right ();
        }
    }

    private void setup_stack () {
        top_stack = new Gtk.Stack ();
        top_stack.add (selection_page);
        top_stack.add (task_page);
        top_stack.set_visible_child (selection_page);
    }

    private void setup_top_bar () {
        // Butons and their corresponding images
        var menu_img = GOFI.Utils.load_image_fallback (
            settings.toolbar_icon_size, "open-menu", "open-menu-symbolic",
            GOFI.ICON_NAME + "-open-menu-fallback");
        menu_btn = new Gtk.MenuButton ();
        menu_btn.hexpand = false;
        menu_btn.image = menu_img;
        menu_btn.tooltip_text = _("Menu");

        menu_popover = new Gtk.Popover (menu_btn);
        menu_popover.add (menu_container);
        menu_btn.popover = menu_popover;

        switch_img = new Gtk.Image.from_icon_name ("go-next", settings.toolbar_icon_size);
        switch_btn = new Gtk.ToolButton (switch_img, null);
        switch_btn.hexpand = false;
        switch_btn.sensitive = false;
        switch_btn.clicked.connect (toggle_top_stack);
        switch_btn.tooltip_text = switch_btn_list_text;

        if (use_header_bar){
            add_headerbar ();
        } else {
            add_headerbar_as_toolbar ();
        }
    }

    private void toggle_top_stack () {
        switch_top_stack (top_stack.visible_child == task_page);
    }

    private void switch_top_stack (bool show_select) {
        if (show_select) {
            top_stack.set_visible_child (selection_page);

            var next_icon = GOFI.Utils.get_image_fallback ("go-next-symbolic", "go-next");
            switch_img.set_from_icon_name (next_icon, settings.toolbar_icon_size);
            switch_btn.tooltip_text = switch_btn_list_text;
            settings.list_last_loaded = null;
            task_page.show_switcher (false);
            list_menu_container.hide ();
        } else if (task_page.ready) {
            top_stack.set_visible_child (task_page);
            var prev_icon = GOFI.Utils.get_image_fallback ("go-previous-symbolic", "go-previous");
            switch_img.set_from_icon_name (prev_icon, settings.toolbar_icon_size);
            switch_btn.tooltip_text = switch_btn_overview_text;
            if (current_list_info != null) {
                settings.list_last_loaded = ListIdentifier.from_info (current_list_info);
            } else {
                settings.list_last_loaded = null;
            }
            task_page.show_switcher (true);
            list_menu_container.show ();
        }
    }

    /**
     * No other suitable toolbar like widget seems to exist.
     * ToolBar is not suitable due to alignment issues and the "toolbar"
     * styleclass isn't universally supported.
     */
    public void add_headerbar_as_toolbar () {
        header_bar = new Gtk.HeaderBar ();
        header_bar.has_subtitle = false;
        header_bar.get_style_context ().add_class ("toolbar");

        // GTK Header Bar
        header_bar.set_show_close_button (false);

        // Add headerbar Buttons here
        header_bar.pack_start (switch_btn);
        header_bar.set_custom_title (task_page.get_switcher ());
        header_bar.pack_end (menu_btn);

        main_layout.add (header_bar);
    }

    public void add_headerbar () {
        header_bar = new Gtk.HeaderBar ();
        header_bar.has_subtitle = false;

        // GTK Header Bar
        header_bar.set_show_close_button (true);

        // Add headerbar Buttons here
        header_bar.pack_start (switch_btn);
        header_bar.title = APP_NAME;
        header_bar.set_custom_title (task_page.get_switcher ());
        header_bar.pack_end (menu_btn);

        this.set_titlebar (header_bar);
    }

    private void setup_menu () {
        /* Initialization */
        menu_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        list_menu_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var config_item = new Gtk.ModelButton ();

        list_menu_container.pack_end (
            new Gtk.Separator (Gtk.Orientation.HORIZONTAL)
        );

        menu_container.add (list_menu_container);

        config_item.text = _("Settings");
        config_item.action_name = ACTION_PREFIX + "." + ACTION_SETTINGS;
        menu_container.add (config_item);

#if !NO_CONTRIBUTE_DIALOG
        var contribute_item = new Gtk.ModelButton ();
        contribute_item.text = _("Contribute / Donate");
        contribute_item.action_name = ACTION_PREFIX + "." + ACTION_CONTRIBUTE;
        menu_container.add (contribute_item);
#endif

#if SHOW_ABOUT
        var about_item = new Gtk.ModelButton ();
        about_item.text = _("About");
        about_item.action_name = ACTION_PREFIX + "." + ACTION_ABOUT;
        menu_container.add (about_item);
#endif

        menu_container.show_all ();
    }

    private void show_about_dialog () {
        var app = get_application () as Main;
        app.show_about (this);
    }

#if !NO_CONTRIBUTE_DIALOG
    private void show_contribute_dialog () {
        var dialog = new ContributeDialog (this);
        dialog.show ();
    }
#endif

    private void show_settings () {
        var dialog = new SettingsDialog (this, settings);
        dialog.show ();
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
            notification.set_hint (
                "desktop-entry", new Variant.string (GOFI.APP_SYSTEM_NAME)
            );

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

    private void init_css () {
        var screen = this.get_screen ();
        palette_css = new Gtk.CssProvider ();
        stylesheet_css = new Gtk.CssProvider ();

        load_css ();

        Gtk.StyleContext.add_provider_for_screen (
            screen, palette_css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
        Gtk.StyleContext.add_provider_for_screen (
            screen, stylesheet_css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    /**
     * Load the css style information from the data directory specified at build
     * time.
     */
    private void load_css () {
        var theme = settings.theme;
        var palette = theme.get_palette (settings.use_dark_theme);

        string version = (Gtk.get_minor_version () >= 19) ? "3.20" : "3.10";

        // Pick the stylesheet that is compatible with the user's Gtk version
        string stylesheet = @"$(theme.get_stylesheet ())-$version.css";

        var path = Path.build_filename (DATADIR, "style", "palettes", palette + ".css");
        if (FileUtils.test (path, FileTest.EXISTS)) {
            try {
                palette_css.load_from_path (path);
            } catch (Error e) {
                warning ("Cannot load CSS stylesheet: %s", e.message);
                return;
            }
        } else {
            warning ("Could not find application stylesheet in %s", path);
            return;
        }

        path = Path.build_filename (DATADIR, "style", stylesheet);
        if (FileUtils.test (path, FileTest.EXISTS)) {
            try {
                stylesheet_css.load_from_path (path);
            } catch (Error e) {
                warning ("Cannot load CSS stylesheet: %s", e.message);
            }
        } else {
            warning ("Could not find application stylesheet in %s", path);
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
