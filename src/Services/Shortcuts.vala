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

        public Shortcut(uint k, Gdk.ModifierType m) {
            this.key = k;
            this.modifier = m;
        }

        public Shortcut.from_string (string accelerator) {
            Gtk.accelerator_parse(accelerator, out this.key, out this.modifier);
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

            var tmp = "";

            if ((this.modifier & Gdk.ModifierType.CONTROL_MASK) != 0) {
                tmp += "Ctrl + ";
            }
            if ((this.modifier & Gdk.ModifierType.SHIFT_MASK) != 0) {
                tmp += "Shift + ";
            }
            if ((this.modifier & Gdk.ModifierType.MOD1_MASK) != 0) {
                tmp += "Alt + ";
            }
            switch (this.key) {
                case Gdk.Key.Return:
                    tmp += "Enter"; // Most keyboards have Enter printed on the key
                    break;
                default:
                    tmp += Gdk.keyval_name (this.key);
                    break;
            }

            return tmp;
        }

        public bool equals (Shortcut other) {
            return other.key == key && other.modifier == modifier;
        }
    }

    public struct KeyBindingParam<G> {
        Gtk.BindingArg arg;

        // t should be long, double, or string depending on G
        public KeyBindingParam(G p, Type t) {
            this.arg.arg_type = t;
            this.arg.string_data = (string) p; // should be large enough
        }

        public G get_param () {
            return (G) arg.string_data;
        }
    }

    public struct MoveKeyParams {
        KeyBindingParam[] params;

        MoveKeyParams(Gtk.MovementStep step, int count) {
            params = {
                KeyBindingParam<Gtk.MovementStep>(step, typeof(long)),
                KeyBindingParam<int>(count, typeof(long))
            };
        }
    }

    public struct KeyBinding {
        string shortcut_id;
        string signal_name;
        KeyBindingParam[] params;
        public KeyBinding(string sc, string s, KeyBindingParam[] p) {
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

            public ConfigurableShortcut(string sc_id, string descr) {
                this.shortcut_id = sc_id;
                this.description = descr;
            }
        }

        public const string SCK_FILTER = "filter";
        public const string SCK_ADD_NEW = "add-new";
        public const string SCK_TOGGLE_TIMER = "toggle-timer";
        public const string SCK_MARK_TASK_DONE = "mark-task-done";
        public const string SCK_MOVE_ROW_UP = "move-row-up";
        public const string SCK_MOVE_ROW_DOWN = "move-row-down";
        public const string SCK_NEXT_TASK = "next-task";
        public const string SCK_PREV_TASK = "prev-task";
        public const string SCK_CYCLE_PAGE = "cycle-page";
        public const string SCK_CYCLE_PAGE_REV = "cycle-page-reverse";
        public const string[] SC_KEYS = {SCK_FILTER, SCK_ADD_NEW, SCK_TOGGLE_TIMER, SCK_MARK_TASK_DONE, SCK_MOVE_ROW_UP, SCK_MOVE_ROW_DOWN, SCK_NEXT_TASK, SCK_PREV_TASK, SCK_CYCLE_PAGE, SCK_CYCLE_PAGE_REV};

        public static ConfigurableShortcut[] known_shortcuts = {
            ConfigurableShortcut (SCK_FILTER,         _("Filter tasks")),
            ConfigurableShortcut (SCK_ADD_NEW,        _("Add new task/list")),
            ConfigurableShortcut (SCK_TOGGLE_TIMER,   _("Start/Stop the timer")),
            ConfigurableShortcut (SCK_MARK_TASK_DONE, _("Mark the task as complete")),
            ConfigurableShortcut (SCK_MOVE_ROW_UP,    _("Move selected row up")),
            ConfigurableShortcut (SCK_MOVE_ROW_DOWN,  _("Move selected row down")),

            ConfigurableShortcut (SCK_NEXT_TASK,      _("Move to next task/row")),
            ConfigurableShortcut (SCK_PREV_TASK,      _("Move to previous task/row")),
            ConfigurableShortcut (SCK_CYCLE_PAGE,     _("Move to right screen")),
            ConfigurableShortcut (SCK_CYCLE_PAGE_REV, _("Move to left screen")),
        };

        static KeyBinding[] DragListBindings = {
            KeyBinding("next-task", "move-cursor", MoveKeyParams(Gtk.MovementStep.DISPLAY_LINES, 1).params),
            KeyBinding("prev-task", "move-cursor", MoveKeyParams(Gtk.MovementStep.DISPLAY_LINES, -1).params),
            KeyBinding("move-row-up", "move-selected-row", {KeyBindingParam<long>(1, typeof(long))}),
            KeyBinding("move-row-down", "move-selected-row", {KeyBindingParam<long>(-1, typeof(long))}),
        };

        static KeyBinding[] TaskListBindings = {
            KeyBinding("filter", "toggle-filtering", {}),
        };

        static KeyBinding[] WindowBindings = {
            KeyBinding("filter", "filter-fallback-action", {}),
        };

        static KeyBinding[] TaskListPageBindings = {
            KeyBinding("next-task", "switch_to_next", {}),
            KeyBinding("prev-task", "switch_to_prev", {}),
            KeyBinding("mark-task-done", "mark_task_done", {}),
        };

        public KeyBindingSettings () {
            shortcuts = new HashTable<string, Shortcut> (str_hash, str_equal);

            settings_backend = new GLib.Settings (GOFI.APP_ID + ".keybindings");

            foreach (var key in SC_KEYS) {
                shortcuts[key] = new Shortcut.from_string (settings_backend.get_string (key));
            }
            install_bindings_for_class (
                typeof (DragList),
                DragListBindings
            );
            install_bindings_for_class (
                typeof (TXT.TaskListWidget),
                TaskListBindings
            );
            install_bindings_for_class (
                typeof (TaskListPage),
                TaskListPageBindings
            );
            install_bindings_for_class (
                typeof (MainWindow),
                WindowBindings
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
