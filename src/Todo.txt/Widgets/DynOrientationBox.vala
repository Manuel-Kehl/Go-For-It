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

// Simple 2 widget layout that chooses a horizontal or vertical layout depending
// on the available width.
class GOFI.TXT.DynOrientationBox : Gtk.Container {
    private Gtk.Widget pri_widget;
    private Gtk.Widget sec_widget;

    public int h_spacing {
        get {
            return _h_spacing;
        }
        set {
            _h_spacing = value;
        }
    }
    private int _h_spacing;

    public int v_spacing {
        get {
            return _v_spacing;
        }
        set {
            _v_spacing = value;
        }
    }
    private int _v_spacing;

    public DynOrientationBox (int h_spacing = 0, int v_spacing = 0) {
        base.set_has_window (false);
        base.set_can_focus (true);
        base.set_redraw_on_allocate (false);

        this.handle_border_width ();

        this._h_spacing = h_spacing;
        this._v_spacing = v_spacing;
        this.sec_widget = null;
        this.pri_widget = null;
    }

    public override void add (Gtk.Widget widget) {
        if (pri_widget == null) {
            set_primary_widget (widget);
        } else if (sec_widget == null) {
            set_secondary_widget (widget);
        }
    }

    public void set_primary_widget (Gtk.Widget widget) {
        pri_widget = widget;
        widget.set_parent (this);
        widget.set_child_visible (true);
    }

    public void set_secondary_widget (Gtk.Widget widget) {
        sec_widget = widget;
        widget.set_parent (this);
        widget.set_child_visible (true);
    }

    public override void remove (Gtk.Widget widget) {
        if (sec_widget == widget) {
            sec_widget = null;
        } else if (pri_widget == widget) {
            pri_widget = null;
        } else {
            return;
        }
        widget.unparent ();
        if (visible && widget.visible) {
            queue_resize ();
        }
    }

