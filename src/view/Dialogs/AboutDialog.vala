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
 * A dialog for displaying information about this application.
 */
class GOFI.AboutDialog : Gtk.AboutDialog {
    public AboutDialog (Gtk.Window? parent = null) {
        this.set_transient_for (parent);
        /* Initalization */
        this.set_default_size (450, 500);
        this.get_content_area ().margin = 10;
        this.title = _("About") + " Go For It!";
        setup_content ();

        /* Action Handling */
        this.response.connect (response_handler);
    }

    /**
     * Displays a welcome message with basic information about Go For It!
     */
    private void setup_content () {
        program_name = "Go For It!";
        logo_icon_name = GOFI.ICON_NAME;

        comments = _("A stylish to-do list with built-in productivity timer.");
        website = GOFI.PROJECT_WEBSITE;
        version = GOFI.APP_VERSION;

        license_type = Gtk.License.GPL_3_0;

        authors = {
            "Jonathan Moerman",
            "<a href='http://manuel-kehl.de'>Manuel Kehl</a>"
        };
        artists = { "<a href='http://traumad91.deviantart.com'>Micah Ilbery</a>" };
    }

    private void response_handler (int response) {
        if (response == Gtk.ResponseType.DELETE_EVENT
            || response == Gtk.ResponseType.CANCEL
            || response == Gtk.ResponseType.CLOSE) {
            this.destroy ();
        }
    }
}
