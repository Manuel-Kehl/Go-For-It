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

namespace GOFI {

    public struct Shortcut {
        uint key;
        Gdk.ModifierType modifier;

        public Shortcut(uint k, Gdk.ModifierType m) {
            this.key = k;
            this.modifier = m;
        }

        public static Shortcut from_string (string accelerator) {
            uint k;
            Gdk.ModifierType m;
            Gtk.accelerator_parse(accelerator, out k, out m);
            return Shortcut(k, m);
        }

        public string to_string () {
            return Gtk.accelerator_name (key, modifier);
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
        private GLib.Settings schema;

        static KeyBinding[] DragListBindings = {
            KeyBinding("next-task", "move-cursor", MoveKeyParams(Gtk.MovementStep.DISPLAY_LINES, 1).params),
            KeyBinding("prev-task", "move-cursor", MoveKeyParams(Gtk.MovementStep.DISPLAY_LINES, -1).params),
            KeyBinding("move-row-up", "move-selected-row", {KeyBindingParam<int>(1, typeof(int))}),
            KeyBinding("move-row-down", "move-selected-row", {KeyBindingParam<int>(-1, typeof(int))}),
        };

        static KeyBinding[] TaskListBindings = {
            KeyBinding("filter", "toggle-filtering", {}),
        };

        static KeyBinding[] TaskListPageBindings = {
            KeyBinding("next-task", "switch_to_next", {}),
            KeyBinding("prev-task", "switch_to_prev", {}),
            KeyBinding("mark-task-done", "mark_task_done", {}),
        };

        public KeyBindingSettings () {
            schema = new GLib.Settings (GOFI.APP_ID + ".keybindings");
            install_bindings(
                Gtk.BindingSet.by_class((ObjectClass) (typeof (DragList)).class_ref()),
                DragListBindings
            );
            install_bindings(
                Gtk.BindingSet.by_class((ObjectClass) (typeof (TXT.TaskList)).class_ref()),
                TaskListBindings
            );
            install_bindings(
                Gtk.BindingSet.by_class((ObjectClass) (typeof (TaskListPage)).class_ref()),
                TaskListPageBindings
            );
        }

        public Shortcut get_shortcut (string shortcut_id) {
            return Shortcut.from_string (schema.get_string (shortcut_id));
        }

        public void install_bindings (Gtk.BindingSet bind_set, KeyBinding[] bindings) {
            foreach (var kb in bindings) {
                var sc = get_shortcut (kb.shortcut_id);
                switch (kb.params.length) {
                    case 0:
                        Gtk.BindingEntry.add_signal(
                            bind_set, sc.key, sc.modifier, kb.signal_name, 0
                        );
                        break;
                    case 1:
                        Gtk.BindingEntry.add_signal(
                            bind_set, sc.key, sc.modifier, kb.signal_name, 1,
                             kb.params[0].type, kb.params[0].param
                        );
                        break;
                    case 2:
                        Gtk.BindingEntry.add_signal(
                            bind_set, sc.key, sc.modifier, kb.signal_name, 2,
                            kb.params[0].type, kb.params[0].param,
                            kb.params[1].type, kb.params[1].param
                        );
                        break;
                    case 3:
                        Gtk.BindingEntry.add_signal(
                            bind_set, sc.key, sc.modifier, kb.signal_name, 2,
                            kb.params[0].type, kb.params[0].param,
                            kb.params[1].type, kb.params[1].param,
                            kb.params[2].type, kb.params[2].param
                        );
                        break;
                    default:
                        error("Too many parameters (max = 3): %s", kb.signal_name);
                }
            }
        }
    }
}
