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

public class FileChooserWidget : Gtk.Button {
    private Gtk.Label uri_lbl;

    private string choose_file_text = _("Choose a file");

    public File? selected_file {
        get {
            return _file;
        }
        set {
            _file = value;
            if (_file == null) {
                uri_lbl.label = choose_file_text;
            } else {
                uri_lbl.label = _file.get_uri ();
            }
        }
    }
    private File? _file;

    public string dialog_title {
        get;
        set;
    }

    public string default_filename {
        get;
        set;
    }

    public Gtk.FileFilter? filter {
        get;
        set;
    }

    public FileChooserWidget (File? file, string dialog_title, string? default_filename = null) {
        uri_lbl = new Gtk.Label (null);
        uri_lbl.ellipsize = Pango.EllipsizeMode.START;
        uri_lbl.hexpand = true;
        uri_lbl.halign = Gtk.Align.START;

        var image = new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.add (uri_lbl);
        box.add (image);

        this.add (box);

        uri_lbl.show ();
        image.show ();
        box.show ();

        this.selected_file = file;
        this.dialog_title = dialog_title;
        this.default_filename = default_filename;

        this.clicked.connect (on_button_clicked);
    }

    public virtual void on_button_clicked () {
        var window = this.get_toplevel () as Gtk.Window;
#if HAS_GTK322
        var file_chooser = new Gtk.FileChooserNative (
            dialog_title, window, Gtk.FileChooserAction.SAVE,
            _("_Select"), null
        );
#else
        var file_chooser = new Gtk.FileChooserDialog (
            dialog_title, window, Gtk.FileChooserAction.SAVE,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("_Select"), Gtk.ResponseType.ACCEPT
        );
#endif
        file_chooser.select_multiple = false;
        file_chooser.do_overwrite_confirmation = false;

        if (_file != null) {
            try {
                file_chooser.set_file (_file);
            } catch (Error e) {
                warning ("Couldn't set file for file chooser dialog: %s", e.message);
                selected_file = null;
            }
        } else if (default_filename != null) {
            file_chooser.set_current_name (default_filename);
        }
        if (filter != null) {
            file_chooser.filter = filter;
        }
        int response_id = file_chooser.run ();
        if (response_id == Gtk.ResponseType.OK || response_id == Gtk.ResponseType.ACCEPT) {
            selected_file = file_chooser.get_file ();
        }
        file_chooser.destroy ();
    }
}
