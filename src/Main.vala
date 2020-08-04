/* Copyright 2014-2020 Go For It! developers
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
    private SettingsManager settings = null;
    private ActivityLog activity_log = null;
    private ListManager list_manager = null;
}

errordomain GOFIParseError {
    TOO_FEW_ARGS,
    TOO_MANY_ARGS,
    BAD_VALUE,
    PARAM_NOT_UNIQUE
}

/**
 * The main application class that is responsible for initiating all
 * necessary steps to create a running instance of "Go For It!".
 */
class GOFI.Main : Gtk.Application {
    private TaskTimer task_timer;
    private MainWindow win;

    private static bool print_version = false;
    private static bool show_about_dialog = false;
    private static bool list_lists = false;
    private static string? logfile = null;
    private static string[] load_list = null;

    private void load_settings () {
        if (settings == null) {
            settings = new SettingsManager ();
        }
    }

    private void load_list_manager () {
        if (list_manager == null) {
            list_manager = new ListManager ();
        }
    }

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
        load_settings ();
        load_list_manager ();
        assert (list_manager != null);

        TodoListInfo? info = null;
        if (load_list != null) {
            info = list_manager.get_list_info (load_list[0], load_list[1]);
            if (info == null) {
                stdout.printf (_("Not a known list: %s"),
                    new ListIdentifier(
                        load_list[0],
                        load_list[1]
                    ).to_string ()
                );
                load_list = null;
                return;
            }
            load_list = null;
        }

        // Don't create a new window, if one already exists
        if (win != null) {
            if (info != null) {
                win.on_list_chosen (info);
            }
            win.show ();
            win.present ();
            return;
        }

        task_timer = new TaskTimer ();

        // Enable Notifications for the App
        Notify.init (GOFI.APP_NAME);
        setup_notifications ();

        kbsettings = new KeyBindingSettings ();

        if (info == null) {
            info = get_last_list_info ();
        }

