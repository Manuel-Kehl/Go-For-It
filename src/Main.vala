/* Copyright 2014-2020 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

namespace GOFI {
    public KeyBindingSettings kbsettings;
    private SettingsManager settings = null;
    private ActivityLog activity_log = null;
    private ListManager list_manager = null;
#if !NO_PLUGINS
    private PluginManager plugin_manager = null;
#endif
    private TaskTimer task_timer;
    private MainWindow win;
    private Notifications notification_service;
}

errordomain GOFIParseError {
    TOO_FEW_ARGS,
    TOO_MANY_ARGS,
    BAD_VALUE,
    PARAM_NOT_UNIQUE
}

/**
 * The main application class that is responsible for initiating all
 * necessary steps to create a running instance of "GoForIt!".
 */
class GOFI.Main : Gtk.Application {
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

#if !NO_PLUGINS
    private void load_plugin_manager () {
        if (plugin_manager == null) {
            plugin_manager = new PluginManager (task_timer);
        }
    }
#endif

    private void setup_timer_and_notifications () {
        if (task_timer == null) {
            task_timer = new TaskTimer ();
            // Enable Notifications for the App
            notification_service = new Notifications (this);
            task_timer.timer_finished.connect (on_timer_elapsed);
        }
    }

    /**
     * Constructor of the Application class.
     */
    public Main () {
        Object (application_id: GOFI.APP_ID, flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    public void new_window () {
        load_settings ();
        setup_timer_and_notifications ();
#if !NO_PLUGINS
        load_plugin_manager ();
#endif
        load_list_manager ();

        TodoListInfo? info = null;
        if (load_list != null) {
            info = list_manager.get_list_info (load_list[0], load_list[1]);
            if (info == null) {
                stdout.printf (_("Not a known list: %s"),
                    new ListIdentifier (
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
            win.restore_win_geometry ();
            win.present ();
            return;
        }
#if !NO_PLUGINS
        plugin_manager.load_plugins ();
#endif

        kbsettings = new KeyBindingSettings ();

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (quit_application);

        add_action (quit_action);
        set_accels_for_action ("app.quit", { "<Control>q" });

        if (info == null) {
            info = get_last_list_info ();
        }

        win = new MainWindow (this, task_timer, info);
        win.show_all ();
        win.delete_event.connect (on_win_delete_event);
    }

    private void quit_application () {
        task_timer.stop ();
        win.save_win_geometry ();
        win.destroy ();
        win = null;
        task_timer = null;
        notification_service = null;
    }

    private bool on_win_delete_event () {
        bool dont_exit = false;
        // Save window state upon deleting the window
        win.save_win_geometry ();

        if (task_timer.running) {
            win.hide ();
            dont_exit = true;
        }

        if (dont_exit == false) {
            win = null;
            task_timer = null;
            notification_service = null;
        }

        return dont_exit;
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
            args[pos + i] = null;
        }
        int to_move = args.length - pos - length;
        int old_length = args.length;
        if (to_move > 0) {
            args.move (pos + length, pos, to_move);
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
                if (i + 2 < args.length && args[i + 1][0] != '-' && args[i + 2][0] != '-') {
                    if (i + 3 != args.length && args[i + 3][0] != '-') {
                        throw new GOFIParseError.TOO_MANY_ARGS (
                            "Too many arguments for --load: \"%s\"", args[i + 3]
                        );
                    }
                    load_list = {args[i + 1], args[i + 2]};
                    remove_args (ref args, i, 3);
                    break;
                } else {
                    throw new GOFIParseError.TOO_FEW_ARGS ("Missing arguments for --load");
                }
            }
        }
        for (; i < args.length; i++) {
            if (args[i] == "--load") {
                throw new GOFIParseError.PARAM_NOT_UNIQUE (
                    "Second --load parameter encountered!" + "\n" +
                    "Only one list can be loaded at a time"
                );
            }
        }
    }

    private int _command_line (ApplicationCommandLine command_line) {
        var context = new OptionContext (null);
        context.add_main_entries (ENTRIES, GOFI.EXEC_NAME);
        context.add_main_entries (get_dynamic_entries (), GOFI.EXEC_NAME);
        context.add_group (Gtk.get_option_group (true));

        string[] args = command_line.get_arguments ();

        try {
            multi_arg_parse (ref args);
            context.parse_strv (ref args);
        } catch (Error e) {
            stdout.printf (_("%1$s: Error: %2$s") + "\n", GOFI.APP_NAME, e.message);
            return 0;
        }

        if (print_version) {
            stdout.printf ("%s %s\n", GOFI.APP_NAME, GOFI.get_version_str ());
            stdout.printf ("Copyright 2014-2020 'Go For it!' Developers.\n");
        } else if (show_about_dialog) {
            show_about ();
        } else if (list_lists) {
            load_settings ();
            load_list_manager ();

            /// Describes format of printed table (table contains the known lists)
            /// The order of the segments ($1 : $2 - $3) between the brackets must remain the same!
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
                if (logfile.get (0) == '~' && logfile.get (1) == '/') {
                    logfile = Environment.get_home_dir () + logfile.offset (1);
                }
                activity_log = new ActivityLog (File.new_for_commandline_arg (logfile));
            } else if (activity_log == null) {
                activity_log = new ActivityLog (null);
            }
            new_window ();
        }

        return 0;
    }

    /// Translators: give translation of FILE in "--logfile=FILE" command line argument
    private const string ENTRY_FILE_ARG = N_("FILE");

    /// Translators: give translation of LIST-TYPE in "--load LIST-TYPE LIST-ID" command line argument
    private static string ENTRY_LIST_TYPE_ARG = _("LIST-TYPE"); // vala-lint=naming-convention
    /// Translators: give translation of LIST-ID in "--load LIST-TYPE LIST-ID" command line argument
    private static string ENTRY_LIST_ID_ARG = _("LIST-ID"); // vala-lint=naming-convention

    const OptionEntry[] ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
        { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
        { "logfile", 0, 0, OptionArg.FILENAME, out logfile, N_("CSV file to log activities to."), ENTRY_FILE_ARG },
        { "list", 0, 0, OptionArg.NONE, out list_lists, N_("Show configured lists and exit"), null},
        { null }
    };

    private const string LOAD_ENTRY_DESCR = N_("Load the list specified by the list type and ID");
    private static string LOAD_ENTRY_NAME = "load" + " " + ENTRY_LIST_TYPE_ARG + " " + ENTRY_LIST_ID_ARG; // vala-lint=naming-convention

    private OptionEntry[] get_dynamic_entries () {
        return {
            OptionEntry () {
                long_name = LOAD_ENTRY_NAME,
                short_name = 0,
                flags = 0,
                arg = OptionArg.NONE,
                arg_data = null,
                description = LOAD_ENTRY_DESCR,
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

    private void on_timer_elapsed () {
#if !NO_PLUGINS
        bool show_window = plugin_manager.show_on_timer_elapsed;
#else
        bool show_window = true;
#endif
        if (show_window) {
            if (!win.visible) {
                win.show ();
                win.restore_win_geometry ();
            }

            win.present_timer ();
        }
    }
}
