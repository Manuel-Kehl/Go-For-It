/* Copyright 2014-2017 Go For It! developers
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

namespace GOFI {
    public KeyBindingSettings kbsettings;
    private SettingsManager settings;
    private ActivityLog activity_log;
}

/**
 * The main application class that is responsible for initiating all
 * necessary steps to create a running instance of "Go For It!".
 */
class GOFI.Main : Gtk.Application {
    private TaskTimer task_timer;
    private ListManager list_manager;
    private MainWindow win;

    private static bool print_version = false;
    private static bool show_about_dialog = false;
    private static string? logfile = null;

    /**
     * Used to determine if a notification should be sent.
     */
    private bool break_previously_active { get; set; default = false; }

    /**
     * Constructor of the Application class.
     */
    public Main () {
        Object (application_id: GOFI.APP_ID, flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    public void new_window () {
        // Don't create a new window, if one already exists
        if (win != null) {
            win.show ();
            win.present ();
            return;
        }

        settings = new SettingsManager.load_from_key_file ();
        task_timer = new TaskTimer ();
        list_manager = new ListManager ();

        // Enable Notifications for the App
        Notify.init (GOFI.APP_NAME);
        setup_notifications ();

        kbsettings = new KeyBindingSettings ();

        win = new MainWindow (this, list_manager, task_timer);
        win.show_all ();
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
        var context = new OptionContext (null);
        context.add_main_entries (entries, GOFI.EXEC_NAME);
        context.add_group (Gtk.get_option_group (true));

        string[] args = command_line.get_arguments ();

        try {
            context.parse_strv (ref args);
        } catch (Error e) {
            stdout.printf ("%s: Error: %s \n", GOFI.APP_NAME, e.message);
            return 0;
        }

        if (print_version) {
            stdout.printf ("%s %s\n", GOFI.APP_NAME, GOFI.APP_VERSION);
            stdout.printf ("Copyright 2014-2019 'Go For it!' Developers.\n");
        } else if (show_about_dialog) {
            show_about ();
        } else {
            if (logfile != null) {
                activity_log = new ActivityLog (File.new_for_commandline_arg (logfile));
            } else {
                activity_log = new ActivityLog (null);
            }
            new_window ();
        }

        return 0;
    }

    const OptionEntry[] entries = {
        { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
        { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
        { "logfile", 0, 0, OptionArg.FILENAME, out logfile, N_("CSV file to log activities to."), "FILE" },
        { null }
    };

    /**
     * Configures the emission of notifications when tasks/breaks are over
     */
    private void setup_notifications () {
        task_timer.active_task_changed.connect (task_timer_activated);
        task_timer.timer_almost_over.connect (display_almost_over_notification);
    }

    private void task_timer_activated (TodoTask? task, bool break_active) {
        if (task == null) {
            return;
        }
        if (break_previously_active != break_active) {
            Notify.Notification notification;

            if (break_active) {
                notification = new Notify.Notification (
                    _("Take a Break"),
                    _("Relax and stop thinking about your current task for a while")
                    + " :-)",
                    GOFI.EXEC_NAME);
            } else {
                notification = new Notify.Notification (
                    _("The Break is Over"),
                    _("Your current task is") + ": " + task.description,
                    GOFI.EXEC_NAME);
            }
            notification.set_hint (
                "desktop-entry", new Variant.string (GOFI.APP_SYSTEM_NAME)
            );

            try {
                notification.show ();
            } catch (GLib.Error err){
                GLib.stderr.printf (
                    "Error in notify! (break_active notification)\n");
            }
        }
        break_previously_active = break_active;
    }

    private void display_almost_over_notification (DateTime remaining_time) {
        int64 secs = remaining_time.to_unix ();
        Notify.Notification notification = new Notify.Notification (
            _("Prepare for your break"),
            _("You have %s seconds left").printf (secs.to_string ()), GOFI.EXEC_NAME);
        try {
            notification.show ();
        } catch (GLib.Error err){
            GLib.stderr.printf (
                "Error in notify! (remaining_time notification)\n");
        }
    }
}
