/* Copyright 2014-2016 Go For It! developers
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
 * A widget for displaying and manipulating task lists.
 */
public class DragListBox : Gtk.Bin {
    private DragListBoxRow? hover_row_top;
    private DragListBoxRow? hover_row_bottom;
    internal DragListBoxRow? drag_row;
    private bool should_scroll = false;
    private bool scrolling = false;
    private bool scroll_up;

    private bool ranges_set = false;
    private IntRange input_range;
    private IntRange drag_row_range;
    private IntRange current_hover_range;

    private const int SCROLL_STEP_SIZE = 8;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;

    internal DragListBoxModel? model;
    private DragListBoxCreateWidgetFunc? create_widget_func;

    private Gtk.ListBox listbox;
    private bool internal_signal;

    public Gtk.Adjustment vadjustment {
        public get {
            return listbox.get_adjustment ();
        }
        public set {
            listbox.set_adjustment (value);
        }
    }

    public virtual signal void activate_cursor_row () {
        listbox.activate_cursor_row ();
    }

    public virtual signal void row_activated (DragListBoxRow row) {
        return;
    }

    private void on_list_row_activated (Gtk.ListBoxRow row) {
        row_activated ((DragListBoxRow) row);
    }

    public virtual signal void move_cursor (Gtk.MovementStep step, int count) {
        internal_signal = true;
        listbox.move_cursor (step, count);
    }

    private void on_list_move_cursor (Gtk.MovementStep step, int count) {
        if (!internal_signal) {
            move_cursor (step, count);
        }
    }

    public virtual signal void row_selected (DragListBoxRow? row) {
        return;
    }

    private void on_list_row_selected (Gtk.ListBoxRow? row) {
        row_selected ((DragListBoxRow) row);
    }

    public virtual signal void row_received_with_model (DragListBoxRow row, int index) {
        return;
    }

    public DragListBox () {
        listbox = new Gtk.ListBox ();
        listbox.set_selection_mode (Gtk.SelectionMode.SINGLE);
        listbox.set_activate_on_single_click (false);
        Gtk.drag_dest_set (
            listbox, Gtk.DestDefaults.ALL, dlb_entries, Gdk.DragAction.MOVE
        );

        internal_signal = false;

        base.add(listbox);
        connect_signals ();
    }

    private void connect_signals () {
        listbox.move_cursor.connect (on_list_move_cursor);
        listbox.row_activated.connect_after (on_list_row_activated);
        listbox.row_selected.connect (on_list_row_selected);
        listbox.drag_motion.connect (on_list_drag_motion);
        listbox.drag_leave.connect (on_list_drag_leave);
        listbox.drag_data_received.connect (on_list_drag_data_received);
    }

    public void bind_model (
        DragListBoxModel? model,
        owned DragListBoxCreateWidgetFunc? create_widget_func
    ) {
        if (model != null && create_widget_func == null) {
            return;
        }
        listbox.@foreach((widget) => {
            remove(widget);
        });
        this.model = model;
        this.create_widget_func = (owned) create_widget_func;

        for (uint i = 0; i < model.get_n_items (); i++) {
            var row = this.create_widget_func(model.get_item (i));
            _add (row);
        }

        model.items_changed.connect (on_model_items_changed);
        model.item_moved.connect (on_model_item_moved);
    }

    private void on_model_items_changed (uint index, uint removed, uint added) {
        for (uint i = 0; i < removed ; i++) {
            listbox.remove (get_row_at_index((int)index));
        }
        for (uint i = index; i < index + added; i++) {
            _insert (create_widget_func (model.get_item (i)), (int)i);
        }
    }

    private void on_model_item_moved (uint old_index, uint new_index) {
        _move_row(
            (DragListBoxRow)get_row_at_index((int)old_index), (int)new_index
        );
    }

    public DragListBoxRow? get_selected_row () {
        return (DragListBoxRow) listbox.get_selected_row ();
    }

    public override void add (Gtk.Widget widget) {
        insert (widget, -1);
    }

    private inline void _add (Gtk.Widget widget) {
        _insert (widget, -1);
    }


    public void insert (Gtk.Widget widget, int position) {
        if (model != null) {
            _insert (widget, position);
        }
    }

    private void _insert (Gtk.Widget widget, int position) {
        DragListBoxRow row = widget as DragListBoxRow;

        if (row == null) {
            row = new DragListBoxRow ();
            row.get_content_area ().add(widget);
        }

        listbox.insert (row, position);
        if (listbox.get_selected_row () == null) {
            listbox.select_row (row);
        }
    }

    public override void remove (Gtk.Widget widget) {
        if (widget.get_parent () == this) {
            base.remove (widget);
        } else if (model == null) {
            listbox.remove (widget);
        }
    }

    public List<unowned DragListBoxRow> get_rows () {
        return (List<unowned DragListBoxRow>) listbox.get_children ();
    }

