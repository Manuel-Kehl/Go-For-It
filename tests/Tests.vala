void main (string[] args) {
    Gtk.init (ref args);
    Test.init (ref args);

    TestSuite.get_root ().add_suite (new TaskStoreTest ().get_suite ());
    TestSuite.get_root ().add_suite (new TodoTaskTest ().get_suite ());
    TestSuite.get_root ().add_suite (new DragListTest ().get_suite ());

    Idle.add (() => {
        Test.run ();
        Gtk.main_quit ();
        return false;
    });

    Gtk.main ();
}
