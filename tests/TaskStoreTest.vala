class TaskStoreTest : TestCase {
    private TodoTask[] test_tasks;
    private const uint TEST_TASKS_LENGTH = 5;
    private TaskStore test_store;

    private bool task_done_changed_expected;
    private TodoTask task_done_changed_expected_task;

    private bool task_data_changed_expected;

    private bool item_moved_expected;
    private uint item_moved_expected_old;
    private uint item_moved_expected_new;

    private bool items_changed_expected;
    private uint items_changed_expected_position;
    private uint items_changed_expected_removed;
    private uint items_changed_expected_added;

    private bool task_invalid_expected;
    private TodoTask task_invalid_expected_task;

    public TaskStoreTest () {
        base ("TaskStore");
        add_test ("access", test_access);
        add_test ("out_of_bounds", test_out_of_bounds);
        add_test ("removing_tasks", test_remove);
        add_test ("clearing_tasks", test_clear);
        add_test ("move_item", test_move_item);
        add_test ("task_changes", test_task_changes);
    }

    public override void set_up () {
        test_store = new TaskStore (false);
        set_up_tasks ();
    }

    public override void tear_down () {
        test_tasks = null;
        test_store = null;
    }

    private void init_signal_checkers () {
        task_done_changed_expected = false;
        task_data_changed_expected = false;
        item_moved_expected = false;
        items_changed_expected = false;
        task_invalid_expected = false;
    }

    private void connect_signals () {
        test_store.task_done_changed.connect (on_task_done_changed);
        test_store.task_data_changed.connect (on_task_data_changed);
        test_store.item_moved.connect (on_item_moved);
        test_store.items_changed.connect (on_items_changed);
        test_store.task_became_invalid.connect (on_task_became_invalid);
    }

    private void on_task_done_changed () {
        assert (task_done_changed_expected);
        task_done_changed_expected = false;
    }

    private void on_task_data_changed () {
        assert (task_data_changed_expected);
        task_data_changed_expected = false;
    }

    private void on_item_moved (uint old_pos, uint new_pos) {
        assert (item_moved_expected);
        assert (compare_uint (old_pos, item_moved_expected_old));
        assert (compare_uint (new_pos, item_moved_expected_new));
        item_moved_expected = false;
    }

    private void on_items_changed (uint pos, uint removed, uint added) {
        assert (items_changed_expected);
        assert (compare_uint (pos, items_changed_expected_position));
        assert (compare_uint (removed, items_changed_expected_removed));
        assert (compare_uint (added, items_changed_expected_added));
        items_changed_expected = false;
    }

    private void on_task_became_invalid (TodoTask task) {
        assert (task_invalid_expected);
        assert (task_invalid_expected_task == task);
        task_invalid_expected = false;
    }

    private void set_up_tasks () {
        test_tasks = new TodoTask[TEST_TASKS_LENGTH];
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            test_tasks[i] = new TodoTask ("Task %u".printf(i), false);
        }
        init_signal_checkers ();
        connect_signals ();
    }

    private string safe_store_get_string (uint position) {
        TodoTask task = (TodoTask)test_store.get_item (position);
        return (task != null)? task.title : "<null>";
    }

    private bool compare_tasks (uint store, uint test) {
        bool same = (test_store.get_item (store) == test_tasks[test]);

        if (!same) {
            stdout.printf ("\n%s (%u) != %s (%u)\n", safe_store_get_string (store), store, test_tasks[test].title, test);
            stdout.printf ("TaskStore tasks:\n");
            for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
                stdout.printf ("\t%u: %s\n", i, (safe_store_get_string (i)));
            }
        }

        return same;
    }

    private void test_access () {
        add_tasks ();

        assert (test_store.get_n_items () == TEST_TASKS_LENGTH);

        // sequential access
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            assert (compare_tasks (i, i));
        }
        for (uint i = TEST_TASKS_LENGTH - 1; i > 0; i--) {
            assert (compare_tasks (i, i));
        }
        assert (compare_tasks (0, 0));

        // random-ish access
        assert (test_store.get_item (0) == test_tasks[0]);
        assert (test_store.get_item (TEST_TASKS_LENGTH-1) == test_tasks[TEST_TASKS_LENGTH-1]);
        assert (test_store.get_item (TEST_TASKS_LENGTH/2) == test_tasks[TEST_TASKS_LENGTH/2]);
    }

    private void test_out_of_bounds () {
        assert (test_store.get_item (0) == null);
        assert (test_store.get_item (TEST_TASKS_LENGTH) == null);
        add_tasks ();
        assert (test_store.get_item (TEST_TASKS_LENGTH) == null);
        assert (test_store.get_item (int.MAX) == null);
    }

    private void test_remove () {
        // Remove all in order
        add_tasks ();
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            remove_task (i, 0);
            for (uint j = i+1, k = 0; j < TEST_TASKS_LENGTH; j++, k++) {
                assert (compare_tasks (k, j));
            }
        }
        assert (test_store.get_n_items () == 0);
        assert (test_store.get_item (0) == null);

        // Remove all in reverse
        add_tasks ();
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            uint pos = TEST_TASKS_LENGTH - i - 1;
            remove_task (pos, pos);
            for (uint j = 0; j < TEST_TASKS_LENGTH - i - 1; j++) {
                assert (compare_tasks (j, j));
            }
        }
        assert (test_store.get_n_items () == 0);
        assert (test_store.get_item (0) == null);

        // Removing the middle
        add_tasks ();
        remove_task (TEST_TASKS_LENGTH/2, TEST_TASKS_LENGTH/2);
        for (uint i = 0, j = 0; i < TEST_TASKS_LENGTH; i++, j++) {
            if (i == TEST_TASKS_LENGTH/2) {
                i++;
            } else {
                assert (compare_tasks (j, i));
            }
        }

        // TaskStore shouln't listen to signals of removed tasks
        TodoTask to_remove = (TodoTask)test_store.get_item (0);
        remove_task (0, 0);
        to_remove.title = "new task title";
        to_remove.done = !to_remove.done;
    }

    private void test_clear () {
        add_tasks ();
        items_changed_expected = true;
        items_changed_expected_position = 0;
        items_changed_expected_added = 0;
        items_changed_expected_removed = TEST_TASKS_LENGTH;
        test_store.clear ();
        assert (!items_changed_expected);
    }

    private void test_move_item () {
        add_tasks ();
        move_item (0, TEST_TASKS_LENGTH/2);
        for (int i = 0, j = 1; i < TEST_TASKS_LENGTH; i++, j++) {
            if (i == TEST_TASKS_LENGTH/2) {
                assert (compare_tasks (i, 0));
                j--;
            } else {
                assert (compare_tasks (i, j));
            }
        }

        move_item (TEST_TASKS_LENGTH/2, 0);
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            assert (compare_tasks (i, i));
        }

        move_item (TEST_TASKS_LENGTH-1, TEST_TASKS_LENGTH/2);
        for (int i = 0, j = 0; i < TEST_TASKS_LENGTH; i++, j++) {
            if (i == TEST_TASKS_LENGTH/2) {
                assert (compare_tasks (i, TEST_TASKS_LENGTH - 1));
                j--;
            } else {
                assert (compare_tasks (i, j));
            }
        }

        move_item (TEST_TASKS_LENGTH/2, TEST_TASKS_LENGTH - 1);
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            assert (compare_tasks (i, i));
        }

        move_item (1, TEST_TASKS_LENGTH - 2);
        assert (compare_tasks (TEST_TASKS_LENGTH - 2, 1));
        assert (compare_tasks (TEST_TASKS_LENGTH - 1, TEST_TASKS_LENGTH - 1));
        assert (compare_tasks (1, 2));
        move_item (TEST_TASKS_LENGTH - 2, 1);
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            assert (compare_tasks (i, i));
        }
    }

    private void test_task_changes () {
        int index;
        add_tasks ();
        task_data_changed_expected = true;
        index = Test.rand_int_range (0, (int32)TEST_TASKS_LENGTH - 1);
        test_tasks[index].title = "new task title";
        assert (!task_data_changed_expected);

        task_done_changed_expected = true;
        index = Test.rand_int_range (0, (int32)TEST_TASKS_LENGTH - 1);
        task_done_changed_expected_task = test_tasks[index];
        test_tasks[index].done = true;
        assert (!task_done_changed_expected);

        task_invalid_expected = true;
        index = Test.rand_int_range (0, (int32)TEST_TASKS_LENGTH - 1);
        task_invalid_expected_task = test_tasks[index];
        test_tasks[index].title = "";
        assert (!task_invalid_expected);
    }

    private void remove_task (uint index, uint expected_pos) {
        items_changed_expected_removed = 1;
        items_changed_expected_added = 0;
        items_changed_expected = true;
        items_changed_expected_position = expected_pos;
        test_store.remove_task (test_tasks[index]);
        assert (!items_changed_expected);
    }

    private void add_task (uint index, uint expected_pos) {
        items_changed_expected_removed = 0;
        items_changed_expected_added = 1;
        items_changed_expected = true;
        items_changed_expected_position = expected_pos;
        test_store.add_task (test_tasks[index]);
        assert (!items_changed_expected);
    }

    private void add_tasks () {
        for (uint i = 0; i < TEST_TASKS_LENGTH; i++) {
            add_task (i, i);
        }
    }

    private void move_item (uint old_position, uint new_position) {
        task_data_changed_expected = true;
        test_store.move_item (old_position, new_position);
        assert (!task_data_changed_expected);
    }
}
