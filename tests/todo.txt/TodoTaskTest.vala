using GOFI.TXT;

class TodoTaskTest : TestCase {
    private uint data_changed_emitted;
    private uint done_changed_emitted;
    private uint notify_done_emitted;

    public TodoTaskTest () {
        base ("TodoTask");
        add_test ("retrieve", test_retreive);
        add_test ("modify_title", test_modify_string);
        add_test ("modify_done", test_modify_done);
    }

    private bool check_expected (uint data_changed, uint done_changed, uint notify_done) {
        bool matched = true;
        if (data_changed != data_changed_emitted) {
            stdout.printf (
                "data_changed emitted %u times, expected %u\n",
                data_changed_emitted,
                data_changed
            );
            matched = false;
        }
        if (done_changed != done_changed_emitted) {
            stdout.printf (
                "done_changed emitted %u times, expected %u\n",
                done_changed_emitted,
                done_changed
            );
            matched = false;
        }
        if (notify_done != notify_done_emitted) {
            stdout.printf (
                "notify[\"done\"] emitted %u times, expected %u\n",
                notify_done_emitted,
                notify_done
            );
            matched = false;
        }
        return matched;
    }

    private void reset_counters () {
        data_changed_emitted = 0;
        done_changed_emitted = 0;
        notify_done_emitted = 0;
    }

    private void connect_task (TxtTask task) {
        task.done_changed.connect (on_task_done_changed);
        task.notify.connect (on_task_property_changed);
    }

    private void disconnect_task (TxtTask task) {
        task.done_changed.disconnect (on_task_done_changed);
        task.notify.disconnect (on_task_property_changed);
    }

    private void on_task_property_changed (Object task, ParamSpec pspec) {
        switch (pspec.name) {
            case "done":
                notify_done_emitted++;
                break;
            default:
                data_changed_emitted++;
                break;
        }
    }

    private void on_task_done_changed () {
        done_changed_emitted++;
    }

    private void test_retreive () {
        string test_title;
        bool done;

        for (int i = 0; i < 4; i++) {
            done = i % 2 == 0;
            test_title = "Task %i".printf (i);
            TxtTask test_task = new TxtTask (test_title, done);

            assert (test_task.description == test_title);
            assert (compare_bool (test_task.done, done));
            assert (test_task.valid);
        }
    }

    private void test_modify_string () {
        string test_title;
        bool done;

        for (int i = 0; i < 4; i++) {
            done = i % 2 == 0;
            test_title = "Task %i".printf (i);

            TxtTask task = new TxtTask (test_title, done);

            reset_counters ();
            connect_task (task);

            string new_title = "new_title";
            task.description = new_title;

            assert (check_expected (1, 0, 0));
            assert (compare_string (task.description, new_title));
            assert (compare_bool (task.done, done));
            assert (task.valid);
            disconnect_task (task);
        }
        for (int i = 4; i < 6; i++) {
            done = i % 2 == 0;
            test_title = "Task %i".printf (i);

            TxtTask task = new TxtTask (test_title, done);

            reset_counters ();
            connect_task (task);

            string new_title = "";
            task.description = new_title;

            assert (check_expected (1, 0, 0));
            assert (compare_string (task.description, new_title));
            assert (compare_bool (task.done, done));
            assert (!task.valid);
            disconnect_task (task);
        }
    }

    private void test_modify_done () {
        string test_title;
        bool done;

        for (int i = 0; i < 2; i++) {
            done = i % 2 == 0;
            test_title = "Task %i".printf (i);

            TxtTask task = new TxtTask (test_title, done);

            reset_counters ();
            connect_task (task);

            task.done = !done;

            assert (check_expected (0, 1, 1));
            assert (compare_string (task.description, test_title));
            assert (compare_bool (task.done, !done));
            assert (task.valid);
            disconnect_task (task);
        }
        for (int i = 2; i < 4; i++) {
            done = i % 2 == 0;
            test_title = "Task %i".printf (i);

            TxtTask task = new TxtTask (test_title, done);

            reset_counters ();
            connect_task (task);

            task.done = done;

            assert (check_expected (0, 0, 1));
            assert (compare_string (task.description, test_title));
            assert (compare_bool (task.done, done));
            assert (task.valid);
            disconnect_task (task);
        }
    }
}
