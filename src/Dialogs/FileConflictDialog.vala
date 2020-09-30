/* Copyright 2020 Go For It! developers
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
    class FileConflict {
        public string? info;
        public string src_uri;
        public string dst_uri;

        public FileConflict (string? info, string src_uri, string dst_uri) {
            this.info = info;
            this.src_uri = src_uri;
            this.dst_uri = dst_uri;
        }
    }

    class ConflictChoices {
        FileConflict[] conflicts;
        FileConflict[] replace_choices;
        FileConflict[] swap_choices;
        int i;

        public ConflictChoices () {
            i = 0;
            conflicts = {};
            replace_choices = {};
            swap_choices = {};
        }

        public void add_conflict (FileConflict conflict) {
            conflicts += conflict;
        }

        public void add_simple_replace (FileConflict simple_replace) {
            replace_choices += simple_replace;
        }

        public void add_simple_swap (FileConflict simple_swap) {
            swap_choices += simple_swap;
        }

        public unowned FileConflict? get_next_conflict () {
            if (i >= conflicts.length) {
                return null;
            }
            return conflicts[i];
        }

        public void keep () {
            i++;
        }

        public void replace () {
            replace_choices += conflicts[i];
            i++;
        }

        public void swap () {
            swap_choices += conflicts[i];
        }

        public unowned FileConflict[] get_replace_choices () {
            return replace_choices;
        }

        public unowned FileConflict[] get_swap_choices () {
            return swap_choices;
        }
    }

    class FileConflictDialogWrapper {

        string replace_dialog_primary = _("Replace \"%s\"?");
        string replace_dialog_question = _("Should this file be replaced or should the old file be used?");

        Gtk.MessageDialog dialog;
        ConflictChoices choices;

        public signal void choices_made (ConflictChoices choices);
        public signal void aborted ();

        public FileConflictDialogWrapper () {

        }

        public void show_conflict_dialog (Gtk.Window? window, ConflictChoices choices) {
            this.choices = choices;
            dialog = new Gtk.MessageDialog (
                window,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.NONE,
                "uninitialized"
            );
            string keep_str = _("Keep old");
            string replace_str = _("Replace");
            dialog.add_button (keep_str, Gtk.ResponseType.REJECT);
            var overwrite_but = dialog.add_button (
                replace_str, Gtk.ResponseType.ACCEPT
            );
            overwrite_but.get_style_context ().add_class ("destructive-action");
            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

            update_dialog ();
            dialog.response.connect (handle_confirm_dialog_response);
        }

        private void update_dialog () {
            var conflict = choices.get_next_conflict ();
            if (conflict == null) {
                dialog.destroy ();
                dialog = null;
                choices_made (choices);
                return;
            }

            dialog.text = replace_dialog_primary.printf (conflict.dst_uri);
            dialog.secondary_text = conflict.info + "\n" + replace_dialog_question;
        }

        private void handle_confirm_dialog_response (int response_id) {
            switch (response_id) {
                case Gtk.ResponseType.ACCEPT:
                    choices.replace ();
                    update_dialog ();
                    break;
                case Gtk.ResponseType.REJECT:
                    choices.keep ();
                    break;
                default:
                    dialog.destroy ();
                    dialog = null;
                    aborted ();
                    break;
            }
        }
    }
}
