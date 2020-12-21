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

    private Gtk.Button mute_item;
    private Gtk.Button filter_item;

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

    public const string SOUND_ACTION_PREFIX = "sound";

    private const string SWITCH_BTN_OVERVIEW_TEXT = _("Go to overview");
    private const string SWITCH_BTN_LIST_TEXT = _("Go back to the to-do list");

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_ABOUT, show_about_dialog },
#if !NO_CONTRIBUTE_DIALOG // vala-lint=skip
        { ACTION_CONTRIBUTE, show_contribute_dialog },
#endif // vala-lint=skip
        { ACTION_SETTINGS, show_settings },
        { ACTION_NEW, action_create_new },
        { ACTION_TIMER, action_toggle_timer },
        { ACTION_SWITCH_PAGE_LEFT, action_switch_page_left },
        { ACTION_SWITCH_PAGE_RIGHT, action_switch_page_right }
    };

    /**
     * The constructor of the MainWindow class.
     */
    public MainWindow (
        Gtk.Application app_context, TaskTimer task_timer, TodoListInfo? initial_list
    ) {
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
        this.get_style_context ().add_class ("gofi_main_window");
        init_css ();
        Gtk.IconTheme.get_default ().add_resource_path (GOFI.RESOURCE_PATH + "/icons");

        load_initial (initial_list);

        list_manager.list_removed.connect (on_list_removed);

        task_page.notify["showing-timer"].connect (on_showing_timer_changed);
#if !NO_PLUGINS // vala-lint=skip
        var plugin_iface = plugin_manager.plugin_iface;
        plugin_iface.next_task.connect (on_plugin_iface_next_task);
        plugin_iface.previous_task.connect (on_plugin_iface_previous_task);
        plugin_iface.mark_task_as_done.connect (on_plugin_iface_mark_task_as_done);
        plugin_iface.quit_application.connect (on_plugin_iface_quit_application);
#endif // vala-lint=skip
    }

#if !NO_PLUGINS // vala-lint=skip
    private void on_plugin_iface_next_task () {
        task_page.switch_to_next ();
    }
    private void on_plugin_iface_previous_task () {
        task_page.switch_to_prev ();
    }
    private void on_plugin_iface_mark_task_as_done () {
        task_page.mark_task_done ();
    }
    private void on_plugin_iface_quit_application () {
        task_timer.stop ();
        this.close ();
    }
