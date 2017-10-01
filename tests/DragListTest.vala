class DragListTest : TestCase {
    private const int TEST_ROWS_LENGTH = 5;
    private DragListRow[] rows;
    private DragList list;

    private DragListRow? signal_selected_row;
    private uint row_selected_emitted;

    public DragListTest () {
        base ("DragList");
        add_test ("automatic_row_selection", test_automatic_row_selection);
    }

    public override void set_up () {
        set_up_rows ();
        set_up_drag_list ();
        signal_selected_row = null;
    }

    public override void tear_down () {
        rows = null;
        list = null;
    }

    private void set_up_rows () {
        rows = new DragListRow[TEST_ROWS_LENGTH];
        for (uint i = 0; i < TEST_ROWS_LENGTH; i++) {
            var label = new Gtk.Label ("Task %u".printf(i));
            rows[i] = new DragListRow ();
            rows[i].get_content_area ().add (label);
        }
    }

    private void set_up_drag_list () {
        list = new DragList ();
        list.row_selected.connect ( (row) => {
            signal_selected_row = row;
            row_selected_emitted++;
        });
    }

    private void add_rows () {
        foreach (DragListRow row in rows) {
            list.add_row (row);
        }
    }

    private void selection_remove_next () {
        row_selected_emitted = 0;

        add_rows ();
        assert (row_selected_emitted == 1);
        row_selected_emitted = 0;

        var selected_row = list.get_selected_row ();
        assert (selected_row != null);
        assert (selected_row == signal_selected_row);
        
        for (int i = 0; i < TEST_ROWS_LENGTH - 1; i++) {
            list.remove_row (rows[i+1]);
        }
        assert (selected_row == list.get_selected_row ());
        assert (row_selected_emitted == 0);
        
        list.remove_row (selected_row);
        assert (row_selected_emitted == 1);
        assert (signal_selected_row == null);
    }

    private void selection_remove_first () {
        row_selected_emitted = 0;
        
        add_rows ();
        assert (row_selected_emitted == 1);
        row_selected_emitted = 0;
        
        var first = list.get_row_at_index (0);
        assert (first == list.get_selected_row ());
        while (first != null) {
            DragListRow? next = list.get_row_at_index (1);
            list.remove_row (first);
            assert (row_selected_emitted == 1);
            row_selected_emitted = 0;
            assert (signal_selected_row == next);
            assert (list.get_selected_row () == next);
            first = next;
        }
    }

    private void selection_remove_last () {
        row_selected_emitted = 0;

        add_rows ();
        assert (row_selected_emitted == 1);
        row_selected_emitted = 0;

        assert (list.get_row_at_index (0) == list.get_selected_row ());
        var last = list.get_row_at_index (TEST_ROWS_LENGTH - 1);
        assert (last != null);
        list.select_row (last);
        assert (list.get_selected_row () == last);
        assert (row_selected_emitted == 1);
        row_selected_emitted = 0;
        assert (signal_selected_row == last);
        
        for (int i = TEST_ROWS_LENGTH - 1; i >= 0; i--) {
            DragListRow? prev = list.get_row_at_index (i - 1);
            list.remove_row (last);
            assert (row_selected_emitted == 1);
            row_selected_emitted = 0;
            assert (signal_selected_row == prev);
            last = prev;
        }
    }
    
    private void selection_remove_prev () {
        row_selected_emitted = 0;

        add_rows ();
        assert (row_selected_emitted == 1);
        row_selected_emitted = 0;

        var last = list.get_row_at_index (TEST_ROWS_LENGTH - 1);
        list.select_row (last);
        assert (row_selected_emitted == 1);
        assert (signal_selected_row == last);
        row_selected_emitted = 0;

        for (int i = TEST_ROWS_LENGTH - 2; i >= 0; i--) {
            list.remove_row (list.get_row_at_index (i));
        }
        assert (row_selected_emitted == 0);
    }

    private void test_automatic_row_selection () {
        selection_remove_next ();
        selection_remove_first ();
        selection_remove_last ();
        selection_remove_prev ();
    }
}
