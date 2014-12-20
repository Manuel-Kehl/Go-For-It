/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Just Do It!.
*
* Just Do It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Just Do It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Just Do It!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * The JDI namespace is a central collection of static constants that are 
 * realted to "Just Do it!".
 */
namespace JDI {
    /* Strings */
    const string APP_NAME = "Just Do It!";
    const string APP_SYSTEM_NAME = "just-do-it";
    const string APP_ID = "de.manuel-kehl.just-do-it";
    const string FILE_CONF = "just-do-it.conf";
    const string[] TEST_DIRS = {
        "Todo", "todo", ".todo", 
        "Dropbox/Todo", "Dropbox/todo"
    };
    
    /* Numeric Values */
    const int DEFAULT_WIN_WIDTH = 350;
    const int DEFAULT_WIN_HEIGHT = 700;
    
    /** 
     * A collection of static utility functions.
     */
    class Utils {
        // A convenient way to get the path of JDI's configuration file
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
    }
}
