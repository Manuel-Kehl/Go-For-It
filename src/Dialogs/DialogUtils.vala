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

        switcher.halign = Gtk.Align.START;

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

    /**
     * Restricts the maximum natural_width value in height for width layouts
     */
    private class ConstrWidthBin : Gtk.Bin {
        int max_width;

        public ConstrWidthBin (Gtk.Widget child, int max_width) {
            Object (child: child);
            this.max_width = max_width;
        }

        public override Gtk.SizeRequestMode get_request_mode () {
            return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            base.get_preferred_width (out minimum_width, out natural_width);
            natural_width = int.min (max_width, natural_width);
        }
    }

    private class ExplanationWidget : Gtk.Button {
        private Gtk.Popover explanation_popover;

        public ExplanationWidget (string explanation) {
            Object (relief: Gtk.ReliefStyle.NONE, tooltip_text: explanation);
            var image_widget = new Gtk.Image.from_icon_name (
                "dialog-information-symbolic", Gtk.IconSize.BUTTON
            );
            image_widget.show ();
            this.add (image_widget);

            explanation_popover = new Gtk.Popover (this);
            var popover_label = new Gtk.Label (explanation);
            popover_label.wrap = true;
            popover_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            popover_label.margin = 10;
            popover_label.show ();
            explanation_popover.add (new ConstrWidthBin (popover_label, 200));

            this.clicked.connect (on_clicked);

            this.get_style_context ().add_class ("no_margin");
        }

        private void on_clicked () {
            Utils.popover_show (explanation_popover);
        }
    }

    public static Gtk.Widget get_explanation_widget (string explanation) {
        return new ExplanationWidget (explanation);
    }
}
