class TaskRow: DragListBoxRow {
    unowned Gtk.Box content_layout;
    private Gtk.CheckButton check_button;
    private Gtk.Label title_label;

    public TodoTask task {
        get;
        construct set;
    }
    
    public TaskRow (TodoTask task) {
        this.task = task;
        content_layout = get_content ();
        
        check_button = new Gtk.CheckButton ();
        check_button.active = task.done;
        
        title_label = new Gtk.Label (task.title);
        title_label.wrap = true;
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.width_request = 200;
        
        // Workaround for: "undefined symbol: gtk_label_set_xalign"
        ((Gtk.Misc) title_label).xalign = 0f;
        
        content_layout.add (check_button);
        content_layout.add (title_label);
        
        connect_signals ();
        show_all ();
    }
    
    private void connect_signals () {
        check_button.toggled.connect (() => {
            task.done = !task.done;
        });
        task.status_changed.connect (() => {
            destroy ();
        });
    }
}