#endif // vala-lint=skip

    private void on_showing_timer_changed () {
        if (top_stack.visible_child != task_page) {
            return;
        }
        if (task_page.showing_timer) {
            list_menu_container.hide ();
            filter_item.sensitive = false;
        } else {
            list_menu_container.show ();
            filter_item.sensitive = true;
        }
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

    public void present_timer () {
        task_page.show_timer ();
        this.present ();
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

        gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = settings.use_dark_theme;

        settings.use_dark_theme_changed.connect (on_use_dark_theme_changed);
        Gtk.Settings.get_default ().notify["gtk-theme-name"].connect (load_css);
        settings.toolbar_icon_size_changed.connect (on_icon_size_changed);
    }

    private void on_use_dark_theme_changed (bool use_dark_theme) {
        gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme = use_dark_theme;
        load_css ();
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
        main_layout.get_style_context ().add_class ("main-layout");

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
        if (list_menu != null) {
            list_menu_container.pack_start (list_menu);
        }
    }

    private void setup_actions (Gtk.Application app) {
        var actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
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

        actions = new SimpleActionGroup ();
        foreach (var action in notification_service.create_actions ()) {
            actions.add_action (action);
        }
        insert_action_group (SOUND_ACTION_PREFIX, actions);
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
        menu_popover.get_style_context ().add_class ("menu");
#if !USE_GRANITE
        menu_container.margin = 10;
#endif
        menu_btn.popover = menu_popover;

        switch_img = new Gtk.Image.from_icon_name ("go-next", settings.toolbar_icon_size);
        switch_btn = new Gtk.ToolButton (switch_img, null);
        switch_btn.hexpand = false;
        switch_btn.sensitive = false;
        switch_btn.clicked.connect (toggle_top_stack);
        switch_btn.tooltip_text = SWITCH_BTN_LIST_TEXT;

        if (use_header_bar) {
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
            switch_btn.tooltip_text = SWITCH_BTN_LIST_TEXT;
            settings.list_last_loaded = null;
            task_page.show_switcher (false);
            list_menu_container.hide ();
            filter_item.sensitive = false;
        } else if (task_page.ready) {
            var current_list_info = task_page.shown_list.list_info;
            top_stack.set_visible_child (task_page);
            var prev_icon = GOFI.Utils.get_image_fallback ("go-previous-symbolic", "go-previous");
            switch_img.set_from_icon_name (prev_icon, settings.toolbar_icon_size);
            switch_btn.tooltip_text = SWITCH_BTN_OVERVIEW_TEXT;
            if (current_list_info != null) {
                settings.list_last_loaded = ListIdentifier.from_info (current_list_info);
            } else {
                settings.list_last_loaded = null;
            }
            task_page.show_switcher (true);
            if (!task_page.showing_timer) {
                list_menu_container.show ();
                filter_item.sensitive = true;
            }
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

        menu_container.add (create_menu_action_section ());

        menu_container.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        list_menu_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        list_menu_container.pack_end (
            new Gtk.Separator (Gtk.Orientation.HORIZONTAL)
        );

        menu_container.add (list_menu_container);

        var config_item = new Gtk.ModelButton ();
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

    /**
     * This part of the menu might not comply with the elementary or GNOME HIGs.
     * It at least doesn't look too strange so it will do for now.
     * If anyone has a better idea I'll be glad to hear it.
     */
    private Gtk.Widget create_menu_action_section () {
        var action_container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        // Button to mute/unmute notification sounds
        mute_item = new Gtk.Button ();
        mute_item.tooltip_text = _("Mute sounds");
        mute_item.action_name =
            SOUND_ACTION_PREFIX + "." + Notifications.KEY_MUTE_SOUND;
        mute_item_update_image ();
        mute_item.clicked.connect_after (mute_item_update_image);

        // Button to show/hide the search bar
        filter_item = new Gtk.Button ();
        var sc = kbsettings.get_shortcut (KeyBindingSettings.SCK_FILTER);
        filter_item.tooltip_markup = sc.get_accel_markup (_("Filter tasks"));
        filter_item.image = GOFI.Utils.load_image_fallback (
            Gtk.IconSize.MENU, "edit-find-symbolic", "edit-find"
        );
        filter_item.clicked.connect (on_filter_item_clicked);

        action_container.add (filter_item);
        action_container.add (mute_item);

        // Apply linked button styling
        mute_item.hexpand = true;
        filter_item.hexpand = true;
        action_container.get_style_context ().add_class ("linked");

#if USE_GRANITE
        action_container.margin = 12;
#else
        action_container.margin_bottom = 10;
#endif

        return action_container;
    }

    private void on_filter_item_clicked () {
        filter_fallback_action ();
    }

    private void mute_item_update_image () {
        if (notification_service.mute_sounds) {
            mute_item.image = GOFI.Utils.load_image_fallback (
                Gtk.IconSize.MENU, "audio-volume-muted-symbolic", "audio-volume-muted"
            );
        } else {
            mute_item.image = GOFI.Utils.load_image_fallback (
                Gtk.IconSize.MENU, "audio-volume-high-symbolic", "audio-volume-high"
            );
        }
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
        stylesheet_css = new Gtk.CssProvider ();

        load_css ();

        Gtk.StyleContext.add_provider_for_screen (
            screen, stylesheet_css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    /**
     * Is the stylesheet mostly using whites grays and blacks?
     */
    private bool has_neutral_stylesheet () {
        var desktop_theme_name = Gtk.Settings.get_default ().gtk_theme_name;
        if (desktop_theme_name.has_prefix ("io.elementary.stylesheet")) {
            return true;
        }
        switch (desktop_theme_name) {
            case "Arc":
            case "Adwaita":
            case "Breeze":
            case "elementary":
            case "Pop-light":
            case "Pop-slim-light":
                return true;
            default:
                return false;
        }
    }

    /**
     * Load the css style information from the data directory specified at build
     * time.
     */
    private void load_css () {
        string stylesheet = "safe-colors";
        if (has_neutral_stylesheet ()) {
            if (settings.use_dark_theme) {
                stylesheet = "dark";
            } else {
                stylesheet = "light";
            }
        }

        // Pick the stylesheet that is compatible with the user's Gtk version
        if (Gtk.get_minor_version () >= 19) {
            stylesheet = stylesheet + "-3.20.css";
        } else {
            stylesheet = stylesheet + "-3.10.css";
        }

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
