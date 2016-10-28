/* Copyright 2014-2016 Go For It! developers
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
 * A collection of static utility functions.
 */
class GOFI.Plugins.TodoTXT.Utils {
    // A convenient way to get the path of GOFI's configuration file
    // TODO: remove this
    public static string config_file {
        owned get {
            string config_dir = Environment.get_user_config_dir ();
            return Path.build_filename (config_dir, "go-for-it.conf");
        }
        private set {}
    }

    public static string tree_row_ref_to_task (Gtk.TreeRowReference reference) {
        // Get Gtk.TreeIterator from reference
        var path = reference.get_path ();
        var model = reference.get_model ();
        Gtk.TreeIter iter;
        model.get_iter (out iter, path);
        
        string description;
        model.get (iter, 1, out description, -1);
        return description;
    }
    
    public static bool iter_to_reference (Gtk.TreeModel model, Gtk.TreeIter iter, out Gtk.TreeRowReference reference) {
        var path = model.get_path (iter);
        reference = null;
        
        if (path != null) {
            reference = new Gtk.TreeRowReference (model, path);
            return true;
        }
        
        return false;
    }
}
