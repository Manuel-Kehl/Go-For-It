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
public class DragListBox : Gtk.Box {
    private _DragListBox _draglistbox;
    private bool internal_signal;

    public Gtk.Adjustment vadjustment {
        public get {
            return _draglistbox.get_adjustment ();
        }
        public set {
            _draglistbox.set_adjustment (value);
        }
    }
    
    public virtual signal void activate_cursor_row () {
        _draglistbox.activate_cursor_row ();
    }
    
    public virtual signal void move_cursor (Gtk.MovementStep step, int count) {
        internal_signal = true;
        _draglistbox.move_cursor (step, count);
    }
    
    public virtual signal void row_activated (DragListBoxRow row) {
        return;
    }
    
    private void on_list_row_activated (Gtk.ListBoxRow row) {
        row_activated ((DragListBoxRow) row);
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

    /**
     * Methods like add, remove
     */
    public unowned Gtk.Container list_widget {
        public get {
            return _draglistbox;
        }
    }

    public DragListBox () {
        _draglistbox = new _DragListBox ();
        _draglistbox.set_selection_mode (Gtk.SelectionMode.SINGLE);
        _draglistbox.set_activate_on_single_click (false);
        
        base.add(_draglistbox);
        set_orientation (Gtk.Orientation.VERTICAL);
        
        internal_signal = false;
        connect_signals ();
    }
    
    private void connect_signals () {
        _draglistbox.move_cursor.connect (on_list_move_cursor);
        _draglistbox.row_activated.connect_after (on_list_row_activated);
        _draglistbox.row_selected.connect (on_list_row_selected);
    }

    public void bind_model (
        DragListBoxModel? model,
        owned DragListBoxCreateWidgetFunc? create_widget_func
    ) {
        _draglistbox.bind_model(model, (owned) create_widget_func);
    }
    
    public DragListBoxRow? get_selected_row () {
        return (DragListBoxRow) _draglistbox.get_selected_row ();
    }

    public override void add (Gtk.Widget widget) {
        insert (widget, -1);
    }

    public void insert (Gtk.Widget widget, int position) {
        _draglistbox._insert (widget, position);
    }

    public void move_row (DragListBoxRow row, int index) {
        _draglistbox.move_row (row, index);
    }

    public DragListBoxRow get_row_at_index (int index) {
        return (DragListBoxRow)_draglistbox.get_row_at_index (index);
    }
}

/**
 * A widget for displaying and manipulating task lists.
 */
private class _DragListBox : Gtk.ListBox {
    private Gtk.ListBoxRow? hover_row;
    internal Gtk.ListBoxRow? drag_row;
    private bool top = false;
    private int hover_top;
    private int hover_bottom;
    private bool should_scroll = false;
    private bool scrolling = false;
    private bool scroll_up;

    private const int SCROLL_STEP_SIZE = 8;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;

    private DragListBoxModel? model;
    private DragListBoxCreateWidgetFunc? create_widget_func;

    public _DragListBox () {
        Gtk.drag_dest_set (
            this, Gtk.DestDefaults.ALL, dlb_entries, Gdk.DragAction.MOVE
        );
    }

    internal void _add (Gtk.Widget widget) {
        _insert (widget, -1);
    }

    internal void _insert (Gtk.Widget widget, int position){
        DragListBoxRow row = widget as DragListBoxRow;

        if (row == null) {
            row = new DragListBoxRow ();
            row.get_content ().add(widget);
        }

        insert (row, position);
        if (get_selected_row () == null) {
            select_row (row);
        }
    }

    public override bool drag_motion (
        Gdk.DragContext context, int x, int y, uint time_
    ) {
        if (y > hover_top || y < hover_bottom) {
            Gtk.Allocation alloc;
            var row = get_row_at_y (y);
            bool old_top = top;

            row.get_allocation (out alloc);
            int hover_row_y = alloc.y;
            int hover_row_height = alloc.height;
            if (row != drag_row) {
                if (y < hover_row_y + hover_row_height/2) {
                    hover_top = hover_row_y;
                    hover_bottom = hover_top + hover_row_height/2;
                    row.get_style_context ().add_class ("drag-hover-top");
                    row.get_style_context ().remove_class ("drag-hover-bottom");
                    top = true;
                } else {
                    hover_top = hover_row_y + hover_row_height/2;
                    hover_bottom = hover_row_y + hover_row_height;
                    row.get_style_context ().add_class ("drag-hover-bottom");
                    row.get_style_context ().remove_class ("drag-hover-top");
                    top = false;
                }
            }

            if (hover_row != null && hover_row != row) {
                if (old_top)
                    hover_row.get_style_context ().remove_class ("drag-hover-top");
                else
                    hover_row.get_style_context ().remove_class ("drag-hover-bottom");
            }

            hover_row = row;
        }

        check_scroll (y);
        if(should_scroll && !scrolling) {
            scrolling = true;
            Timeout.add (SCROLL_DELAY, scroll);
        }

        return true;
    }

