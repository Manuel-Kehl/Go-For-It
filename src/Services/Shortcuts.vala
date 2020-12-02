/* Copyright 2019 Go For It! developers
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
 * The code in this file is based on the keybinding code from
 * https://gitlab.com/doublehourglass/dnd_order_list_box
 */
namespace GOFI {

    public class Shortcut {
        public uint key;
        public Gdk.ModifierType modifier;

        public bool is_valid {
            get {
                return key != 0;
            }
        }

        public Shortcut (uint k, Gdk.ModifierType m) {
            this.key = k;
            this.modifier = m;
        }

        public Shortcut.from_string (string accelerator) {
            Gtk.accelerator_parse (accelerator, out this.key, out this.modifier);
        }

        public Shortcut.disabled () {
            this.key = 0;
            this.modifier = 0;
        }

        public string to_string () {
            if (!this.is_valid) {
                return "";
            }
            return Gtk.accelerator_name (key, modifier);
        }

        public string to_readable () {
            if (!this.is_valid) {
                return _("disabled");
            }
#if USE_GRANITE
            return Granite.accel_to_string (Gtk.accelerator_name (key, modifier));
#else
            return Gtk.accelerator_get_label (key, modifier);
#endif
        }

        public string get_accel_markup (string description) {
            if (!this.is_valid) {
                return description;
            }
#if USE_GRANITE
            if (this.is_valid) {
                return Granite.markup_accel_tooltip ({this.to_string ()}, description);
            } else {
                return Granite.markup_accel_tooltip ({}, description);
            }
#else
            if (this.is_valid) {
                return description;
            } else {
                return "%s\n<span weight=\"600\" size=\"smaller\" alpha=\"75%%\">%s</span>".printf (
                    description, this.to_readable ()
                );
            }
#endif
        }

        public bool equals (Shortcut other) {
            return other.key == key && other.modifier == modifier;
        }
    }

    public struct KeyBindingParam<G> {
        Gtk.BindingArg arg;

        // t should be long, double, or string depending on G
        public KeyBindingParam (G p, Type t) {
            this.arg.arg_type = t;
            this.arg.string_data = (string) p; // should be large enough
        }

        public G get_param () {
            return (G) arg.string_data;
        }
    }

    public struct MoveKeyParams {
        KeyBindingParam[] params;

        MoveKeyParams (Gtk.MovementStep step, int count) {
            params = {
                KeyBindingParam<Gtk.MovementStep> (step, typeof (long)),
                KeyBindingParam<int> (count, typeof (long))
            };
        }
    }

    public struct KeyBinding {
        string shortcut_id;
        string signal_name;
        KeyBindingParam[] params;
        public KeyBinding (string sc, string s, KeyBindingParam[] p) {
            this.shortcut_id = sc;
            this.signal_name = s;
            this.params = p;
        }
    }

    public class KeyBindingSettings {
        private GLib.Settings settings_backend;
        HashTable<string, Shortcut> shortcuts;

        public struct ConfigurableShortcut {
            string shortcut_id;
            string description;

            public ConfigurableShortcut (string sc_id, string descr) {
                this.shortcut_id = sc_id;
                this.description = descr;
            }
        }

        public const string SCK_ADD_NEW = "add-new";
        public const string SCK_CYCLE_PAGE = "cycle-page";
        public const string SCK_CYCLE_PAGE_REV = "cycle-page-reverse";
        public const string SCK_DELETE = "delete"; // Not configurable
        public const string SCK_EDIT_PROPERTIES = "edit-properties";
        public const string SCK_FILTER = "filter";
        public const string SCK_MARK_TASK_DONE = "mark-task-done";
        public const string SCK_MOVE_ROW_DOWN = "move-row-down";
        public const string SCK_MOVE_ROW_UP = "move-row-up";
        public const string SCK_NEXT_TASK = "next-task";
        public const string SCK_PREV_TASK = "prev-task";
        public const string SCK_SORT = "sort";
        public const string SCK_SKIP = "skip";
        public const string SCK_TOGGLE_TIMER = "toggle-timer";
        public const string[] SC_KEYS = {
            SCK_ADD_NEW, SCK_CYCLE_PAGE, SCK_CYCLE_PAGE_REV,
            SCK_EDIT_PROPERTIES, SCK_FILTER, SCK_MARK_TASK_DONE,
            SCK_MOVE_ROW_DOWN, SCK_MOVE_ROW_UP, SCK_NEXT_TASK,
            SCK_PREV_TASK, SCK_SORT, SCK_SKIP, SCK_TOGGLE_TIMER
        };

        public static ConfigurableShortcut[] known_shortcuts = {
            ConfigurableShortcut (SCK_FILTER,         _("Filter tasks")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_SORT,           _("Sort Tasks")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_ADD_NEW,        _("Add new task/list")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_TOGGLE_TIMER,   _("Start/Stop the timer")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_SKIP,           _("Skip the break or skip to the break")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_EDIT_PROPERTIES,_("Edit the properties of a list or task")), // vala-lint=no-space

            ConfigurableShortcut (SCK_MARK_TASK_DONE, _("Mark the task as complete")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_MOVE_ROW_UP,    _("Move selected row up")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_MOVE_ROW_DOWN,  _("Move selected row down")), // vala-lint=double-spaces

            ConfigurableShortcut (SCK_NEXT_TASK,      _("Move to next task/row")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_PREV_TASK,      _("Move to previous task/row")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_CYCLE_PAGE,     _("Move to right screen")), // vala-lint=double-spaces
            ConfigurableShortcut (SCK_CYCLE_PAGE_REV, _("Move to left screen")), // vala-lint=double-spaces
        };

