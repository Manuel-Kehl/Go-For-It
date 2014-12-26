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
 * A class that handles access to settings in a transparent manner.
 * Its main motivation is the option of easily replacing Glib.KeyFile with 
 * another settings storage mechanism in the future.
 */
public class SettingsManager {
    private KeyFile key_file;
    
    /*
     * A list of constants that define settings group names
     */
     
     private const string GROUP_TODO_TXT = "Todo.txt";
     private const string GROUP_TIMER = "Timer";
    
    /*
     * A list of settings values with their corresponding access methods.
     * The "heart" of the SettingsManager class.
     */
     
     /*---GROUP:Todo.txt------------------------------------------------------*/
     public string todo_txt_location {
        owned get { return get_value (GROUP_TODO_TXT, "location"); }
        set {
            set_value (GROUP_TODO_TXT, "location", value); 
            todo_txt_location_changed ();
        }
     }
     /*---GROUP:Timer---------------------------------------------------------*/
     public int task_duration {
        owned get {
            var duration = get_value (GROUP_TIMER, "task_duration", "1500");
            return int.parse (duration);
        }
        set {
            set_value (GROUP_TIMER, "task_duration", value.to_string ());
            timer_duration_changed ();
        }
     }
     public int break_duration {
        owned get {
            var duration = get_value (GROUP_TIMER, "break_duration", "300");
            return int.parse (duration);
        }
        set {
            set_value (GROUP_TIMER, "break_duration", value.to_string ());
            timer_duration_changed ();
        }
     }
     
     public signal void todo_txt_location_changed ();
     public signal void timer_duration_changed ();
    
    /**
     * Constructs a SettingsManager object from a configuration file.
     * Reads the corresponding file and creates it, if necessary.
     */
    public SettingsManager.load_from_key_file () {
        // Instantiate the key_file object
        key_file = new KeyFile ();
        
        if (!FileUtils.test (GOFI.Utils.config_file, FileTest.EXISTS)) {
            // Fill with default values, if it does not exist yet
            generate_configuration ();
            var dia = new SettingsDialog (true, this);
            dia.show ();
        } else {
            // If it does exist, read existing values
            try {
                key_file.load_from_file (GOFI.Utils.config_file,
                   KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (Error e) {
                stderr.printf("Reading %s failed", GOFI.Utils.config_file);
                error ("%s", e.message);
            }
        }
    }
    
    /**
     * Provides read access to a setting, given a certain group and key.
     * Public access is granted via the SettingsManager's attributes, so this
     * function has been declared private
     */
    private string get_value (string group, string key, string default = "") {
        try {
            // use key_file, if it has been assigned
            if (key_file != null
                && key_file.has_group (group)
                && key_file.has_key (group, key)) {
                    return key_file.get_value(group, key);
            } else {
                return default;
            }
        } catch (Error e) {
                error ("An error occured while reading the setting"
                    +" %s.%s: %s", group, key, e.message);
        }
    }
    
    /**
     * Provides write access to a setting, given a certain group key and value.
     * Public access is granted via the SettingsManager's attributes, so this
     * function has been declared private
     */
    private void set_value (string group, string key, string value) {
        if (key_file != null) {
            try {
                key_file.set_value (group, key, value);
                key_file.save_to_file (GOFI.Utils.config_file);
            } catch (Error e) {
                error ("An error occured while setting the setting"
                    +" %s.%s to %s: %s", group, key, value, e.message);
            }
        }
    }
    
    /**
     * Generates the default configuration.
     * It also tries to automatically determine the location of the user's 
     * Todo.txt directory by checking a set of common potential 
     * "standard locations", which are defined in GOFI.TEST_DIRS in Utils.vala.
     */
    private void generate_configuration () {
        string user_dir = Environment.get_home_dir ();
        
        /* Determine the Todo.txt Directory */
        // Start by setting the default fallback directory
        var todo_dir = Path.build_filename (user_dir, GOFI.TEST_DIRS[0]);
        
        // Try a set of possible "standard locations"
        foreach (var test_sub_dir in GOFI.TEST_DIRS) {
            var test_dir = Path.build_filename (user_dir, test_sub_dir);
            if (FileUtils.test (test_dir, FileTest.EXISTS)) {
                todo_dir = test_dir;
                break;
            }
        }
        
        this.todo_txt_location = todo_dir;
    }
}