    public override void forall_internal (bool include_internals, Gtk.Callback callback) {
        if (pri_widget != null) {
            callback (pri_widget);
        }
        if (sec_widget != null) {
            callback (sec_widget);
        }
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    private int get_minimum_width (Gtk.Widget child) {
        int minimum;

        child.get_preferred_width (out minimum, null);
        return minimum;
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        if (pri_widget == null || !pri_widget.visible) {
            if (sec_widget == null || !sec_widget.visible) {
                minimum_width = 0;
                natural_width = 0;
                return;
            }

            sec_widget.get_preferred_width (
                out minimum_width, out natural_width
            );
        } else if (sec_widget == null || !sec_widget.visible) {
            pri_widget.get_preferred_width (
                out minimum_width, out natural_width
            );
        } else {
            int pri_min;
            int pri_nat;
            int sec_min;

            pri_widget.get_preferred_width (out pri_min, out pri_nat);
            sec_widget.get_preferred_width (out sec_min, null);

            minimum_width = int.max (pri_min, sec_min);
            natural_width = pri_nat + _h_spacing + sec_min;
        }
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        get_preferred_height_for_width (get_minimum_width (this), out minimum_height, out natural_height);
    }

    private void size_allocate_single (Gtk.Allocation allocation, Gtk.Widget child) {
        Gtk.Allocation child_allocation = Gtk.Allocation ();

        child_allocation.x = allocation.x;
        child_allocation.y = allocation.y;
        child_allocation.width = allocation.width;
        child_allocation.height = allocation.height;
        int baseline = get_baseline (allocation);
        child.size_allocate_with_baseline (child_allocation, baseline);
    }

    private int get_baseline (Gtk.Allocation allocation) {
        int baseline = this.get_allocated_baseline ();
        if (baseline < 0) {
            int min_height, nat_height, baseline_min;
            get_preferred_height_and_baseline_for_width (
                allocation.width, out min_height, out nat_height,
                out baseline_min, out baseline
            );
            if (allocation.height < nat_height) {
                baseline = baseline_min;
            }
        }
        return baseline;
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        if (pri_widget == null || !pri_widget.visible) {
            if (sec_widget != null && sec_widget.visible) {
                size_allocate_single (allocation, sec_widget);
            }
            base.size_allocate (allocation);
            return;
        }
        if (sec_widget == null || !sec_widget.visible) {
            size_allocate_single (allocation, pri_widget);
            base.size_allocate (allocation);
            return;
        }

        Gtk.Allocation pri_allocation = Gtk.Allocation ();
        Gtk.Allocation sec_allocation = Gtk.Allocation ();

        var height = allocation.height;
        var available_width = allocation.width - _h_spacing;
        int pri_natural;
        pri_widget.get_preferred_width (null, out pri_natural);
        var sec_minimum = get_minimum_width (sec_widget);
        int baseline = get_baseline (allocation);

        if (available_width >= pri_natural + sec_minimum) {

            pri_allocation.width = available_width - sec_minimum;
            pri_allocation.height = height;
            sec_allocation.width = available_width - pri_allocation.width;
            sec_allocation.height = height;

            pri_allocation.y = allocation.y;
            sec_allocation.y = allocation.y;

            if (get_direction () == Gtk.TextDirection.RTL) {
                sec_allocation.x = allocation.x;
                pri_allocation.x  = allocation.x + _h_spacing + sec_allocation.width;;
            } else {
                pri_allocation.x  = allocation.x;
                sec_allocation.x = allocation.x + _h_spacing + pri_allocation.width;
            }
            pri_widget.size_allocate_with_baseline (pri_allocation, baseline);
            sec_widget.size_allocate_with_baseline (sec_allocation, baseline);
        } else {
            int sec_height;
            available_width += _h_spacing;
            sec_widget.get_preferred_height_for_width (available_width, out sec_height, null);

            pri_allocation.x = allocation.x;
            pri_allocation.y = allocation.y;
            pri_allocation.width = available_width;
            pri_allocation.height = height - sec_height - _v_spacing;

            sec_allocation.x = allocation.x;
            sec_allocation.y = allocation.y + pri_allocation.height + _v_spacing;
            sec_allocation.width = available_width;
            sec_allocation.height = sec_height;
            pri_widget.size_allocate_with_baseline (pri_allocation, baseline);
            sec_widget.size_allocate (sec_allocation);
        }

        base.size_allocate (allocation);
    }

    public override void get_preferred_height_and_baseline_for_width (
        int width, out int minimum_height, out int natural_height,
        out int minimum_baseline, out int natural_baseline
    ) {
        if (width < 0) {
            width = get_minimum_width (this);
        }

        if (pri_widget == null || !pri_widget.visible) {
            if (sec_widget == null || !sec_widget.visible) {
                minimum_height = 0;
                natural_height = 0;
                minimum_baseline = -1;
                natural_baseline = -1;
                return;
            }

            sec_widget.get_preferred_height_and_baseline_for_width (
                width,
                out minimum_height, out natural_height,
                out minimum_baseline, out natural_baseline
            );
            return;
        } else if (sec_widget == null || !sec_widget.visible) {
            pri_widget.get_preferred_height_and_baseline_for_width (
                width,
                out minimum_height, out natural_height,
                out minimum_baseline, out natural_baseline
            );
            return;
        }

        int pri_natural;
        pri_widget.get_preferred_width (null, out pri_natural);
        var sec_minimum = get_minimum_width (sec_widget);

        int pri_min;
        int pri_nat;
        int sec_min;
        int sec_nat;

        var available_width = width - _h_spacing;

        if (available_width >= pri_natural + sec_minimum) {
            // we can place the widgets next to eachother;
            var pri_width  = available_width - sec_minimum;
            var sec_width = available_width - pri_width;
            int pri_base_min;
            int pri_base_nat;
            int sec_base_min;
            int sec_base_nat;

            pri_widget.get_preferred_height_and_baseline_for_width (
                pri_width, out pri_min, out pri_nat, out pri_base_min, out pri_base_nat
            );
            sec_widget.get_preferred_height_and_baseline_for_width (
                sec_width, out sec_min, out sec_nat, out sec_base_min, out sec_base_nat
            );

            minimum_baseline = int.max (pri_base_min, sec_base_min);
            natural_baseline = int.max (pri_base_nat, sec_base_nat);

            if (minimum_baseline > 0) {
                int min_below = int.max (
                    pri_min - int.max (0, pri_base_min),
                    sec_min - int.max (0, sec_base_min)
                );
                int nat_below = int.max (
                    pri_nat - int.max (0, pri_base_nat),
                    sec_nat - int.max (0, sec_base_nat)
                );
                minimum_height = minimum_baseline + min_below;
                natural_height = natural_baseline + nat_below;
            } else {
                minimum_height = int.max (pri_min, sec_min);
                natural_height = int.max (pri_nat, sec_nat);
            }
        } else {
            // we must place the widgets below eachother
            available_width += _h_spacing;

            pri_widget.get_preferred_height_and_baseline_for_width (
                available_width, out pri_min, out pri_nat,
                out minimum_baseline, out natural_baseline
            );
            sec_widget.get_preferred_height_for_width (
                available_width, out sec_min, out sec_nat
            );
            minimum_height = pri_min + _v_spacing + sec_min;
            natural_height = pri_nat + _v_spacing + sec_nat;
        }
    }
}
