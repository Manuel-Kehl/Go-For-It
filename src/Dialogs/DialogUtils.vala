namespace GOFI.DialogUtils {
    public const int SPACING_SETTINGS_ROW = 6;
    public const int SPACING_SETTINGS_COLUMN = 10;

    private Gtk.Widget create_section_box (string? sect_title, Gtk.Widget contents) {
        contents.margin = 10;

        var section_frame = new Gtk.Frame (null);
        section_frame.add (contents);
        section_frame.get_style_context ().add_class ("settings-frame");

#if USE_GRANITE
        var section_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        if (sect_title != null) {
            var sect_lbl = new Gtk.Label (sect_title);
            sect_lbl.get_style_context ().add_class ("h4");
#else
        var section_box = new Gtk.Box (Gtk.Orientation.VERTICAL, SPACING_SETTINGS_ROW);

        if (sect_title != null) {
            var sect_lbl = new Gtk.Label ("<b>%s</b>".printf (sect_title));
            sect_lbl.use_markup = true;
#endif
            sect_lbl.halign = Gtk.Align.START;
            section_box.add (sect_lbl);
        }

        section_box.add (section_frame);
        return section_box;
    }

    private static void add_option (Gtk.Grid grid, ref int row, Gtk.Widget label,
                            Gtk.Widget switcher, Gtk.Widget? label2 = null)
    {
        label.halign = Gtk.Align.END;

        grid.attach (label, 0, row, 1, 1);

        if (switcher is Gtk.Switch || switcher is Gtk.Entry) {
            switcher.halign = Gtk.Align.START;
        } else {
            switcher.halign = Gtk.Align.FILL;
        }

        if (label2 != null) {
            label2.halign = Gtk.Align.START;
            label2.hexpand = true;
            grid.attach (switcher, 1, row, 1, 1);
            grid.attach (label2, 2, row, 1, 1);
        } else {
            grid.attach (switcher, 1, row, 2, 1);
            switcher.hexpand = true;
        }
        row++;
    }

    private static void apply_grid_spacing (Gtk.Grid grid) {
        grid.row_spacing = SPACING_SETTINGS_ROW;
        grid.column_spacing = SPACING_SETTINGS_COLUMN;
    }

    private static Gtk.Grid create_page_grid () {
        var grid = new Gtk.Grid ();
        apply_grid_spacing (grid);
        return grid;
    }

    public static Gtk.Widget get_explanation_widget (string explanation) {
        var image_widget = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.BUTTON);
        image_widget.tooltip_text = explanation;
        return image_widget;
    }
}
