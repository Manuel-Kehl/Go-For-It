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
 * The main application class that is responsible for initiating all
 * necessary steps to create a running instance of "Just Do It!".
 */
public class Main : Gtk.Application {
    /**
     * Constructor of the Application class.
     */
    private Main () {
        Object (application_id: JDI.APP_ID, flags: ApplicationFlags.FLAGS_NONE);
        set_inactivity_timeout (10000);
    }
    
    /**
     * The entry point for running the application.
     */
    public static int main (string[] args) {
        Main app = new Main ();
        int status = app.run (args);
        return status;
    }
    
    public override void activate () {
        // Don't create a new window, if one already exists
        if (this.active_window != null) {
            // Highlight the existing window instead
            this.active_window.present ();
            return;
        }
        
        // Read the user's configuration file
        KeyFile settings = read_user_config ();
        
        try {
            //Get relevant settings from configuration file
            var dir = File.new_for_path (settings.get_value(
                JDI.CONF_GROUP_TODO_TXT,
                JDI.CONF_TODO_TXT_LOCATION
            ));
            
            /* Instantiation of the Core Classes of the Application */
            var task_manager = new TaskManager(dir);
            var win = new MainWindow (this, task_manager);
            
        } catch (Error e) {
            // Basically the only reason for this try/catch is the suppression
            // of warnings.If an error has not been caught until this point,
            // e.g.in read_user_config (), it is "too late" anyways.
            error ("%s", e.message);
        }
    }
    
    /**
     * Reads the user's configuration file and creates it, if necessary.
     */
    private KeyFile read_user_config () {
        string config_dir = Environment.get_user_config_dir ();
        string config_file = Path.build_filename (config_dir, JDI.FILE_CONF);
        
        // Create config file if it does not exist yet
        if (!FileUtils.test (config_file, FileTest.EXISTS)) {
            create_default_conf_file();
        }
        
        try {
            var settings = new KeyFile ();
            settings.load_from_file (config_file,
                KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            return settings;
        } catch (Error e) {
            stderr.printf("Reading settings from '" + config_file + "' failed.");
            error ("%s", e.message);
        }
    }

    /**
     * Creates a default configuration file in the corresponding subdirectory of 
     * the user's home directory. It also tries to automatically determine the 
     * location of the user's Todo.txt directory, by checking a set of 
     * common potential "standard locations". 
     * Such test directories can be appended to JDI.TEST_DIRS in Utils.vala.
     */
    private void create_default_conf_file () {
        string user_dir = Environment.get_home_dir ();
        string config_dir = Environment.get_user_config_dir ();
        string config_file = Path.build_filename (config_dir, JDI.FILE_CONF);
        
        /* Determine the Todo.txt Directory */
        // Start by setting the default fallback directory
        var todo_dir = Path.build_filename (user_dir, JDI.TEST_DIRS[0]);
        
        // Try a set of possible "standard locations"
        foreach (var test_sub_dir in JDI.TEST_DIRS) {
            var test_dir = Path.build_filename (user_dir, test_sub_dir);
            if (FileUtils.test (test_dir, FileTest.EXISTS)) {
                todo_dir = test_dir;
                break;
            }
        }
        
        // Create the actual configuration file
        var settings = new KeyFile ();
        settings.set_value (
            JDI.CONF_GROUP_TODO_TXT,
            JDI.CONF_TODO_TXT_LOCATION,
            todo_dir
        );
        
        try {
            settings.save_to_file(config_file);
        } catch (Error e) {
            error ("%s", e.message);
        }
    }
}
