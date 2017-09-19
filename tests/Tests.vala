void main (string[] args) {
    Test.init (ref args);

    TestSuite.get_root ().add_suite (new TaskStoreTest ().get_suite ());
    TestSuite.get_root ().add_suite (new TodoTaskTest ().get_suite ());

    Test.run ();
}
