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

class GOFI.AppearancePage : Gtk.Box {

    public AppearancePage () {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 12);
        this.add (create_general_appearance_sect ());
        this.add (create_theme_section ());
    }

    private Gtk.Widget create_general_appearance_sect () {
        var small_icons_lbl = new Gtk.Label (_("Use small toolbar icons") + ":");
        var small_icons_switch = new Gtk.Switch ();
        small_icons_switch.active = settings.use_small_toolbar_icons;
        small_icons_switch.notify["active"].connect ( () => {
            settings.use_small_toolbar_icons = small_icons_switch.active;
        });

        var switch_app_lbl = new Gtk.Label (_("Appearance of the activity switcher") + ":");
        var switch_app_selector = new Gtk.ComboBoxText ();
        switch_app_selector.append ("icons", _("Icons"));
        switch_app_selector.append ("text", _("Text"));
        switch_app_selector.active_id =
            settings.switcher_use_icons ? "icons" : "text";
        switch_app_selector.changed.connect ( () => {
            settings.switcher_use_icons =
                switch_app_selector.active_id == "icons";
        });

        int pos = 0;
        var general_grid = create_page_grid ();
        add_option (general_grid, ref pos, small_icons_lbl, small_icons_switch);
        add_option (general_grid, ref pos, switch_app_lbl, switch_app_selector);
        if (GOFI.Utils.desktop_hb_status.config_useful ()) {
            string restart_info = _("%s needs to be restarted for this setting to take effect").printf (APP_NAME);
            var headerbar_lbl = new Gtk.Label (_("Use a header bar") + ":");
            var restart_info_widget = get_explanation_widget (restart_info);
            var headerbar_switch = new Gtk.Switch ();

            /* Configuration */
            headerbar_switch.active = settings.use_header_bar;

            /* Signal Handling */
            headerbar_switch.notify["active"].connect ( () => {
                settings.use_header_bar = headerbar_switch.active;
            });

            /* Add widgets */
            add_option (general_grid, ref pos, headerbar_lbl, headerbar_switch, restart_info_widget);
        }
        return create_section_box (_("General"), general_grid);
    }

    private Gtk.Widget create_theme_section () {
        var color_scheme_lbl = new Gtk.Label (_("Color scheme") + ":");
        var color_scheme_selector = new Gtk.ComboBoxText ();
        foreach (ColorScheme cs in ColorScheme.all ()) {
            color_scheme_selector.append (cs.to_string (), cs.get_description ());
        }
        color_scheme_selector.active_id = settings.color_scheme.to_string ();
        color_scheme_selector.changed.connect ( () => {
            settings.color_scheme = ColorScheme.from_string (color_scheme_selector.active_id);
        });

        int pos = 0;
        var theme_grid = create_page_grid ();
        add_option (theme_grid, ref pos, color_scheme_lbl, color_scheme_selector);

        if (!(Gtk.Settings.get_default ().gtk_theme_name == "elementary") || settings.theme != Theme.ELEMENTARY) {
            var theme_lbl = new Gtk.Label (_("Theme") + ":");
            var theme_selector = new Gtk.ComboBoxText ();
            foreach (Theme theme in Theme.all ()) {
                theme_selector.append (theme.to_string (), theme.to_theme_description ());
            }
            theme_selector.active_id = settings.theme.to_string ();
            theme_selector.changed.connect ( () => {
                settings.theme = Theme.from_string (theme_selector.active_id);
            });

            add_option (theme_grid, ref pos, theme_lbl, theme_selector);
        }
        return create_section_box (_("Theme"), theme_grid);
    }
}