        static KeyBinding[] drag_list_bindings = {
            KeyBinding (SCK_NEXT_TASK, "move-cursor", MoveKeyParams (Gtk.MovementStep.DISPLAY_LINES, 1).params),
            KeyBinding (SCK_PREV_TASK, "move-cursor", MoveKeyParams (Gtk.MovementStep.DISPLAY_LINES, -1).params),
            KeyBinding (SCK_MOVE_ROW_UP, "move-selected-row", {KeyBindingParam<long> (1, typeof (long))}),
            KeyBinding (SCK_MOVE_ROW_DOWN, "move-selected-row", {KeyBindingParam<long> (-1, typeof (long))}),
        };

        static KeyBinding[] task_list_bindings = {
            KeyBinding (SCK_FILTER, "toggle-filtering", {}),
            KeyBinding (SCK_SORT, "sort-tasks", {}),
            KeyBinding (SCK_EDIT_PROPERTIES, "task_edit_action", {}),
        };

        static KeyBinding[] window_bindings = {
            KeyBinding (SCK_FILTER, "filter-fallback-action", {}),
        };

        static KeyBinding[] task_list_page_bindings = {
            KeyBinding (SCK_NEXT_TASK, "switch_to_next", {}),
            KeyBinding (SCK_PREV_TASK, "switch_to_prev", {}),
            KeyBinding (SCK_MARK_TASK_DONE, "mark_task_done", {}),
        };

        static KeyBinding[] selection_page_bindings = {
            KeyBinding (SCK_EDIT_PROPERTIES, "list_edit_action", {}),
            KeyBinding (SCK_DELETE, "list_delete_action", {}),
        };

        static KeyBinding[] timer_view_bindings = {
            KeyBinding (SCK_SKIP, "skip", {}),
        };

        public KeyBindingSettings () {
            shortcuts = new HashTable<string, Shortcut> (str_hash, str_equal);

            settings_backend = new GLib.Settings (GOFI.APP_ID + ".keybindings");

            foreach (var key in SC_KEYS) {
                shortcuts[key] = new Shortcut.from_string (settings_backend.get_string (key));
            }
            shortcuts[SCK_DELETE] = new Shortcut.from_string ("Delete");
            install_bindings_for_class (
                typeof (DragList),
                drag_list_bindings
            );
            install_bindings_for_class (
                typeof (TXT.TaskListWidget),
                task_list_bindings
            );
            install_bindings_for_class (
                typeof (TaskListPage),
                task_list_page_bindings
            );
            install_bindings_for_class (
                typeof (SelectionPage),
                selection_page_bindings
            );
            install_bindings_for_class (
                typeof (TimerView),
                timer_view_bindings
            );
            install_bindings_for_class (
                typeof (MainWindow),
                window_bindings
            );
        }

        public Shortcut? get_shortcut (string shortcut_id) {
            return shortcuts.lookup (shortcut_id);
        }

        public string? conflicts (Shortcut sc) {
            string? conflict_id = null;

            shortcuts.foreach ((key, other) => {
                if (sc.equals (other)) {
                    conflict_id = key;
                }
            });

            return conflict_id;
        }

        /**
         * Todo: unbind old shortcut and bind the actions to the new one
         */
        public void set_shortcut (string shortcut_id, Shortcut sc) {
            var old_sc = shortcuts[shortcut_id];

            if (old_sc == null) {
                warning ("No shortcut with id \"%s\" is known", shortcut_id);
                return;
            }
            if (shortcut_id == "delete") {
                return;
            }

            shortcuts[shortcut_id] = sc;
            settings_backend.set_string (shortcut_id, sc.to_string ());
        }

        public void install_bindings_for_class (Type type, KeyBinding[] bindings) {
            install_bindings (
                Gtk.BindingSet.by_class ((ObjectClass) (type).class_ref ()),
                bindings
            );
        }

        public void install_bindings (Gtk.BindingSet bind_set, KeyBinding[] bindings) {
            foreach (var kb in bindings) {
                var sc = get_shortcut (kb.shortcut_id);
                if (sc == null) {
                    if (settings_backend != null) {
                        warning ("Unknown shortcut id: \"%s\".", kb.shortcut_id);
                    }
                    continue;
                }
                if (!sc.is_valid) {
                    return;
                }

                var binding_args = new SList<Gtk.BindingArg?> ();

                for (int i = 0; i < kb.params.length; i++) {
                    binding_args.prepend (kb.params[i].arg);
                }

                binding_args.reverse ();

                Gtk.BindingEntry.add_signall (
                    bind_set, sc.key, sc.modifier, kb.signal_name, binding_args
                );
            }
        }
    }
}
