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

using GOFI.DialogUtils;

class GOFI.AppearancePage : Gtk.Grid {

    public AppearancePage () {
        int row = 0;
        add_general_appearance_sect (ref row);
        add_theme_section (ref row);
        apply_grid_spacing (this);
    }

    private void add_general_appearance_sect (ref int row) {
        Gtk.Label general_sect_lbl;
        Gtk.Label small_icons_lbl;
        Gtk.Switch small_icons_switch;
        Gtk.Label switch_app_lbl;
        Gtk.ComboBoxText switch_app_selector;

        /* Instantiation */
        general_sect_lbl = new Gtk.Label (_("General"));

        small_icons_lbl = new Gtk.Label (_("Use small toolbar icons") + ":");
        small_icons_switch = new Gtk.Switch ();

        switch_app_lbl = new Gtk.Label (_("Appearance of the activity switcher") + ":");
        switch_app_selector = new Gtk.ComboBoxText ();

        /* Configuration */
        small_icons_switch.active = settings.use_small_toolbar_icons;

        switch_app_selector.append ("icons", _("Icons"));
        switch_app_selector.append ("text", _("Text"));
        switch_app_selector.active_id =
            settings.switcher_use_icons ? "icons" : "text";

        /* Signal Handling */
        switch_app_selector.changed.connect ( () => {
            settings.switcher_use_icons =
                switch_app_selector.active_id == "icons";
        });

        small_icons_switch.notify["active"].connect ( () => {
            settings.use_small_toolbar_icons = small_icons_switch.active;
        });

        /* Add widgets */
        add_section (this, general_sect_lbl, ref row);
        add_option (this, small_icons_lbl, small_icons_switch, ref row);
        add_option (this, switch_app_lbl, switch_app_selector, ref row);
        if (GOFI.Utils.desktop_hb_status.config_useful ()) {
            add_csd_settings_widgets (this, ref row);
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
            if (dark_theme_switch.active) {
                settings.color_scheme = ColorScheme.DARK;
            } else {
                settings.color_scheme = ColorScheme.LIGHT;
            }
        });
        theme_selector.changed.connect ( () => {
            settings.theme = Theme.from_string (theme_selector.active_id);
        });

        add_section (this, theme_sect_lbl, ref row);
        add_option (this, theme_lbl, theme_selector, ref row);
        add_option (this, dark_theme_lbl, dark_theme_switch, ref row);
    }

    private void add_csd_settings_widgets (Gtk.Grid grid, ref int row) {
        Gtk.Label headerbar_lbl;
        Gtk.Label restart_info_lbl;
        Gtk.Switch headerbar_switch;

        string restart_info = _("%s needs to be restarted for this setting to take effect").printf (APP_NAME);

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
