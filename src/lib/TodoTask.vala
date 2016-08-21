/* Copyright 2016 Go For It! developers
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
 * This class stores all task information that should be known to the timer.
 */
public class GOFI.TodoTask : GLib.Object {
    public Gtk.TreeRowReference reference {
        public get;
        public set;
    }
    
    public string title {
        public get;
        public set;
    }
    
    public bool valid {
        public get {
            return reference.valid ();
        }
    }
    
    public TodoTask (Gtk.TreeRowReference reference) {
        this.reference = reference;
        this.title = GOFI.Utils.tree_row_ref_to_task (reference);
    }
}
