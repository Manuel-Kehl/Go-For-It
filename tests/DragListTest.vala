using GOFI;

class DragListTest : TestCase {
    private const int TEST_ROWS_LENGTH = 5;
    private DragListRow[] rows;
    private DragList list;

    private DragListRow? signal_selected_row;
    private uint row_selected_emitted;

    public DragListTest () {
        base ("DragList");
        add_test ("get_row", test_get_row);
        add_test ("automatic_row_selection", test_automatic_row_selection);
        add_test ("move_row", test_move_row);
        add_test ("model_get_row", test_model_get_row);
        add_test ("model_move_row", test_model_move_row);
        add_test ("model_list_move_row", test_model_list_move_row);
        add_test ("model_automatic_row_selection", test_model_automatic_row_selection);
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
        rows = generate_rows (0, TEST_ROWS_LENGTH);
    }

    private DragListRow[] generate_rows (uint start, uint amount) {
        var new_rows = new DragListRow[amount];
        for (uint i = 0; i < amount; i++) {
            var label = new Gtk.Label ("Task %u".printf (start+i));
            new_rows[i] = new DragListRow ();
            new_rows[i].set_center_widget (label);
        }
        return new_rows;
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

    private void test_get_row () {
        add_rows ();

        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }
    }

    private void test_move_row () {
        add_rows ();
        list.move_row (rows[0], TEST_ROWS_LENGTH/2);
        for (int i = 0, j = 1; i < TEST_ROWS_LENGTH; i++, j++) {
            if (i == TEST_ROWS_LENGTH/2) {
                assert (list.get_row_at_index (i) == rows[0]);
                j--;
            } else {
                assert (list.get_row_at_index (i) == rows[j]);
            }
        }

        list.move_row (rows[0], 0);
        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }

        list.move_row (rows[TEST_ROWS_LENGTH-1], TEST_ROWS_LENGTH/2);
        for (int i = 0, j = 0; i < TEST_ROWS_LENGTH; i++, j++) {
            if (i == TEST_ROWS_LENGTH/2) {
                assert (list.get_row_at_index (i) == rows[TEST_ROWS_LENGTH - 1]);
                j--;
            } else {
                assert (list.get_row_at_index (i) == rows[j]);
            }
        }

