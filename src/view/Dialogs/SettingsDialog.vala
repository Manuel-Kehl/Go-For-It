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

/**
 * A dialog for changing the application's settings.
 */
class GOFI.SettingsDialog : Gtk.Dialog {
    private SettingsManager settings;
    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Grid timer_page;
    private Gtk.Grid appearance_page;
    private Gtk.StackSwitcher stack_switcher;
    private Gtk.Stack settings_stack;

    public SettingsDialog (Gtk.Window? parent, SettingsManager settings) {
        this.set_transient_for (parent);
        this.settings = settings;
        /* Initalization */
        main_layout = new Gtk.Grid ();

        /* General Settigns */
        // Default to minimum possible size
        this.set_default_size (1, 1);
        this.get_content_area ().margin = 10;
        this.get_content_area ().pack_start (main_layout);
        this.set_modal (true);
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        main_layout.row_spacing = 10;

        this.title = _("Settings");
        setup_settings_widgets ();
        this.add_button (_("Close"), Gtk.ResponseType.CLOSE);

        /* Action Handling */
        this.response.connect ((s, response) => {
            if (response == Gtk.ResponseType.CLOSE) {
                this.destroy ();
            }
        });

        this.show_all ();
    }

    private void setup_settings_widgets () {
        settings_stack = new Gtk.Stack ();
        stack_switcher = new Gtk.StackSwitcher ();

        stack_switcher.stack = settings_stack;
        stack_switcher.halign = Gtk.Align.CENTER;

        setup_timer_settings_widgets ();
        setup_appearance_settings_widgets ();

        settings_stack.add_titled (timer_page, "timer_page", _("Timer"));
        settings_stack.add_titled (appearance_page, "appearance_page", _("Appearance"));

        main_layout.add(stack_switcher);
        main_layout.add(settings_stack);
    }

    private void add_section (Gtk.Grid grid, Gtk.Label label, ref int row) {
        label.set_markup ("<b>%s</b>".printf (label.get_text ()));
        label.halign = Gtk.Align.START;

        grid.attach (label, 0, row, 2, 1);
        row++;
    }

    private void add_option (Gtk.Grid grid, Gtk.Widget label,
                             Gtk.Widget switcher, ref int row, int indent=1)
    {
        label.hexpand = true;
        label.margin_start = indent * 20; // indentation relative to the section label
        label.halign = Gtk.Align.START;

        switcher.hexpand = true;
        switcher.halign = Gtk.Align.FILL;

        if (switcher is Gtk.Switch || switcher is Gtk.Entry) {
            switcher.halign = Gtk.Align.START;
        }

        grid.attach (label, 0, row, 1, 1);
        grid.attach (switcher, 1, row, 1, 1);
        row++;
    }

    private void add_explanation (Gtk.Grid grid, Gtk.Label label, ref int row) {
        label.hexpand = true;
        label.margin_start = 20; // indentation relative to the section label
        label.halign = Gtk.Align.START;

        grid.attach (label, 0, row, 2, 1);
        row++;
    }

    private Gtk.Grid create_page_grid () {
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 10;
        return grid;
    }

    private void setup_timer_settings_widgets () {
        /* Declaration */
        Gtk.Label task_lbl;
        Gtk.SpinButton task_spin;
        Gtk.Label break_lbl;
        Gtk.SpinButton break_spin;
        Gtk.Label reminder_lbl;
        Gtk.SpinButton reminder_spin;

        /* Instantiation */
        timer_page = create_page_grid ();

        task_lbl = new Gtk.Label (_("Task duration (minutes)") + ":");
        break_lbl = new Gtk.Label (_("Break duration (minutes)") + ":");
        reminder_lbl = new Gtk.Label (_("Reminder before task ends (seconds)") +":");

        // No more than one day: 60 * 24 -1 = 1439
        task_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        // More than ten minutes would not make much sense
        reminder_spin = new Gtk.SpinButton.with_range (0, 600, 1);

        /* Configuration */
        task_spin.value = settings.task_duration / 60;
        break_spin.value = settings.break_duration / 60;
        reminder_spin.value = settings.reminder_time;

        /* Signal Handling */
        task_spin.value_changed.connect ((e) => {
            settings.task_duration = task_spin.get_value_as_int () * 60;
        });
        break_spin.value_changed.connect ((e) => {
            settings.break_duration = break_spin.get_value_as_int () * 60;
        });
        reminder_spin.value_changed.connect ((e) => {
            settings.reminder_time = reminder_spin.get_value_as_int ();
        });

        /* Add widgets */
        int row = 0;
        add_option (timer_page, task_lbl, task_spin, ref row, 0);
        add_option (timer_page, break_lbl, break_spin, ref row, 0);
        add_option (timer_page, reminder_lbl, reminder_spin, ref row, 0);
    }

