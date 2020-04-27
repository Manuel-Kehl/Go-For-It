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
        Type type;
        G param;

        public KeyBindingParam(G p, Type t) {
            this.param = p;
            this.type = t;
        }
    }

    public struct MoveKeyParams {
        KeyBindingParam[] params;

        MoveKeyParams(Gtk.MovementStep step, int count) {
            params = {
                KeyBindingParam<Gtk.MovementStep>(step, typeof( Gtk.MovementStep )),
                KeyBindingParam<int>(count, typeof( int ))
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

        public static ConfigurableShortcut[] known_shortcuts = {
            ConfigurableShortcut ("filter",         _("Filter tasks")),
            ConfigurableShortcut ("add-new",        _("Add new task/list")),
            ConfigurableShortcut ("toggle-timer",   _("Start/Stop the timer")),
            ConfigurableShortcut ("mark-task-done", _("Mark the task as complete")),
            ConfigurableShortcut ("move-row-up",    _("Move selected row up")),
            ConfigurableShortcut ("move-row-down",  _("Move selected row down")),

            ConfigurableShortcut ("next-task",      _("Move to next task/row")),
            ConfigurableShortcut ("prev-task",      _("Move to previous task/row")),
            ConfigurableShortcut ("cycle-page",     _("Move to right screen")),
            ConfigurableShortcut ("cycle-page-reverse", _("Move to left screen")),
        };

        static KeyBinding[] DragListBindings = {
            KeyBinding("next-task", "move-cursor", MoveKeyParams(Gtk.MovementStep.DISPLAY_LINES, 1).params),
            KeyBinding("prev-task", "move-cursor", MoveKeyParams(Gtk.MovementStep.DISPLAY_LINES, -1).params),
            KeyBinding("move-row-up", "move-selected-row", {KeyBindingParam<int>(1, typeof(int))}),
            KeyBinding("move-row-down", "move-selected-row", {KeyBindingParam<int>(-1, typeof(int))}),
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

            var schema_source = GLib.SettingsSchemaSource.get_default ();
            var schema_id = GOFI.APP_ID + ".keybindings";

            var schema = schema_source.lookup (schema_id, true);
            settings_backend = new GLib.Settings.full (schema, null, null);

            if (schema != null) {
                settings_backend = new GLib.Settings.full (schema, null, null);
            } else {
                warning ("Settings schema \"%s\" is not installed on your system!", schema_id);
                return;
            }

            foreach (var key in settings_backend.list_keys ()) {
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
                switch (kb.params.length) {
                    case 0:
                        Gtk.BindingEntry.add_signal (
                            bind_set, sc.key, sc.modifier, kb.signal_name, 0
                        );
                        break;
                    case 1:
                        Gtk.BindingEntry.add_signal (
                            bind_set, sc.key, sc.modifier, kb.signal_name, 1,
                             kb.params[0].type, kb.params[0].param
                        );
                        break;
                    case 2:
                        Gtk.BindingEntry.add_signal (
                            bind_set, sc.key, sc.modifier, kb.signal_name, 2,
                            kb.params[0].type, kb.params[0].param,
                            kb.params[1].type, kb.params[1].param
                        );
                        break;
                    case 3:
                        Gtk.BindingEntry.add_signal (
                            bind_set, sc.key, sc.modifier, kb.signal_name, 2,
                            kb.params[0].type, kb.params[0].param,
                            kb.params[1].type, kb.params[1].param,
                            kb.params[2].type, kb.params[2].param
                        );
                        break;
                    default:
                        warning ("Too many parameters (max = 3): %s", kb.signal_name);
                        break;
                }
            }
        }
    }
}
