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
class GOFI.ViewSwitcher : Gtk.Box {
    HashTable<string, SButton> buttons;

    public Gtk.IconSize icon_size {
        get {
            return _icon_size;
        }
        set {
            _icon_size = value;
            foreach (Gtk.Widget child in get_children ()) {
                ((SButton) child).icon_size = value;
            }
        }
    }
    private Gtk.IconSize _icon_size;

    public bool show_icons {
        get {
            return _show_icons;
        }
        set {
            _show_icons = value;
            foreach (Gtk.Widget child in get_children ()) {
                ((SButton) child).show_icon = value;
            }
        }
    }
    private bool _show_icons;

    public string selected_item {
        get {
            return _selected_item;
        }
        set {
            if (_selected_item == value) {
                return;
            }
            var old = _selected_item;
            _selected_item = value;
            if (old != null) {
                buttons[old].active = false;
            }
            buttons[value].active = true;
        }
    }
    private string _selected_item;

    public ViewSwitcher (bool show_icons = true) {
        orientation = Gtk.Orientation.HORIZONTAL;
        icon_size = Gtk.IconSize.BUTTON;
        _show_icons = true;
        _selected_item = null;
        buttons = new HashTable<string, SButton> (str_hash, str_equal);

        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        get_style_context ().add_class ("raised");
    }

    public void append (string name, string title, string? icon_name) {
        var button = new SButton (name, title, icon_name, _icon_size, _show_icons);
        this.add (button);
        buttons[name] = button;
        if (_selected_item == null) {
            _selected_item = name;
            button.active = true;
        }

        button.toggled.connect (on_button_toggled);
    }

    private void on_button_toggled (Gtk.ToggleButton button) {
        var vsbutton = (SButton) button;
        if (button.active) {
            selected_item = vsbutton.name;
        } else {
            if (_selected_item == vsbutton.name) {
                button.active = true;
            }
        }
    }

    public void set_icon_for_name (string name, string? icon_name) {
        var button = buttons[name];
        assert (button != null);

        button.icon_name = icon_name;
    }

    public void set_title_for_name (string name, string title) {
        var button = buttons[name];
        assert (button != null);

        button.title = title;
    }

    private class SButton : Gtk.ToggleButton {

        /**
         * We don't just use the image field of Gtk.Button as this may cause
         * issues with some themes.
         */
        private Gtk.Widget label_widget;

        public Gtk.IconSize icon_size {
            get {
                return _icon_size;
            }
            set {
                _icon_size = value;
                var icon = label_widget as Gtk.Image;
                if (icon != null) {
                    icon.icon_size = value;
                }
            }
        }
        private Gtk.IconSize _icon_size;

        public new string name {
            get;
            set;
        }

        public string title {
            get {
                return _title;
            }
            set {
                _title = value;
                var lbl = label_widget as Gtk.Label;
                if (lbl != null) {
                    lbl.label = value;
                }
            }
        }
        private string _title;

        public string icon_name {
            get {
                return _icon_name;
            }
            set {
                _icon_name = value;
                if (!show_icon) {
                    return;
                }
                if (value == null) {
                    use_label ();
                } else {
                    use_icon ();
                }
            }
        }
        private string _icon_name;

        public bool show_icon {
            get {
                return _show_icon;
            }
            set {
                if (!value && _show_icon && _icon_name != null) {
                    use_label ();
                } else if (value && !_show_icon && _icon_name != null) {
                    use_icon ();
                }
                _show_icon = value;
            }
        }
        private bool _show_icon;

        public SButton (
            string name, string title, string? icon_name,
            Gtk.IconSize icon_size, bool show_icon
        ) {
            this.name = name;
            this._title = title;
            this._icon_name = icon_name;
            this._icon_size = icon_size;
            this._show_icon = show_icon;

            if (icon_name != null && show_icon) {
                label_widget = new Gtk.Image.from_icon_name (icon_name, icon_size);
                label_widget.tooltip_text = _title;
            } else {
                label_widget = new Gtk.Label (_title);
            }
            add (label_widget);
        }

        private void use_icon () {
            remove (label_widget);
            label_widget = new Gtk.Image.from_icon_name (_icon_name, _icon_size);
            label_widget.tooltip_text = _title;
            add (label_widget);
            label_widget.show ();
        }

        private void use_label () {
            remove (label_widget);
            label_widget = new Gtk.Label (_title);
            add (label_widget);
            label_widget.show ();
        }
    }
}