    private void setup_appearance_settings_widgets () {
        appearance_page = create_page_grid ();

        int row = 0;
        add_general_appearance_sect (ref row);
        add_theme_section (ref row);
    }

    private void add_general_appearance_sect (ref int row) {
        Gtk.Label general_sect_lbl;
        Gtk.Label small_icons_lbl;
        Gtk.Switch small_icons_switch;
        Gtk.Label use_text_lbl;
        Gtk.Switch use_text_switch;

        /* Instantiation */
        general_sect_lbl = new Gtk.Label (_("General"));

        small_icons_lbl = new Gtk.Label (_("Use small toolbar icons") + ":");
        small_icons_switch = new Gtk.Switch ();

        use_text_lbl = new Gtk.Label (_("Use text for the activity switcher") + ":");
        use_text_switch = new Gtk.Switch ();

        /* Configuration */
        small_icons_switch.active =
            settings.toolbar_icon_size == Gtk.IconSize.SMALL_TOOLBAR;
        use_text_switch.active = !settings.switcher_use_icons;

        /* Signal Handling */
        small_icons_switch.notify["active"].connect ( () => {
            if (small_icons_switch.active) {
                settings.toolbar_icon_size = Gtk.IconSize.SMALL_TOOLBAR;
            } else {
                settings.toolbar_icon_size = Gtk.IconSize.LARGE_TOOLBAR;
            }
        });
        use_text_switch.notify["active"].connect ( () => {
            settings.switcher_use_icons = !use_text_switch.active;
        });

        small_icons_switch.notify["active"].connect ( () => {
            if (small_icons_switch.active) {
                settings.toolbar_icon_size = Gtk.IconSize.SMALL_TOOLBAR;
            } else {
                settings.toolbar_icon_size = Gtk.IconSize.LARGE_TOOLBAR;
            }
        });

        /* Add widgets */
        add_section (appearance_page, general_sect_lbl, ref row);
        add_option (appearance_page, small_icons_lbl, small_icons_switch, ref row);
        add_option (appearance_page, use_text_lbl, use_text_switch, ref row);
        if (GOFI.Utils.desktop_hb_status.config_useful ()) {
            add_csd_settings_widgets (appearance_page, ref row);
        }
    }

    private void add_theme_section (ref int row) {
        Gtk.Label theme_sect_lbl;
        Gtk.Label dark_theme_lbl;
        Gtk.Label theme_lbl;
        Gtk.Switch dark_theme_switch;
        Gtk.ComboBoxText theme_selector;

        /* Instantiation */
        theme_sect_lbl = new Gtk.Label (_("Theme"));
        dark_theme_lbl = new Gtk.Label (_("Dark theme") + ":");
        theme_lbl = new Gtk.Label (_("Theme") + ":");
        dark_theme_switch = new Gtk.Switch ();
        theme_selector = new Gtk.ComboBoxText ();

        /* Configuration */
        dark_theme_switch.active = settings.use_dark_theme;
        foreach (Theme theme in Theme.all ()) {
            theme_selector.append (theme.to_string (), theme.to_theme_description ());
        }
        theme_selector.active_id = settings.theme.to_string ();

        /* Signal Handling */
        dark_theme_switch.notify["active"].connect ( () => {
            settings.use_dark_theme = dark_theme_switch.active;
        });
        theme_selector.changed.connect ( () => {
            settings.theme = Theme.from_string (theme_selector.active_id);
        });

        add_section (appearance_page, theme_sect_lbl, ref row);
        add_option (appearance_page, theme_lbl, theme_selector, ref row);
        add_option (appearance_page, dark_theme_lbl, dark_theme_switch, ref row);
    }

    private void add_csd_settings_widgets (Gtk.Grid grid, ref int row) {
        Gtk.Label headerbar_lbl;
        Gtk.Label restart_info_lbl;
        Gtk.Switch headerbar_switch;

        string restart_info = _("Go For It! needs to be restarted for this setting to take effect");

        /* Instantiation */
        headerbar_lbl = new Gtk.Label (_("Use a header bar") + ":");
        restart_info_lbl = new Gtk.Label (@"<i>$restart_info</i>:");
        headerbar_switch = new Gtk.Switch ();

        /* Configuration */
        headerbar_switch.active = settings.use_header_bar;
        restart_info_lbl.use_markup = true;

        /* Signal Handling */
        headerbar_switch.notify["active"].connect ( () => {
            settings.use_header_bar = headerbar_switch.active;
        });

        /* Add widgets */
        add_explanation (grid, restart_info_lbl, ref row);
        add_option (grid, headerbar_lbl, headerbar_switch, ref row, 2);
    }
}
