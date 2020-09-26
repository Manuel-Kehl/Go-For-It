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

/**
 * A dialog for changing the application's settings.
 */
class GOFI.SettingsDialog : Gtk.Dialog {
    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private BehaviorPage timer_page;
    private AppearancePage appearance_page;
    private ShortcutsPage shortcuts_page;
    private Gtk.StackSwitcher stack_switcher;
    private Gtk.Stack settings_stack;

    public SettingsDialog (Gtk.Window? parent) {
        this.set_transient_for (parent);
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

        timer_page = new BehaviorPage ();
        appearance_page = new AppearancePage ();
        shortcuts_page = new ShortcutsPage ();

        settings_stack.add_titled (timer_page, "behavior_page", _("Behavior"));
        settings_stack.add_titled (appearance_page, "appearance_page", _("Appearance"));
        settings_stack.add_titled (shortcuts_page, "shortcuts_page", _("Shortcuts"));
        settings_stack.add_titled (plugin_manager.get_settings_widget (), "plugins_page", _("Plugins"));

        main_layout.add(stack_switcher);
        main_layout.add(settings_stack);
    }
}