    public void move_row (DragListBoxRow row, int index) {
        if (model != null) {
            return;
        }
        Gtk.ListBox row_parent = row.get_parent () as Gtk.ListBox;

        if (row_parent == listbox) {
            _move_row (row, index);
        }
    }

    private void _move_row (DragListBoxRow row, int index) {
        int _index = index;
        int old_index = row.get_index ();
        if (old_index != index) {
            if (_index > old_index) {
                _index--;
            }
            listbox.remove (row);
            listbox.insert (row, _index);
            if (model != null) {
                if (index < 0) {
                    index = (int)model.get_n_items () - 1;
                }
                model.move_item (old_index, index);
            }
        }
    }

    public DragListBoxRow get_row_at_index (int index) {
        return (DragListBoxRow)listbox.get_row_at_index (index);
    }

    public void set_filter_func (DragListBoxFilterFunc? filter_func) {
        listbox.set_filter_func ((row) => {
            return filter_func ((DragListBoxRow) row);
        });
    }

    public void invalidate_filter () {
        listbox.invalidate_filter ();
    }

    private void set_ranges () {
        if (ranges_set) {
            return;
        }
        input_range = {min: 0, max: -1};
        current_hover_range = {min: 0, max: -1};
        drag_row_range = {min: 0, max: -1};

        int last_index = (int)listbox.get_children ().length () - 1;
        DragListBoxRow first = get_row_at_index (0);
        DragListBoxRow last = get_row_at_index (last_index);

        Gtk.Allocation alloc;
        first.get_allocation (out alloc);
        input_range.min = alloc.y + 1;
        last.get_allocation (out alloc);
        input_range.max = alloc.y + alloc.height - 1;

        set_drag_row_range ();
        ranges_set = true;
    }

    private void set_drag_row_range () {
        if (drag_row == null) {
            return;
        }

        int drag_row_index = drag_row.get_index ();
        Gtk.Allocation alloc;
        drag_row.get_allocation (out alloc);

        if (drag_row_index > 1) {
            drag_row_range.min = get_widget_middle(
                listbox.get_row_at_index(drag_row_index - 1)
            );
        } else {
            drag_row_range.min = alloc.y;
        }
        var next_row = listbox.get_row_at_index (drag_row_index + 1);
        if (next_row != null) {
            drag_row_range.max = get_widget_middle (next_row);
        } else {
            drag_row_range.max = alloc.y + alloc.height;
        }
    }

    private int get_widget_middle (Gtk.Widget widget) {
        Gtk.Allocation alloc;

        widget.get_allocation (out alloc);
        return alloc.y + alloc.height/2;
    }

    private bool on_list_drag_motion (
        Gdk.DragContext context, int x, int y, uint time_
    ) {
        set_ranges ();
        y = input_range.clamp (y);
        if (!current_hover_range.contains (y)) {
            remove_hover_style ();
            set_hover_rows (y);
            add_hover_style ();
        }

        check_scroll (y);
        if(should_scroll && !scrolling) {
            scrolling = true;
            Timeout.add (SCROLL_DELAY, scroll);
        }

        return true;
    }

    private void set_hover_rows (int y) {
        if (drag_row_range.contains (y)) {
            set_hover_rows_deadzone ();
        } else {
            set_hover_rows_from_y (y);
        }
    }

    private void set_hover_rows_deadzone () {
        hover_row_bottom = null;
        hover_row_top = null;
        current_hover_range = drag_row_range;
    }

    private void set_hover_rows_from_y (int y) {
        var row = (DragListBoxRow)listbox.get_row_at_y (y);
        int hover_row_middle = get_widget_middle (row);

        if (y < hover_row_middle) {
            hover_row_bottom = row;
            hover_row_top = get_row_at_index (row.get_index () - 1);
            current_hover_range.max = hover_row_middle;
            if (hover_row_top != null) {
                current_hover_range.min = get_widget_middle (hover_row_top);
            } else {
                current_hover_range.min = input_range.min;
            }
        } else {
            hover_row_top = row;
            hover_row_bottom = get_row_at_index (row.get_index () + 1);
            current_hover_range.min = hover_row_middle;
            if (hover_row_bottom != null) {
                current_hover_range.max = get_widget_middle (hover_row_bottom);
            } else {
                current_hover_range.max = input_range.max;
            }
        }
    }

    private void remove_hover_style () {
        if (hover_row_top != null) {
            hover_row_top.get_style_context ().remove_class ("drag-hover-top");
        }
        if (hover_row_bottom != null) {
            hover_row_bottom.get_style_context ().remove_class ("drag-hover-bottom");
        }
    }

    private void add_hover_style () {
        if (hover_row_top != null) {
            hover_row_top.get_style_context ().add_class ("drag-hover-top");
        }
        if (hover_row_bottom != null) {
            hover_row_bottom.get_style_context ().add_class ("drag-hover-bottom");
        }
    }

    private void on_list_drag_leave (Gdk.DragContext context, uint time_) {
        should_scroll = false;
        ranges_set = false;
        remove_hover_style ();
    }

