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
    private TaskTimer task_timer;
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

    private Gtk.Widget? list_menu;

    public const string ACTION_PREFIX = "win";
    public const string ACTION_ABOUT = "about";
    public const string ACTION_CONTRIBUTE = "contribute";
    public const string ACTION_FILTER = "filter";
    public const string ACTION_SETTINGS = "settings";
    public const string ACTION_NEW = "new_todo";
    public const string ACTION_TIMER = "toggle_timer";
    public const string ACTION_SWITCH_PAGE_LEFT = "switch_page_left";
    public const string ACTION_SWITCH_PAGE_RIGHT = "switch_page_right";

    private const string switch_btn_overview_text = _("Go to overview");
    private const string switch_btn_list_text = _("Go back to the to-do list");

    private const ActionEntry[] action_entries = {
        { ACTION_ABOUT, show_about_dialog },
#if !NO_CONTRIBUTE_DIALOG
        { ACTION_CONTRIBUTE, show_contribute_dialog },
#endif
        { ACTION_SETTINGS, show_settings },
        { ACTION_NEW, action_create_new },
        { ACTION_TIMER, action_toggle_timer },
        { ACTION_SWITCH_PAGE_LEFT, action_switch_page_left },
        { ACTION_SWITCH_PAGE_RIGHT, action_switch_page_right }
    };

    /**
     * The constructor of the MainWindow class.
     */
    public MainWindow (Gtk.Application app_context, TaskTimer task_timer,
                       TodoListInfo? initial_list)
    {
        // Pass the applicaiton context via GObject-based construction, because
        // constructor chaining is not possible for Gtk.ApplicationWindow
        Object (application: app_context, title: APP_NAME);
        this.task_timer = task_timer;
        assert (GOFI.list_manager != null);

        apply_settings ();

        setup_window ();
        setup_actions (app_context);
        setup_menu ();
        setup_widgets ();
        init_css ();
        Gtk.IconTheme.get_default ().add_resource_path (GOFI.RESOURCE_PATH + "/icons");

        load_initial (initial_list);

        list_manager.list_removed.connect (on_list_removed);
    }

    ~MainWindow () {
        task_page.remove_task_list ();
    }

    /**
     * Checks if this list is currently in use and removes this list from
     * task_page, should this be the case.
     */
    private void on_list_removed (string provider, string id) {
        var shown_list = task_page.shown_list;
        if (shown_list == null) {
            return;
        }
        var list_info = shown_list.list_info;
        if (list_info.provider_name == provider &&
            list_info.id == id
        ) {
            switch_top_stack (true);
            if (task_page.active_list == shown_list) {
                switch_btn.sensitive = false;
                task_page.remove_task_list ();
            } else {
                load_list (task_page.active_list);
            }
        } else {
            list_info = task_page.active_list.list_info;
            if (list_info.provider_name == provider &&
                list_info.id == id
            ) {
                task_page.switch_active_task_list ();
            }
        }
    }

    public override void show_all () {
        base.show_all ();
        if (top_stack.visible_child != task_page) {
            task_page.show_switcher (false);
        }
    }

    private void load_initial (TodoListInfo? initial_list) {
        if (initial_list == null) {
            list_menu_container.hide ();
        } else {
            on_list_chosen (initial_list);
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

        selection_page = new SelectionPage ();
        task_page = new TaskListPage (task_timer);

        selection_page.list_chosen.connect (on_list_chosen);

        setup_stack ();
        setup_top_bar ();

        main_layout.add (top_stack);

        // Add main_layout to the window
        this.add (main_layout);
    }

    public void on_list_chosen (TodoListInfo selected_info) {
        // Prevent retrieving a new list if this list is currently in use
        var shown_list = task_page.shown_list;
        if (shown_list != null) {
            if (shown_list.list_info == selected_info) {
                switch_top_stack (false);
                return;
            } else if (task_page.active_list.list_info == selected_info) {
                load_list (task_page.active_list);
                switch_top_stack (false);
                return;
            }
        }

        var list = list_manager.get_list (selected_info.provider_name, selected_info.id);
        assert (list != null);
        load_list (list);
        switch_btn.sensitive = true;
        switch_top_stack (false);
    }

    private void load_list (TaskList list) {
        task_page.show_task_list (list);
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
        app.set_accels_for_action (
            ACTION_PREFIX + "." + ACTION_TIMER,
            {kbsettings.get_shortcut ("toggle-timer").to_string ()}
        );
        app.set_accels_for_action (
            ACTION_PREFIX + "." + ACTION_NEW,
            {kbsettings.get_shortcut ("add-new").to_string ()}
        );
        app.set_accels_for_action (
            ACTION_PREFIX + "." + ACTION_SWITCH_PAGE_LEFT,
            {kbsettings.get_shortcut ("cycle-page-reverse").to_string ()}
        );
        app.set_accels_for_action (
            ACTION_PREFIX + "." + ACTION_SWITCH_PAGE_RIGHT,
            {kbsettings.get_shortcut ("cycle-page").to_string ()}
        );
    }

    [Signal (action = true)]
    public virtual signal void filter_fallback_action () {
        // If the user presses ctrl+f and the task list is shown but not
        // focussed we need to manually activate the key binding
        if (top_stack.visible_child == task_page) {
            task_page.propagate_filter_action ();
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
            "open-menu-fallback");
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
            var shown_list = task_page.shown_list;
            if (shown_list != null) {
                selection_page.select_row (shown_list.list_info);
            }

            top_stack.set_visible_child (selection_page);

            var next_icon = GOFI.Utils.get_image_fallback ("go-next-symbolic", "go-next");
            switch_img.set_from_icon_name (next_icon, settings.toolbar_icon_size);
            switch_btn.tooltip_text = switch_btn_list_text;
            settings.list_last_loaded = null;
            task_page.show_switcher (false);
            list_menu_container.hide ();
            list_menu_container.hide ();
        } else if (task_page.ready) {
            var current_list_info = task_page.shown_list.list_info;
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
        var dialog = new SettingsDialog (this);
        dialog.show ();
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

        palette_css.load_from_resource (@"$(GOFI.RESOURCE_PATH)/style/palettes/$(palette).css");
        stylesheet_css.load_from_resource (@"$(GOFI.RESOURCE_PATH)/style/$(stylesheet)");
    }

    /**
     * Restores the window geometry from settings
     */
    public void restore_win_geometry () {
        int x, y, width, height;
        settings.get_window_position (out x, out y);
        settings.get_window_size (out width, out height);
        if (x < 0 || y < 0) {
            // Center if no position have been saved yet
            this.set_position (Gtk.WindowPosition.CENTER);
        } else {
            this.move (x, y);
        }
        this.set_default_size (width, height);
    }

    /**
     * Persistently store the window geometry
     */
    public void save_win_geometry () {
        int x, y, width, height;
        this.get_position (out x, out y);
        this.get_size (out width, out height);

        // Store values
        settings.set_window_position (x, y);
        settings.set_window_size (width, height);
    }
}
