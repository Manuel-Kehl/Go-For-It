/* Copyright 2017-2020 Go For It! developers
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
 * A Gtk.ListBox based widget with drag and drop support.
 *
 * If this contains any rows exactly one will be selected at all times.
 *
 * Row headers are not supported.
 */
public class GOFI.DragList : Gtk.Bin {
    private Gtk.ListBox listbox;

    internal DragListModel? model;
    private DragListCreateWidgetFunc? create_widget_func;

    private DragListRow? hover_row_top;
    private DragListRow? hover_row_bottom;
    private DragListRow? selected_row;
    internal DragListRow? drag_row;
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

    // To block recursively emitting and calling signals
    private bool internal_signal;
    // Do not emit row_selected if a row can be selected
    private bool block_row_selected;

    /**
     * Adjustment used for scrolling.
     */
    public Gtk.Adjustment vadjustment {
        public get {
            return listbox.get_adjustment ();
        }
        public set {
            listbox.set_adjustment (value);
        }
    }

    /**
     * Activates the currently selected row.
     */
    public virtual signal void activate_cursor_row () {
        listbox.activate_cursor_row ();
    }

    /**
     * The row_activated signal is emitted when a row has been activated by the.
     * user.
     */
    public virtual signal void row_activated (DragListRow row) {
        return;
    }

    private void on_list_row_activated (Gtk.ListBoxRow row) {
        row_activated ((DragListRow) row);
    }

    /**
     * Selects the row count*step positions away from the currently selected row.
     */
    [Signal (action = true)]
    public virtual signal void move_cursor (Gtk.MovementStep step, int count) {
        internal_signal = true;
        listbox.move_cursor (step, count);
    }

    [Signal (action = true)]
    public virtual signal void move_selected_row (int offset) {
        if (selected_row == null) {
            return;
        }
        _move_row (selected_row, offset, false);
    }

    private void on_list_move_cursor (Gtk.MovementStep step, int count) {
        if (!internal_signal) {
            move_cursor (step, count);
        }
    }

    /**
     * The row_selected signal is emitted when a new row is selected, or null.
     * when the last row is removed.
     */
    public virtual signal void row_selected (DragListRow? row) {
        selected_row = row;
        return;
    }

    private void on_list_row_selected (Gtk.ListBoxRow? row) {
        if (!block_row_selected) {
            row_selected ((DragListRow) row);
        }
    }

    /**
     * The row_received_with_model is emitted when this receives a row when a
     * model is bound to this or to the current parent DragList of the row.
     *
     * @param row Row that was received
     * @param index index at which it would have been inserted in
     */
    public virtual signal void row_received_with_model (DragListRow row, int index) {
        return;
    }

