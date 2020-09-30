namespace GOFI.DialogUtils {
    public static void add_section (Gtk.Grid grid, Gtk.Label label, ref int row) {
        label.set_markup ("<b>%s</b>".printf (label.get_text ()));
        label.halign = Gtk.Align.START;

        grid.attach (label, 0, row, 3, 1);
        row++;
    }

    public static void add_option (Gtk.Grid grid, Gtk.Widget label,
                            Gtk.Widget switcher, ref int row, int indent=1, Gtk.Widget? label2 = null)
    {
        label.margin_start = indent * 12; // indentation relative to the section label
        label.halign = Gtk.Align.END;

        grid.attach (label, 0, row, 1, 1);
        if (label2 != null) {
            var box = new  Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            box.add (switcher);
            box.add (label2);
            label2.halign = Gtk.Align.START;
            grid.attach (box, 1, row, 2, 1);
        } else {
            grid.attach (switcher, 1, row, 2, 1);
            switcher.hexpand = true;

            if (switcher is Gtk.Switch || switcher is Gtk.Entry) {
                switcher.halign = Gtk.Align.START;
            } else {
                switcher.halign = Gtk.Align.FILL;
            }
        }
        row++;
    }

    public static void add_explanation (Gtk.Grid grid, Gtk.Label label, ref int row) {
        label.hexpand = true;
        label.margin_start = 20; // indentation relative to the section label
        label.halign = Gtk.Align.START;

        grid.attach (label, 0, row, 3, 1);
        row++;
    }

    public static void apply_grid_spacing (Gtk.Grid grid) {
        grid.row_spacing = 6;
        grid.column_spacing = 10;
    }

    public static Gtk.Grid create_page_grid () {
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
