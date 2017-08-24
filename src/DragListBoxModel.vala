public interface DragListBoxModel : Object {
    public abstract Object? get_item (uint position);
    
    /**
     * Function should be such that the model that the resulting order is the
     * same as after sorting the model.
     * If sorted won't be called this can return null.
     */
    public abstract CompareDataFunc<DragListBoxRow>? get_sort_func ();
    
    /**
     * Called when a row is moved in the widget.
     * It should only be used to synchronize the model with the widget.
     */
    public abstract void move_item (uint old_position, uint new_position);

    public abstract uint get_n_items ();
    
    public abstract Iterator<Object> iterator();
    
    public virtual Iterator<Object> iterator_for_position (uint position) {
        Iterator<Object> iter = iterator ();
        while (position > 0 && iter.next ()) {
            position--;
        }
        if (position == 0) {
            return iter;
        }
        error ("iter.next is false before reaching position");
    }

    public signal void items_removed (uint position, uint amount);

    public signal void items_added (uint position, uint amount);

    /**
     * Causes the row to be moved in the widget.
     */
    public signal void item_moved (uint old_position, uint new_position);
    
    public signal void sorted ();
}

public delegate Gtk.Widget DragListBoxCreateWidgetFunc (Object item);