        list.move_row (rows[TEST_ROWS_LENGTH-1], TEST_ROWS_LENGTH - 1);
        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }

        list.move_row (rows[1], TEST_ROWS_LENGTH - 2);
        assert (list.get_row_at_index (TEST_ROWS_LENGTH - 2) == rows[1]);
        assert (list.get_row_at_index (TEST_ROWS_LENGTH - 1) == rows[TEST_ROWS_LENGTH - 1]);
        assert (list.get_row_at_index (1) == rows[2]);
        list.move_row (rows[1], 1);
        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }
    }

    private void selection_remove_next () {
        row_selected_emitted = 0;

        add_rows ();
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        var selected_row = list.get_selected_row ();
        assert (selected_row != null);
        assert (selected_row == signal_selected_row);

        for (int i = 0; i < TEST_ROWS_LENGTH - 1; i++) {
            list.remove_row (rows[i+1]);
        }
        assert (selected_row == list.get_selected_row ());
        assert (compare_uint (row_selected_emitted, 0));

        list.remove_row (selected_row);
        assert (compare_uint (row_selected_emitted, 1));
        assert (signal_selected_row == null);
    }

    private void selection_remove_first () {
        row_selected_emitted = 0;

        add_rows ();
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        var first = list.get_row_at_index (0);
        assert (first == list.get_selected_row ());
        while (first != null) {
            DragListRow? next = list.get_row_at_index (1);
            list.remove_row (first);
            assert (compare_uint (row_selected_emitted, 1));
            row_selected_emitted = 0;
            assert (signal_selected_row == next);
            assert (list.get_selected_row () == next);
            first = next;
        }
    }

    private void selection_remove_last () {
        row_selected_emitted = 0;

        add_rows ();
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        assert (list.get_row_at_index (0) == list.get_selected_row ());
        var last = list.get_row_at_index (TEST_ROWS_LENGTH - 1);
        assert (last != null);
        list.select_row (last);
        assert (list.get_selected_row () == last);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;
        assert (signal_selected_row == last);

        for (int i = TEST_ROWS_LENGTH - 1; i >= 0; i--) {
            DragListRow? prev = list.get_row_at_index (i - 1);
            list.remove_row (last);
            assert (compare_uint (row_selected_emitted, 1));
            row_selected_emitted = 0;
            assert (signal_selected_row == prev);
            last = prev;
        }
    }

    private void selection_remove_prev () {
        row_selected_emitted = 0;

        add_rows ();
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        var last = list.get_row_at_index (TEST_ROWS_LENGTH - 1);
        list.select_row (last);
        assert (compare_uint (row_selected_emitted, 1));
        assert (signal_selected_row == last);
        row_selected_emitted = 0;

        for (int i = TEST_ROWS_LENGTH - 2; i >= 0; i--) {
            list.remove_row (list.get_row_at_index (i));
        }
        assert (compare_uint (row_selected_emitted, 0));
    }

    private void test_automatic_row_selection () {
        selection_remove_next ();
        selection_remove_first ();
        selection_remove_last ();
        selection_remove_prev ();
    }

    private void test_model_get_row () {
        var model = new TestModel ();
        model.add_rows (rows, TEST_ROWS_LENGTH);
        list.bind_model (model, return_row);

        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }
    }

    private void test_model_move_row () {
        var model = new TestModel ();
        model.add_rows (rows, TEST_ROWS_LENGTH);
        list.bind_model (model, return_row);

        model.model_move_item (0, TEST_ROWS_LENGTH/2);
        for (int i = 0, j = 1; i < TEST_ROWS_LENGTH; i++, j++) {
            if (i == TEST_ROWS_LENGTH/2) {
                assert (list.get_row_at_index (i) == rows[0]);
                j--;
            } else {
                assert (list.get_row_at_index (i) == rows[j]);
            }
        }

        model.model_move_item (TEST_ROWS_LENGTH/2, 0);
        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }

        model.model_move_item (TEST_ROWS_LENGTH - 1, TEST_ROWS_LENGTH/2);
        for (int i = 0, j = 0; i < TEST_ROWS_LENGTH; i++, j++) {
            if (i == TEST_ROWS_LENGTH/2) {
                assert (list.get_row_at_index (i) == rows[TEST_ROWS_LENGTH - 1]);
                j--;
            } else {
                assert (list.get_row_at_index (i) == rows[j]);
            }
        }

        model.model_move_item (TEST_ROWS_LENGTH/2, TEST_ROWS_LENGTH - 1);
        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }

        model.model_move_item (1, TEST_ROWS_LENGTH - 2);
        assert (list.get_row_at_index (TEST_ROWS_LENGTH - 2) == rows[1]);
        assert (list.get_row_at_index (TEST_ROWS_LENGTH - 1) == rows[TEST_ROWS_LENGTH - 1]);
        assert (list.get_row_at_index (1) == rows[2]);
        model.model_move_item (TEST_ROWS_LENGTH - 2, 1);
        for (int i = 0; i < TEST_ROWS_LENGTH; i++) {
            assert (list.get_row_at_index (i) == rows[i]);
        }
    }

    private void test_model_list_move_row () {
        var model = new TestModel ();
        model.add_rows (rows, TEST_ROWS_LENGTH);
        list.bind_model (model, return_row);

        model.move_item_called = 0;
        list.move_row (rows[0], TEST_ROWS_LENGTH/2);
        assert (model.move_item_called == 1);
        assert (model.move_item_old == 0);
        assert (model.move_item_new == TEST_ROWS_LENGTH/2);

        model.move_item_called = 0;
        list.move_row (rows[0], 0);
        assert (model.move_item_called == 1);
        assert (model.move_item_old == TEST_ROWS_LENGTH/2);
        assert (model.move_item_new == 0);

        model.move_item_called = 0;
        list.move_row (rows[TEST_ROWS_LENGTH - 1], TEST_ROWS_LENGTH/2);
        assert (model.move_item_called == 1);
        assert (model.move_item_old == TEST_ROWS_LENGTH - 1);
        assert (model.move_item_new == TEST_ROWS_LENGTH/2);

        model.move_item_called = 0;
        list.move_row (rows[TEST_ROWS_LENGTH - 1], TEST_ROWS_LENGTH - 1);
        assert (model.move_item_called == 1);
        assert (model.move_item_old == TEST_ROWS_LENGTH/2);
        assert (model.move_item_new == TEST_ROWS_LENGTH - 1);

        model.move_item_called = 0;
        list.move_row (rows[1], TEST_ROWS_LENGTH - 2);
        assert (model.move_item_called == 1);
        assert (model.move_item_old == 1);
        assert (model.move_item_new == TEST_ROWS_LENGTH - 2);
    }

    private void model_selection_remove_next (TestModel model) {
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        var selected_row = list.get_selected_row ();
        assert (selected_row != null);
        assert (selected_row == signal_selected_row);

        for (int i = 0; i < TEST_ROWS_LENGTH - 1; i++) {
            model.remove_rows (1, 1);
        }
        assert (selected_row == list.get_selected_row ());
        assert (compare_uint (row_selected_emitted, 0));

        model.remove_rows (0, 1);
        assert (compare_uint (row_selected_emitted, 1));
        assert (signal_selected_row == null);

        // multiple
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        selected_row = list.get_selected_row ();
        assert (selected_row != null);
        assert (selected_row == signal_selected_row);

        model.remove_rows (1, TEST_ROWS_LENGTH - 1);
        assert (selected_row == list.get_selected_row ());
        assert (compare_uint (row_selected_emitted, 0));
        model.remove_rows (0, 1);
    }

    private void model_selection_remove_first (TestModel model) {
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        var first = list.get_row_at_index (0);
        assert (first == list.get_selected_row ());
        while (first != null) {
            DragListRow? next = list.get_row_at_index (1);
            model.remove_rows (0, 1);
            assert (compare_uint (row_selected_emitted, 1));
            row_selected_emitted = 0;
            assert (signal_selected_row == next);
            assert (list.get_selected_row () == next);
            first = next;
        }
    }

    private void model_selection_remove_last (TestModel model) {
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        assert (list.get_row_at_index (0) == list.get_selected_row ());
        var last = list.get_row_at_index (TEST_ROWS_LENGTH - 1);
        assert (last != null);
        list.select_row (last);
        assert (list.get_selected_row () == last);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;
        assert (signal_selected_row == last);

        for (int i = TEST_ROWS_LENGTH - 1; i >= 0; i--) {
            DragListRow? prev = list.get_row_at_index (i - 1);
            model.remove_rows (i, 1);
            assert (row_selected_emitted == 1);
            row_selected_emitted = 0;
            assert (signal_selected_row == prev);
            last = prev;
        }
    }

    private void model_selection_remove_prev (TestModel model) {
        //single
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        var last = list.get_row_at_index (TEST_ROWS_LENGTH - 1);
        list.select_row (last);
        assert (compare_uint (row_selected_emitted, 1));
        assert (signal_selected_row == last);
        row_selected_emitted = 0;

        for (int i = TEST_ROWS_LENGTH - 2; i >= 0; i--) {
            model.remove_rows (i, 1);
        }
        assert (list.get_selected_row () == last);
        assert (compare_uint (row_selected_emitted, 0));

        //multiple
        model.add_rows (
            generate_rows (
                TEST_ROWS_LENGTH, TEST_ROWS_LENGTH - 1
            ),
            TEST_ROWS_LENGTH - 1
        );
        model.remove_rows (0, TEST_ROWS_LENGTH - 1);
        assert (compare_uint (row_selected_emitted, 0));

        model.remove_rows (0, 1);
    }

    private void model_selection_remove_all (TestModel model) {
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        model.remove_rows (0, TEST_ROWS_LENGTH);
        assert (signal_selected_row == null);
    }

    private void model_selection_replace (TestModel model) {
        row_selected_emitted = 0;

        model.add_rows (rows, TEST_ROWS_LENGTH);
        assert (compare_uint (row_selected_emitted, 1));
        row_selected_emitted = 0;

        uint selected_index = TEST_ROWS_LENGTH/2;

        list.select_row (rows[selected_index]);
        row_selected_emitted = 0;

        model.replace (0, selected_index, generate_rows (0, selected_index));
        assert (compare_uint (row_selected_emitted, 0));
        uint remove = selected_index + 1;
        model.replace (remove, TEST_ROWS_LENGTH - (remove), generate_rows (remove, remove));
        assert (compare_uint (row_selected_emitted, 0));
        assert (signal_selected_row == rows[selected_index]);
        model.replace (selected_index, 1, generate_rows (selected_index, 1));
        assert (compare_uint (row_selected_emitted, 1));
        assert (signal_selected_row == model.get_item (selected_index));

        model.remove_rows (0, TEST_ROWS_LENGTH);
    }

    private void test_model_automatic_row_selection () {
        var model = new TestModel ();
        list.bind_model (model, return_row);

        model_selection_remove_next (model);
        model_selection_remove_first (model);
        model_selection_remove_last (model);
        model_selection_remove_prev (model);
        model_selection_remove_all (model);
        model_selection_replace (model);
    }

    private class TestModel : Object, DragListModel {
        List<DragListRow> row_list;
        public uint move_item_called;
        public uint move_item_old;
        public uint move_item_new;

        public TestModel () {
            row_list = new List<DragListRow> ();
            move_item_called = 0;
        }

        public void add_rows (DragListRow[]? new_rows, int length) {
            for (int i = length - 1; i >= 0; i--) {
                row_list.prepend (new_rows[i]);
            }
            items_changed (0, 0, length);
        }

        public void remove_rows (uint position, uint amount) {
            for (uint i = amount; i > 0; i--) {
                var nth_link = row_list.nth (position));
                nth_link.data.unref ();
                row_list.delete_link (nth_link);
            }
            items_changed (position, amount, 0);
        }

        public void replace (uint position, uint remove, DragListRow[] new_rows) {
            uint added = 0;
            for (uint i = remove; i > 0; i--) {
                var nth_link = row_list.nth (position));
                nth_link.data.unref ();
                row_list.delete_link (nth_link);
            }
            foreach (DragListRow row in new_rows) {
                row_list.insert (row, (int) (position + added));
                added++;
            }
            items_changed (position, remove, added);
        }

        public void move_item (uint old_position, uint new_position) {
            _move_item (old_position, new_position);
            move_item_called++;
            move_item_old = old_position;
            move_item_new = new_position;
        }

        private void _move_item (uint old_position, uint new_position) {
            unowned List<DragListRow> link = row_list.nth (old_position);
            var row = link.data;
            //TODO: check if unref is necessary here
            row_list.delete_link (link);
            row_list.insert (row, (int)new_position);
        }

        public void model_move_item (uint old_position, uint new_position) {
            _move_item (old_position, new_position);
            item_moved (old_position, new_position);
        }

        public Object? get_item (uint position) {
            if (position >= get_n_items ()) {
                return null;
            }
            return row_list.nth_data (position);
        }

        public Type get_item_type () {
            return typeof (DragListRow);
        }

        public uint get_n_items () {
            return row_list.length ();
        }
    }

    private Gtk.Widget return_row (Object row) {
        return (Gtk.Widget) row;
    }
}
