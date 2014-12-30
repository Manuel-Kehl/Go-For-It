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
 * The main application class that is responsible for initiating all
 * necessary steps to create a running instance of "Go For It!".
 */
public class Main : Gtk.Application {
    private SettingsManager settings;
    private TaskManager task_manager;
    private TaskTimer task_timer;
    private MainWindow win;

    private static bool print_version = false;
    private static bool show_about_dialog = false;
    /**
     * Constructor of the Application class.
     */
    private Main () {
        Object (application_id: GOFI.APP_ID, flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }
    
    /**
     * The entry point for running the application.
     */
    public static int main (string[] args) {
        Main app = new Main ();
        int status = app.run (args);
        return status;
    }
    
    public void new_window () {
        // Don't create a new window, if one already exists
        if (win != null) {
            win.show_all ();
            win.present ();
            return;
        }
        
        settings = new SettingsManager.load_from_key_file ();
        task_manager = new TaskManager(settings);
        task_timer = new TaskTimer (settings);
        task_timer.active_task_done.connect (task_manager.mark_task_done);
        win = new MainWindow (this, task_manager, task_timer, settings);
        win.show_all ();
        
        /*
         * If the timer is currently active, create a new hidden instance of
         * MainWindow, so that the app keeps running in the background.
         */
        this.window_removed.connect ((e) => {
            if (task_timer.running) {
                win = new MainWindow (this, task_manager, task_timer, settings);
            }
        });
        
    }
    public void show_about () {
        var dialog = new AboutDialog ();
        dialog.run ();
    }

    public override int command_line (ApplicationCommandLine command_line) {
        hold ();
        int res = _command_line (command_line);
        release ();
        return res;
    }

    private int _command_line (ApplicationCommandLine command_line) {
        var context = new OptionContext (GOFI.APP_NAME);
        context.add_main_entries (entries, GOFI.APP_SYSTEM_NAME);
        context.add_group (Gtk.get_option_group (true));

        string[] args = command_line.get_arguments ();

        try {
            unowned string[] tmp = args;
            context.parse (ref tmp);
        } catch (Error e) {
            stdout.printf ("%s: Error: %s \n", GOFI.APP_NAME, e.message);
            return 0;
        }

        if (print_version) {
            stdout.printf ("%s %s\n", GOFI.APP_NAME, GOFI.APP_VERSION);
            stdout.printf ("Copyright 2011-2014 'Go For it!' Developers.\n");

        } else if (show_about_dialog) {
            show_about ();
        } else {
            new_window ();
        }

        return 0;
    }

    static const OptionEntry[] entries = {
        { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
        { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
        { null }
    };
}
