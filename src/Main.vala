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
    private static bool refresh_tasks = false;
    private static bool use_header_bar = true;
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
        apply_desktop_specific_tweaks ();
        Main app = new Main ();
        int status = app.run (args);
        return status;
    }
    
    /**
     * This function handles different tweaks that have to be applied to
     * make Go For It! work properly on certain desktop environments.
     */
    public static void apply_desktop_specific_tweaks () {
        string desktop = Environment.get_variable ("DESKTOP_SESSION");
        
        if (desktop == "ubuntu") {
            // Disable overlay scrollbars on unity, to avoid a strange Gtk bug
            Environment.set_variable ("LIBOVERLAY_SCROLLBAR", "0", true);
        }
        
        if (desktop == "ubuntu" || desktop == "kde") {
            use_header_bar = false;
        }
    }
    
    public void new_window () {
        // Don't create a new window, if one already exists
        if (win != null) {
            win.show ();
            win.present ();
            return;
        }
        
        settings = new SettingsManager.load_from_key_file ();
        task_manager = new TaskManager(settings);
        task_timer = new TaskTimer (settings);
        task_timer.active_task_done.connect (task_manager.mark_task_done);
        win = new MainWindow (this, task_manager, task_timer, settings,
            use_header_bar);
        win.show_all ();
    }
    
    public void refresh () {
        if (win == null) {
            stdout.printf ("An instance of Go For It! needs to be running in order for this to work!\n");
            return;
        }
        task_manager.refresh ();
    }
    
    public void show_about (Gtk.Window? parent = null) {
        var dialog = new AboutDialog (parent);
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

        } else if (refresh_tasks) {
            refresh ();
        } else if (show_about_dialog) {
            show_about ();
        } else {
            new_window ();
        }

        return 0;
    }

    static const OptionEntry[] entries = {
        { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
        { "refresh", 'r', 0, OptionArg.NONE, out refresh_tasks, N_("Refresh the current window"), null },
        { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
        { null }
    };
}
