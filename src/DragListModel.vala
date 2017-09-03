public interface DragListModel : Object, GLib.ListModel {
    /**
     * Called when a row is moved in the widget.
     * It should only be used to synchronize the model with the widget.
     */
    public abstract void move_item (uint old_position, uint new_position);

    /**
     * Causes the row to be moved in the widget.
     */
    public signal void item_moved (uint old_position, uint new_position);
}

public delegate Gtk.Widget DragListCreateWidgetFunc (Object item);