    private void check_scroll (int y) {
        Gtk.Adjustment adjustment = listbox.get_adjustment ();
        if (adjustment == null) {
            should_scroll = false;
            return;
        }
        double adjustment_min = adjustment.value;
        double adjustment_max = adjustment.page_size + adjustment_min;
        double show_min = double.max(0, y - SCROLL_DISTANCE);
        double show_max = double.min(adjustment.upper, y + SCROLL_DISTANCE);
        if(adjustment_min > show_min) {
            should_scroll = true;
            scroll_up = true;
        } else if (adjustment_max < show_max){
            should_scroll = true;
            scroll_up = false;
        } else {
            should_scroll = false;
        }
    }

    private bool scroll () {
        Gtk.Adjustment adjustment = listbox.get_adjustment ();
        if (should_scroll) {
            if(scroll_up) {
                adjustment.value -= SCROLL_STEP_SIZE;
            } else {
                adjustment.value += SCROLL_STEP_SIZE;
            }
        } else {
            scrolling = false;
        }
        return should_scroll;
    }

    private void on_list_drag_data_received (
        Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint info, uint time_
    ) {
        DragListBoxRow row;

        int index = -1;
        remove_hover_style ();
        if (hover_row_bottom != null) {
            index = hover_row_bottom.get_index ();
        } else if (hover_row_top != null) {
            index = hover_row_top.get_index () + 1;
        }
        if (index >= 0 && selection_data.get_data_type().name () == "DRAG_LIST_BOX_ROW") {
            row = ((DragListBoxRow[])selection_data.get_data ())[0];
            drag_insert_row (row, index);
        }
        drag_row = null;
        hover_row_top = null;
        hover_row_bottom = null;
        ranges_set = false;
    }

    private void drag_insert_row (DragListBoxRow row, int index) {
        DragListBox row_draglist = row.get_drag_list_box ();

        if (row_draglist == this) {
            _move_row (row, index);
        } else {
            if (model == null && row_draglist.model == null) {
                row.get_parent ().remove (row);
                listbox.insert (row, index);
            } else {
                row_received_with_model (row, index);
            }
        }
    }
}

public delegate bool DragListBoxFilterFunc (DragListBoxRow row);

private const Gtk.TargetEntry[] dlb_entries = {
    {"DRAG_LIST_BOX_ROW", Gtk.TargetFlags.SAME_APP, 0}
};

private struct IntRange {
    public int min;
    public int max;
    public inline bool contains (int val) {return val >= min && val <= max;}
    public inline int clamp (int val) {return val.clamp (min, max);}
}

public class DragListBoxRow : Gtk.ListBoxRow {
    private Gtk.EventBox handle;
    private Gtk.Box layout;
    private Gtk.Box content;
    private Gtk.Image image;

    public DragListBoxRow () {
        layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        layout.margin_start = 5;
        layout.margin_end = 5;
        add (layout);

        content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        content.margin_end = 5;
        content.hexpand = true;

        layout.add (content);

        handle = new Gtk.EventBox ();
        image = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.MENU);
        handle.add (image);
        layout.add (handle);

        Gtk.drag_source_set (
            handle, Gdk.ModifierType.BUTTON1_MASK, dlb_entries, Gdk.DragAction.MOVE
        );
        handle.drag_begin.connect (handle_drag_begin);
        handle.drag_data_get.connect (handle_drag_data_get);
    }

    public unowned Gtk.Box get_content_area () {
        return content;
    }

    public DragListBox? get_drag_list_box () {
        Gtk.Widget? parent = this.get_parent ();
        if (parent != null) {
            return parent.get_parent () as DragListBox;
        }
        return null;
    }

    private void handle_drag_begin (Gdk.DragContext context) {
        DragListBox draglist;
        Gtk.Allocation alloc;
        Cairo.Surface surface;
        Cairo.Context cr;
        int x, y;

        get_allocation (out alloc);
        surface = new Cairo.ImageSurface (
            Cairo.Format.ARGB32, alloc.width, alloc.height
        );
        cr = new Cairo.Context (surface);

        draglist = get_drag_list_box ();
        if (draglist != null)
            draglist.drag_row = this;

        get_style_context ().add_class ("drag-icon");
        draw (cr);
        get_style_context ().remove_class ("drag-icon");

        handle.translate_coordinates (this, 0, 0, out x, out y);
        surface.set_device_offset (-x, -y);
        Gtk.drag_set_icon_surface (context, surface);
    }

    private void handle_drag_data_get (
        Gdk.DragContext context, Gtk.SelectionData selection_data,
        uint info, uint time_
    ) {
        uchar[] data = new uchar[(sizeof (Gtk.Widget))];
        ((Gtk.Widget[])data)[0] = this;
        selection_data.set (
            Gdk.Atom.intern_static_string ("DRAG_LIST_BOX_ROW"), 32, data
        );
    }
}
