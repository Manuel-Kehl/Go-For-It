/* Copyright 2014 Manuel Kehl (mank319)
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
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
 * The widget for selecting, displaying and controlling the active task.
 */
public class AboutDialog : Gtk.Dialog {
    /* GTK Widgets */
    private Gtk.Label content_lbl;
    
    public AboutDialog () {
        /* Initalization */
        
        /* General Settigns */
        this.set_default_size (450, 500);
        this.get_content_area ().margin = 10;
        this.title = "About";
        setup_content ();
        
        /* Close Button */
        this.add_button ("Close", Gtk.ResponseType.CLOSE);
        /* Action Handling */
        this.response.connect ((s, response) => {
            if (response == Gtk.ResponseType.CLOSE) {
                this.destroy ();
            }
        });
    }
    
    /** 
     * Displays a welcome message with basic information about Go For It!
     */
    private void setup_content () {
        content_lbl = new Gtk.Label (
"""<b>About</b>

<a href="http://manuel-kehl.de/projects/go-for-it">Website</a>

<i>Go For It!</i> is a stylish to-do list with built-in productivity timer.

For developing new features and keeping the project running,
I rely on your <a href="https://github.com/mank319/Go-For-It">contributions</a> and <a href="http://manuel-kehl.de/donations">donations</a>.

Thank you!


<b>Contributors</b>

- <a href="http://manuel-kehl.de">Manuel Kehl (mank319)</a> - Concept and Development

- <a href="http://traumad91.deviantart.com">Micah Ilbery (TraumaD91)</a> - Icon Design
""");
        
        /* Configuration */
        content_lbl.set_use_markup (true);
        content_lbl.set_line_wrap (false);
        content_lbl.halign = Gtk.Align.START;
        content_lbl.visible = true;
        
        /* Add widget */
        this.get_content_area ().add (content_lbl);
    }
}