    public override void drag_leave (Gdk.DragContext context, uint time_) {
        should_scroll = false;
    }

    private void check_scroll (int y) {
        Gtk.Adjustment adjustment = get_adjustment ();
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
        Gtk.Adjustment adjustment = get_adjustment ();
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

    public override void drag_data_received (
        Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint info, uint time_
    ) {
        // Gtk.Widget handle;
        DragListBoxRow row;

        int index = 0;
        if (hover_row != null) {
            if (top) {
                index = hover_row.get_index () - 1;
                hover_row.get_style_context ().remove_class ("drag-hover-top");
            } else {
                index = hover_row.get_index ();
                hover_row.get_style_context ().remove_class ("drag-hover-bottom");
            }
            if (selection_data.get_data_type().name () == "DRAG_LIST_BOX_ROW") {
                row = ((DragListBoxRow[])selection_data.get_data ())[0];

                if (row != hover_row) {
                    drag_insert_row (row, index);
                }
            }
        }
        drag_row = null;
    }

    private void drag_insert_row (DragListBoxRow row, int index) {
        _DragListBox row_parent = row.get_parent () as _DragListBox;

        if (row_parent == this) {
            _move_row (row, index);
        } else {
            if (model != null) {

            } else {
                row.get_parent ().remove (row);
                insert (row, index);
            }
        }
    }

    public void move_row (DragListBoxRow row, int index) {
        if (model != null) {
            return;
        }
        _DragListBox row_parent = row.get_parent () as _DragListBox;

        if (row_parent == this) {
            _move_row (row, index);
        }
    }

    private void _move_row (DragListBoxRow row, int index) {
        int _index = index;
        int old_index = row.get_index ();
        if (old_index != index) {
            if (_index < old_index) {
                _index++;
            }
            remove (row);
            insert (row, _index);
            if (model != null) {
                if (index < 0) {
                    index = (int)model.get_n_items () - 1;
                }
                model.move_item (old_index, index);
            }
        }
    }

    public new void bind_model (
        DragListBoxModel? model, 
        owned DragListBoxCreateWidgetFunc? create_widget_func
    ) {
        if (model != null && create_widget_func == null) {
            return;
        }
        @foreach((widget) => {
            remove(widget);
        });
        this.model = model;
        this.create_widget_func = (owned) create_widget_func;

        for (uint i = 0; i < model.get_n_items (); i++) {
            var row = this.create_widget_func(model.get_item (i));
            this._add (row);
        }

        model.items_added.connect (on_model_items_added);
        model.items_removed.connect (on_model_items_removed);
        model.item_moved.connect (on_model_item_moved);
    }

    private void on_model_items_added (uint index, uint amount) {
        if (amount == 1) {
            this._add (this.create_widget_func (model.get_item (index)));
        } else {
            Iterator<Object> iter = model.iterator_for_position (index);
            while (amount > 0 && iter.next ()) {
                var row = this.create_widget_func (iter.get());
                this._add (row);
            }
        }
    }

    private void on_model_items_removed (uint index, uint amount) {
        for (uint i = index + amount - 1; i >= index ; i++) {
            remove (get_row_at_index((int)i));
        }
    }

    private void on_model_item_moved (uint old_index, uint new_index) {
        _move_row(
            (DragListBoxRow)get_row_at_index((int)old_index), (int)new_index
        );
    }
}

private const Gtk.TargetEntry[] dlb_entries = {
    {"DRAG_LIST_BOX_ROW", Gtk.TargetFlags.SAME_APP, 0}
};

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

    public unowned Gtk.Box get_content () {
        return content;
    }

    private void handle_drag_begin (Gdk.DragContext context) {
        _DragListBox parent;
        Gtk.Allocation alloc;
        Cairo.Surface surface;
        Cairo.Context cr;
        int x, y;

        get_allocation (out alloc);
        surface = new Cairo.ImageSurface (
            Cairo.Format.ARGB32, alloc.width, alloc.height
        );
        cr = new Cairo.Context (surface);

        parent = this.get_parent () as _DragListBox;
        if (parent != null)
            parent.drag_row = this;

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