    public DragList () {
        listbox = new Gtk.ListBox ();
        listbox.set_selection_mode (Gtk.SelectionMode.BROWSE);
        listbox.set_activate_on_single_click (false);
        selected_row = null;
        Gtk.drag_dest_set (
            listbox, Gtk.DestDefaults.ALL, dlb_entries, Gdk.DragAction.MOVE
        );

        internal_signal = false;
        block_row_selected = false;

        add (listbox);
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

    /**
     * Binds model to this.
     *
     * If this was already bound to a model, that previous binding is destroyed.
     *
     * The contents of this are cleared and then filled with widgets that
     * represent items from model. this is updated whenever model changes.
     *
     * If model is null, this is left empty.
     *
     * It is undefined to add, remove or move widgets directly
     * (for example, with insert_row or add_row) while this is bound to a model.
     *
     * @paran model the DragListModel to be bound to this
     * @param create_widget_func a function that creates Widgets for items or null in
     * case you also passed null as model
     */
    public void bind_model (
        DragListModel? model, owned DragListCreateWidgetFunc? create_widget_func
    ) {
        if (model == null) {
            assert (create_widget_func == null);
        }

        disconnect_model_signals ();
        listbox.@foreach ((widget) => {
            remove (widget);
        });

        this.model = model;
        this.create_widget_func = (owned) create_widget_func;

        if (this.model == null) {
            return;
        }

        for (uint i = 0; i < model.get_n_items (); i++) {
            var row = this.create_widget_func (model.get_item (i));
            _add_row (row);
        }

        model.items_changed.connect (on_model_items_changed);
        model.item_moved.connect (on_model_item_moved);
    }

    private void disconnect_model_signals () {
        if (this.model != null) {
            this.model.items_changed.disconnect (on_model_items_changed);
            this.model.item_moved.disconnect (on_model_item_moved);
        }
    }

    private void on_model_items_changed (uint index, uint removed, uint added) {
        bool need_to_select_closest = false;
        bool need_to_set_focus = false;
        block_row_selected = true;
        if (removed > 0 && added == 0) {
            DragListRow selected_row = get_selected_row ();
            assert (selected_row != null);
            uint selected_index = selected_row.get_index ();
            if (index <= selected_index && index + removed > selected_index) {
                need_to_select_closest = true;
                if (selected_row.has_focus) {
                    need_to_set_focus = true;
                } else {
                    var row_child = selected_row.get_focus_child ();
                    if (row_child != null && row_child.has_focus) {
                        need_to_set_focus = true;
                    }
                }
            }
        }
        for (uint i = 0; i < removed ; i++) {
            var row = get_row_at_index ((int)index);
            listbox.remove (row);

            // Make sure that the row isn't selected anymore.
            // Gtk.ListBox doesn't do this, causing buggy behavior in certain
            // situations.
            if (row.is_selected ()) {
                row.selectable = false;
                row.selectable = true;
            }
        }
        if (added > 0) {
            block_row_selected = false;
        }
        for (uint i = index; i < index + added; i++) {
            _insert_row (create_widget_func (model.get_item (i)), (int)i);
        }
        if (need_to_select_closest) {
            select_closest_to ((int)index);
            block_row_selected = false;
        }
        if (need_to_set_focus && selected_row != null) {
            selected_row.grab_focus ();
        }
    }

    private void on_model_item_moved (uint old_index, uint new_index) {
        _move_row (
            (DragListRow)get_row_at_index ((int)old_index), (int)new_index, false
        );
    }

    /**
     * Returns the currently selected row.
     */
    public unowned DragListRow? get_selected_row () {
        return selected_row;
    }

    /**
     * Make row the currently selected row.
     *
     * @param row DragListRow to select
     */
    public void select_row (DragListRow row) {
        listbox.select_row (row);
    }

    /**
     * Used to select a row after the selected row was removed
     */
    private void select_closest_to (int index) {
        DragListRow? next = get_row_at_index (index);
        if (next == null) {
            next = get_row_at_index (index - 1);
        }
        listbox.select_row (next);
        row_selected (next);
    }

    /**
     * Sets the placeholder widget that is shown in the list when it doesn't
     * display any visible children.
     */
    public void set_placeholder (Gtk.Widget? placeholder) {
        listbox.set_placeholder (placeholder);
    }

    public void add_row (Gtk.Widget widget) {
        insert_row (widget, -1);
    }

    private inline void _add_row (Gtk.Widget widget) {
        _insert_row (widget, -1);
    }

    /**
     * Insert the widget into the this at position.
     *
     * If position is -1, or larger than the total number of items in the this,
     * then the child will be appended to the end.
     *
     * @param widget the Widget to add
     * @param position the position to insert child in
     */
    public void insert_row (Gtk.Widget widget, int position) {
        if (model == null) {
            _insert_row (widget, position);
        }
    }

    private void _insert_row (Gtk.Widget widget, int position) {
        DragListRow row = widget as DragListRow;

        if (row == null) {
            row = new DragListRow ();
            row.set_center_widget (widget);
        }

        listbox.insert (row, position);
        if (listbox.get_selected_row () == null) {
            listbox.select_row (row);
            assert (listbox.get_selected_row () == row);
        }
    }

    public void remove_row (DragListRow row) {
        assert (model == null);
        if (row == listbox.get_selected_row ()) {
            block_row_selected = true;
            int index = row.get_index ();
            listbox.remove (row);
            select_closest_to (index);

            // Make sure that the row isn't selected anymore.
            // Gtk.ListBox doesn't do this, causing buggy behavior in certain
            // situations.
            if (row.is_selected ()) {
                row.selectable = false;
                row.selectable = true;
            }

            block_row_selected = false;
        } else {
            listbox.remove (row);
        }
    }

    /**
     * Returns all rows contained in this.
     */
    public List<unowned DragListRow> get_rows () {
        return (List<unowned DragListRow>) listbox.get_children ();
    }

    /**
     * Moves row to index.
     *
     * @param row DragListRow to be moved
     * @param index the index to move the row to
     */
    public void move_row (DragListRow row, int index) {
        Gtk.ListBox row_parent = row.get_parent () as Gtk.ListBox;

        if (row_parent == listbox) {
            _move_row (row, index, false);
        }
    }

    private void _move_row (DragListRow row, int index, bool relative) {
        int old_index = row.get_index ();
        bool row_was_selected = listbox.get_selected_row () == row;
        bool row_had_focus = row.has_focus;
        block_row_selected = true;
        if (old_index != index) {
            if (relative && index > old_index) {
                index--;
            }
            listbox.remove (row);
            listbox.insert (row, index);
            if (model != null) {
                if (index < 0) {
                    index = (int)model.get_n_items () - 1;
                }
                model.move_item (old_index, index);
            }
        }
        if (row_was_selected) {
            listbox.select_row (row);
            selected_row = row;
        }
        if (row_had_focus) {
            row.grab_focus ();
        }
        block_row_selected = false;
    }

    /**
     * Gets the n-th child in the list.
     *
     * If @index is negative or larger than the number of items in the list,
     * null is returned.
     *
     * @param index the index of the row
     */
    public unowned DragListRow? get_row_at_index (int index) {
        return (DragListRow)listbox.get_row_at_index (index);
    }

    /**
     * By setting a filter function on the this one can decide dynamically which
     * of the rows to show.
     *
     * For instance, to implement a search function on a list that filters the
     * original list to only show the matching rows.
     *
     * The filter_func will be called for each row after the call, and it will
     * continue to be called each time a row changes (via changed) or when
     * invalidate_filter is called.
     *
     * Unlike with Gtk.Listbox, filtering is supported when a model is bound to
     * a DragList.
     *
     * @param filter_func callback that lets you filter which rows to show
     */
    public void set_filter_func (DragListFilterFunc? filter_func) {
        listbox.set_filter_func ((row) => {
            return filter_func ((DragListRow) row);
        });
    }

    /**
     * Update the filtering for all rows.
     *
     * Call this when result of the filter function on the this is changed due
     * to an external factor. For instance, this would be used if the filter
     * function just looked for a specific search string and the entry with the
     * search string has changed.
     */
    public void invalidate_filter () {
        listbox.invalidate_filter ();
    }

    /**
     * Used to clamp the drag input to the area filled by the current rows to
     * make highlighting easier.
     *
     * Also sets drag_row_range to the y coordinates that would cause no change
     * when a row is dropped at those positions.
     */
    private void set_ranges () {
        if (ranges_set) {
            return;
        }
        input_range = {min: 0, max: -1};
        current_hover_range = {min: 0, max: -1};
        drag_row_range = {min: 0, max: -1};

        int last_index = (int)listbox.get_children ().length () - 1;
        DragListRow first = get_row_at_index (0);
        DragListRow last = get_row_at_index (last_index);

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

        if (drag_row_index >= 1) {
            drag_row_range.min = get_widget_middle (
                listbox.get_row_at_index (drag_row_index - 1)
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
        if (should_scroll && !scrolling) {
            scrolling = true;
            Timeout.add (SCROLL_DELAY, scroll);
        }

        return true;
    }

    /**
     * Sets current_hover_range to the range of y values that would give the
     * same result as the current y and sets hover_row_top and hover_row_bottom
     * to the rows the dragrow would be inserted between.
     */
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
        var row = (DragListRow)listbox.get_row_at_y (y);
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
        double show_min = double.max (0, y - SCROLL_DISTANCE);
        double show_max = double.min (adjustment.upper, y + SCROLL_DISTANCE);
        if (adjustment_min > show_min) {
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
            if (scroll_up) {
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
        DragListRow row;

        int index = -1;
        remove_hover_style ();
        if (hover_row_bottom != null) {
            index = hover_row_bottom.get_index ();
        } else if (hover_row_top != null) {
            index = hover_row_top.get_index () + 1;
        } else if (listbox.get_row_at_index (0) == null) {
            index = 0;
        }
        if (index >= 0 && selection_data.get_data_type ().name () == "DRAG_LIST_ROW") {
            row = ((DragListRow[])selection_data.get_data ())[0];
            drag_insert_row (row, index);
        }
        drag_row = null;
        hover_row_top = null;
        hover_row_bottom = null;
        ranges_set = false;
    }

    private void drag_insert_row (DragListRow row, int index) {
        DragList row_draglist = row.get_drag_list_box ();

        if (row_draglist == this) {
            _move_row (row, index, true);
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

namespace GOFI {
    public delegate bool DragListFilterFunc (DragListRow row);
    public delegate Gtk.Widget DragListCreateWidgetFunc (Object item);

    private const Gtk.TargetEntry[] dlb_entries = {
        {"DRAG_LIST_ROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private struct IntRange {
        public int min;
        public int max;
        public inline bool contains (int val) {return val >= min && val <= max;}
        public inline int clamp (int val) {return val.clamp (min, max);}
    }
}


public class GOFI.DragListRow : Gtk.ListBoxRow {
    private Gtk.EventBox handle;
    private DragListRowBox layout;
    private Gtk.Image image;
    private Gtk.Widget start_widget;
    private Gtk.Widget center_widget;

    public DragListRow () {
        layout = new DragListRowBox (5);
        layout.margin_start = 5;
        layout.margin_end = 5;
        add (layout);

        handle = new Gtk.EventBox ();
        image = new Gtk.Image.from_icon_name ("drag-handle-symbolic", Gtk.IconSize.MENU);
        handle.add (image);
        layout.set_end_widget (handle);

        Gtk.drag_source_set (
            handle, Gdk.ModifierType.BUTTON1_MASK, dlb_entries, Gdk.DragAction.MOVE
        );
        handle.drag_begin.connect (handle_drag_begin);
        handle.drag_data_get.connect (handle_drag_data_get);
    }

    public void set_start_widget (Gtk.Widget? widget) {
        start_widget = widget;
            layout.set_start_widget (start_widget);
    }

    public unowned Gtk.Widget? get_start_widget () {
        return start_widget;
    }

    public void set_center_widget (Gtk.Widget? widget) {
        center_widget = widget;
        if (center_widget != null) {
            layout.set_center_widget (center_widget);
        }
    }

    public unowned Gtk.Widget? get_center_widget () {
        return center_widget;
    }

    /**
     * Gets the DragList parent of this.
     */
    public unowned DragList? get_drag_list_box () {
        Gtk.Widget? parent = this.get_parent ();
        if (parent != null) {
            return parent.get_parent () as DragList;
        }
        return null;
    }

    private void handle_drag_begin (Gdk.DragContext context) {
        DragList draglist;
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
        uchar[] data = new uchar[ (sizeof (Gtk.Widget))];
        ((Gtk.Widget[])data)[0] = this;
        selection_data.set (
            Gdk.Atom.intern_static_string ("DRAG_LIST_ROW"), 32, data
        );
    }
}