        win = new MainWindow (this, task_timer, info);
        win.show_all ();
    }

    private TodoListInfo? get_last_list_info () {
        var last_loaded = settings.list_last_loaded;
        if (last_loaded != null) {
            var list = list_manager.get_list_info (last_loaded.provider, last_loaded.id);
            if (list != null) {
                return list;
            }
        }
        return null;
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

    /**
     * Removes arguments from args. This frees the args located at pos and
     * shrinks args.
     */
    private static void remove_args (ref string[] args, int pos, int length) {
        for (int i = 0; i < length; i++) {
            args[pos+i] = null;
        }
        int to_move = args.length - pos - length;
        int old_length = args.length;
        if (to_move > 0) {
            args.move (pos+length, pos, to_move);
        }
        args.length = old_length - length;
    }

    /**
     * This function performs manual parsing of parameters that have multiple
     * arguments. OptionContext.parse_strv isn't able to do that at this time.
     */
    private void multi_arg_parse (ref string[] args) throws GOFIParseError {
        int i = 0;
        for (; i < args.length; i++) {
            if (args[i] == "--load") {
                if (i+2 < args.length && args[i+1][0] != '-' && args[i+2][0] != '-') {
                    if (i+3 != args.length && args[i+3][0] != '-') {
                        throw new GOFIParseError.TOO_MANY_ARGS(
                            "Too many arguments for --load: \"%s\"", args[i+3]
                        );
                    }
                    load_list = {args[i+1], args[i+2]};
                    remove_args (ref args, i ,3);
                    break;
                } else {
                    throw new GOFIParseError.TOO_FEW_ARGS("Missing arguments for --load");
                }
            }
        }
        for (; i < args.length; i++) {
            if (args[i] == "--load") {
                throw new GOFIParseError.PARAM_NOT_UNIQUE(
                    "Second --load parameter encountered!" + "\n" +
                    "Only one list can be loaded at a time"
                );
            }
        }
    }

    private int _command_line (ApplicationCommandLine command_line) {
        var context = new OptionContext (null);
        context.add_main_entries (entries, GOFI.EXEC_NAME);
        context.add_main_entries (get_dynamic_entries (), GOFI.EXEC_NAME);
        context.add_group (Gtk.get_option_group (true));

        string[] args = command_line.get_arguments ();

        try {
            multi_arg_parse (ref args);
            context.parse_strv (ref args);
        } catch (Error e) {
            stdout.printf (_("%s: Error: %s") + "\n", GOFI.APP_NAME, e.message);
            return 0;
        }

        if (print_version) {
            stdout.printf ("%s %s\n", GOFI.APP_NAME, GOFI.APP_VERSION);
            stdout.printf ("Copyright 2014-2020 'Go For it!' Developers.\n");
        } else if (show_about_dialog) {
            show_about ();
        } else if (list_lists) {
            load_settings ();
            load_list_manager ();
            stdout.printf (_("Lists (List type : List ID - List name)") + ":\n");
            foreach (var info in list_manager.get_list_infos ()) {
                stdout.printf ("\"%s\" : \"%s\" - \"%s\"\n", info.provider_name, info.id, info.name);
            }
        } else {
            if (logfile != null) {
                // resolving ~, useful if --logfile=~/something is used
                // (The user probably doesn't mean that it wants to create a
                // folder called ~)
                // Doing this is probably non standard, but I think that its
                // better to be helpful than to confuse the user.
                if (logfile.get(0) == '~' && logfile.get(1) == '/') {
                    logfile = Environment.get_home_dir () + logfile.offset(1);
                }
                activity_log = new ActivityLog (File.new_for_commandline_arg (logfile));
            } else if (activity_log == null) {
                activity_log = new ActivityLog (null);
            }
            new_window ();
        }

        return 0;
    }

    const OptionEntry[] entries = {
        { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
        { "about",   'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
        { "logfile",   0, 0, OptionArg.FILENAME, out logfile, N_("CSV file to log activities to."), N_("FILE") },
        { "list",      0, 0, OptionArg.NONE, out list_lists, N_("Show configured lists and exit"), null},
        { null }
    };

    private const string load_entry_descr = N_("Load the list specified by the list type and ID");
    private string load_entry_name = "load" + " " + _("LIST-TYPE") + " " + _("LIST-ID");

    private OptionEntry[] get_dynamic_entries () {
        return {
            OptionEntry () {
                long_name = load_entry_name,
                short_name = 0,
                flags = 0,
                arg = OptionArg.NONE,
                arg_data = null,
                description = load_entry_descr,
                arg_description = null
            },
            OptionEntry () { // empty OptionEntry to null terminate list
                long_name = null,
                short_name = 0,
                flags = 0,
                arg = 0,
                arg_data = null,
                description = null,
                arg_description = null
            }
        };
    }

    /**
     * Configures the emission of notifications when tasks/breaks are over
     */
    private void setup_notifications () {
        task_timer.active_task_changed.connect (task_timer_activated);
        task_timer.timer_almost_over.connect (display_almost_over_notification);
        task_timer.task_duration_exceeded.connect (display_duration_exceeded);
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

    private void display_almost_over_notification (uint remaining_time) {
        Notify.Notification notification = new Notify.Notification (
            _("Prepare for your break"),
            _("You have %s seconds left").printf (remaining_time.to_string ()),
            GOFI.EXEC_NAME
        );
        notification.set_hint (
            "desktop-entry", new Variant.string (GOFI.APP_SYSTEM_NAME)
        );
        try {
            notification.show ();
        } catch (GLib.Error err){
            GLib.stderr.printf (
                "Error in notify! (remaining_time notification)\n");
        }
    }

    private void display_duration_exceeded () {
        Notify.Notification notification = new Notify.Notification (
            _("Task duration exceeded"),
            _("Consider switching to a different task"), GOFI.EXEC_NAME);
        try {
            notification.show ();
        } catch (GLib.Error err){
            GLib.stderr.printf (
                "Error in notify! (remaining_time notification)\n");
        }
    }
}
