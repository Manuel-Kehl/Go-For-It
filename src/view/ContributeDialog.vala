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
 * A dialog that displays information about how to support the project.
 */
public class ContributeDialog : Gtk.MessageDialog {
    /* GTK Widgets */
    public ContributeDialog (Gtk.Window? parent) {
        Object (buttons: Gtk.ButtonsType.OK);
        this.message_type = Gtk.MessageType.INFO;
        this.set_modal (true);
        this.title = _("Contributions and Donations");

        this.format_secondary_markup (
        "<b>" + _("Thank you for supporting") + " <i>Go For It!</i>\n\n\n</b>"
        + _("Submitting code, artwork, translations or documentation is a great way of contributing to the project:")
        + "\n\n"
        + "<a href=\"" + GOFI.PROJECT_REPO + "\">" + GOFI.PROJECT_REPO + "</a>"
        + "\n\n\n"
        +_("Donations give me a chance to dedicate more time towards implementing new features:")
        + "\n\n"
        + "<a href=\"" + GOFI.PROJECT_DONATIONS + "\">" + GOFI.PROJECT_DONATIONS
        + "</a>"
        );

        this.response.connect ((e) => {
            this.destroy ();
        });

        this.get_action_area ().hexpand = false;
        this.get_action_area ().halign = Gtk.Align.END;
        this.set_transient_for (parent);
    }
}
