/* Copyright 2014 Manuel Kehl (mank319)
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
 * The GOFI namespace is a central collection of static constants that are 
 * realted to "Go For It!".
 */
namespace GOFI {
    /* Strings */
    const string APP_NAME = "Go For It!";
    const string APP_SYSTEM_NAME = "go-for-it";
    const string APP_ID = "de.manuel-kehl.go-for-it";
    const string APP_VERSION = "1.4.6";
    const string FILE_CONF = "go-for-it.conf";
    const string PROJECT_WEBSITE = "http://manuel-kehl.de/projects/go-for-it/";
    const string PROJECT_REPO = "https://github.com/mank319/Go-For-It";
    const string PROJECT_DONATIONS = "http://manuel-kehl.de/donations/";
    const string[] TEST_DIRS = {
        "Todo", "todo", ".todo", 
        "Dropbox/Todo", "Dropbox/todo"
    };
    
    /** 
     * A collection of static utility functions.
     */
    class Utils {
        // A convenient way to get the path of GOFI's configuration file
        public static string config_file {
            owned get {
                string config_dir = Environment.get_user_config_dir ();
                return Path.build_filename (config_dir, FILE_CONF);
            }
            private set {}
        }
        
        public static string tree_row_ref_to_task (
                Gtk.TreeRowReference reference) {
            // Get Gtk.TreeIterator from reference
            var path = reference.get_path ();
            var model = reference.get_model ();
            Gtk.TreeIter iter;
            model.get_iter (out iter, path);
            
            string description;
            model.get (iter, 1, out description, -1);
            return description;
        }
        
        /**
         * Loads the first icon in the list, which is contained in the 
         * active icon theme. This way one can avoid the "broken image" icon
         * by offering a list of fallback icon names.
         */
        public static Gtk.Image load_image_fallback (Gtk.IconSize size, 
                string icon_name, ...) {
            Gtk.Image result = new Gtk.Image.from_icon_name (icon_name, size);
            // If icon_name is present, simply return the related image
            if (Gtk.IconTheme.get_default ().has_icon (icon_name)) {
                return result;
            }
            
            // Iterate through the list of fallbacks, if icon_name was not found
            var fallbacks = va_list();
            while (true) {
                string? fallback_name = fallbacks.arg();
                if (fallback_name == null) {
                    // end of the varargs list without a matching fallback
                    // in this case the "broken image" icon is returned
                    return result; 
                }
                
                // If fallback is found, return the related image
                if (Gtk.IconTheme.get_default ().has_icon (fallback_name)) {
                    return new Gtk.Image.from_icon_name (fallback_name, size);
                }
            }
        }
    }
}
