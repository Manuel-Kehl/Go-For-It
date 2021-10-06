/* Copyright 2020 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

// This basic horizontal box as Gtk.Box has some undesirable behavior when using
// a height-for-width child.
// This container also aligns the start and end widgets above the baseline of
// the center widget, if the space is available.
class GOFI.DragListRowBox : Gtk.Container {
    private Gtk.Widget start_widget;
    private Gtk.Widget center_widget;
    private Gtk.Widget end_widget;

    public int h_spacing {
        get {
            return _h_spacing;
        }
        set {
            _h_spacing = value;
        }
    }
    private int _h_spacing;

    public DragListRowBox (int h_spacing = 0) {
        base.set_has_window (false);
        base.set_can_focus (false);
        base.set_redraw_on_allocate (false);

        this._h_spacing = h_spacing;

        this.handle_border_width ();

        this.start_widget = null;
        this.center_widget = null;
        this.end_widget = null;
    }

    public override void add (Gtk.Widget widget) {
        if (center_widget == null) {
            set_start_widget (widget);
        }
    }

    public void set_start_widget (Gtk.Widget? widget) {
        _remove (start_widget);
        start_widget = widget;
        _set_child_parent (widget);
    }

    public void set_center_widget (Gtk.Widget? widget) {
        _remove (center_widget);
        center_widget = widget;
        _set_child_parent (widget);
    }

    public void set_end_widget (Gtk.Widget? widget) {
        _remove (end_widget);
        end_widget = widget;
        _set_child_parent (widget);
    }

    private void _set_child_parent (Gtk.Widget? widget) {
        if (widget == null) {
            return;
        }
        widget.set_parent (this);
        widget.set_child_visible (true);
    }

    private void _remove (Gtk.Widget? widget) {
        if (widget == null) {
            return;
        }
        widget.unparent ();
        if (visible && widget.visible) {
            queue_resize ();
        }
    }

    public override void remove (Gtk.Widget widget) {
        if (end_widget == widget) {
            end_widget = null;
        } else if (center_widget == widget) {
            center_widget = null;
        } else if (start_widget == widget) {
            start_widget = null;
        } else {
            return;
        }
        _remove (widget);
    }

    public override void forall_internal (bool include_internals, Gtk.Callback callback) {
        if (start_widget != null) {
            callback (start_widget);
        }
        if (center_widget != null) {
            callback (center_widget);
        }
        if (end_widget != null) {
            callback (end_widget);
        }
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        minimum_width = 0;
        natural_width = 0;

        if (center_widget != null && center_widget.visible) {
            center_widget.get_preferred_width (out minimum_width, out natural_width);
        }

        int edge_min = get_edge_width ();

        if (edge_min > 0) {
            minimum_width += 2 * edge_min + 2 * _h_spacing;
            natural_width += 2 * edge_min + 2 * _h_spacing;
        }
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        int minimum_width;
        get_preferred_width (out minimum_width, null);
        get_preferred_height_for_width (minimum_width, out minimum_height, out natural_height);
    }

    private int get_edge_width () {
        int width = 0;
        // Passing null to out parameters sometimes causes issues in Gtk methods
        // lets play it safe
        int unused;

        if (start_widget != null && start_widget.visible) {
            start_widget.get_preferred_width (out width, out unused);
        }
        if (end_widget != null && end_widget.visible) {
            int end_min;
            end_widget.get_preferred_width (out end_min, out unused);

            width = int.max (end_min, width);
        }
        return width;
    }

    private int get_edge_height (int width) {
        int height = 0;
        // Passing null to out parameters sometimes causes issues in Gtk methods
        // lets play it safe
        int unused;

        if (start_widget != null && start_widget.visible) {
            start_widget.get_preferred_height_for_width (width, out height, out unused);
        }
        if (end_widget != null && end_widget.visible) {
            int end_min;
            end_widget.get_preferred_height_for_width (width, out end_min, out unused);

            height = int.max (end_min, height);
        }
        return height;
    }

    private void calculate_widget_placement (int width, out int height, out Gtk.Allocation start_alloc, out Gtk.Allocation center_alloc) {
        int unused;
        start_alloc = {};
        center_alloc = {};

        start_alloc.x = 0;
        start_alloc.width = get_edge_width ();
        center_alloc.x = 0;
        center_alloc.width = width;

        if (start_alloc.width > 0) {
            center_alloc.x += start_alloc.width + _h_spacing;
            center_alloc.width -= start_alloc.width * 2 + _h_spacing * 2;
        }

        int center_v_center, edge_v_center;

        start_alloc.height = get_edge_height (start_alloc.width);

        edge_v_center = start_alloc.height / 2;

        if (center_widget != null && center_widget.visible) {
            center_widget.get_preferred_height_for_width (int.MAX/2, out center_alloc.height, out unused);
            center_v_center = center_alloc.height / 2;

            center_widget.get_preferred_height_for_width (center_alloc.width, out center_alloc.height, out unused);
        } else {
            center_v_center = edge_v_center;
            center_alloc.height = start_alloc.height;
        }

        int centerline = int.max (edge_v_center, center_v_center);
        start_alloc.y = centerline - edge_v_center;
        center_alloc.y = centerline - center_v_center;

        height = int.max (
            start_alloc.y + start_alloc.height,
            center_alloc.y + center_alloc.height
        );
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        Gtk.Allocation edge_alloc, center_alloc;
        calculate_widget_placement (allocation.width, null, out edge_alloc, out center_alloc);
        edge_alloc.x += allocation.x;
        center_alloc.x += allocation.x;
        edge_alloc.y += allocation.y;
        center_alloc.y += allocation.y;

        if (start_widget != null && start_widget.visible) {
            start_widget.size_allocate (edge_alloc);
        }
        if (center_widget != null && center_widget.visible) {
            center_widget.size_allocate (center_alloc);
        }
        if (end_widget != null && end_widget.visible) {
            edge_alloc.x = center_alloc.x + center_alloc.width + h_spacing;
            end_widget.size_allocate (edge_alloc);
        }

        base.size_allocate (allocation);
    }

    public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
        if (width < 0) {
            get_preferred_width (out width, null);
        }

        calculate_widget_placement (width, out minimum_height, null, null);
        natural_height = minimum_height;
    }
}
