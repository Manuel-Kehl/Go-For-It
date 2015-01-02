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
 * This class is basically a temporary hack to mimic the mechanics of
 * notifications on Windows. Hopefully Glib.Notification will work natively
 * some day. Until then, this gets the job done.
 */
public class WinNotification : Gtk.Dialog {
    public WinNotification (string title, string message) {
        /* Window Settings */
        this.decorated = false;
        this.has_resize_grip = false;
        this.set_default_size (200, 30);
        this.title = title;
        this.accept_focus = false;
        this.can_focus = false;
        this.set_keep_above (true);
        
        // Add content to the widget
        var title_lbl = new Gtk.Label (@"<b>$title</b>");
        var message_lbl = new Gtk.Label (message);
        //title_lbl.visible = true;
        title_lbl.use_markup = true;
        message_lbl.visible = true;
        message_lbl.wrap = true;
        this.get_content_area ().pack_start (title_lbl, false, true, 10);
        this.get_content_area ().pack_start (message_lbl, false, true, 10);

        /* Action Handling */
        //ponse.connect (response_handler);
    }
    
    /**
     * Displays the "notification"
     */
    public void send () {
        this.show_all ();
        this.move (7, 7);
        /*
         * This code waits 3 seconds and closes the dialog afterwards.
         * iteration_flag is for ensuring, that at least one iteration is 
         * made before this.close () is called.
         */
        var iteration_flag = false;
        Timeout.add_full (Priority.DEFAULT, 3000, () => {
            if (iteration_flag) {
                this.close ();
            }
            iteration_flag = true;
            return true;
        });
    }
}
