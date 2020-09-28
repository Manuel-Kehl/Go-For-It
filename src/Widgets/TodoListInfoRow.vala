/* Copyright 2018-2019 Go For It! developers
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

class GOFI.TodoListInfoRow: DragListRow {
    private Gtk.Label name_label;
    private bool showing_menu;

    private Gtk.Revealer option_revealer;
    private Gtk.ToggleButton options_button;
    private Gtk.EventBox event_box;
    private Gtk.Box center_box;
    private Gtk.Popover popover;

    public TodoListInfo info {
        get;
        private set;
    }

    public signal void delete_clicked (TodoListInfo info);
    public signal void edit_clicked (TodoListInfo info);

    public TodoListInfoRow (TodoListInfo info) {
        this.info = info;

        event_box = new Gtk.EventBox ();
        center_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
        option_revealer = new Gtk.Revealer ();

        option_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;

        name_label = new Gtk.Label (info.name);
        name_label.hexpand = true;

        options_button = new Gtk.ToggleButton ();
        options_button.add (GOFI.Utils.load_image_fallback (
            Gtk.IconSize.MENU, "edit-symbolic", "edit",
            "document-edit-symbolic", "view-more-symbolic"
        ));
        options_button.relief = Gtk.ReliefStyle.NONE;
        var style = options_button.get_style_context ();
        style.add_class ("no_margin");

        option_revealer.add (options_button);
        center_box.set_center_widget (name_label);
        center_box.pack_end (option_revealer, false);
        event_box.add (center_box);

        set_center_widget (event_box);

        connect_signals ();
        show_all ();
    }

    private void connect_signals () {
        info.notify["name"].connect (update);

        options_button.toggled.connect (on_options_button_toggled);

        event_box.enter_notify_event.connect ( (event) => {
            option_revealer.reveal_child = true;
            return false;
        });
        event_box.leave_notify_event.connect ( (event) => {
            if (event.detail != Gdk.NotifyType.INFERIOR && !showing_menu) {
                option_revealer.reveal_child = false;
            }
            return false;
        });
    }

    private void on_options_button_toggled () {
        if (showing_menu) {
            return;
        }
        showing_menu = true;
        popover = new Gtk.Popover (options_button);
        popover.position = Gtk.PositionType.BOTTOM;

        var popover_cont = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        var menuitem_delete = Utils.create_menu_button (_("Delete"));
        var menuitem_edit = Utils.create_menu_button (_("Edit"));

        menuitem_delete.clicked.connect (on_menuitem_delete_clicked);
        menuitem_edit.clicked.connect (on_menuitem_edit_clicked);

        popover_cont.add (menuitem_edit);
        popover_cont.add (menuitem_delete);
        popover.add (popover_cont);
        Utils.popover_show (popover);

        popover.hide.connect (on_popover_hidden);
    }

    private void on_popover_hidden () {
        option_revealer.reveal_child = false;
        options_button.active = false;

        GLib.Idle.add (on_popover_animation_finished);
    }

    private bool on_popover_animation_finished () {
        showing_menu = false;
        popover.destroy ();
        popover = null;
        return GLib.Source.REMOVE;
    }

    private void on_menuitem_delete_clicked () {
        delete_clicked (this.info);
        if (popover != null) {
            Utils.popover_hide (popover);
        }
    }

    private void on_menuitem_edit_clicked () {
        edit_clicked (this.info);
        if (popover != null) {
            Utils.popover_hide (popover);
        }
    }

    private void update () {
        name_label.label = info.name;
    }
}
