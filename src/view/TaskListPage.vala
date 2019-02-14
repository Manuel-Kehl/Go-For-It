/**
 * A widget containing a TaskList and its widgets and the TimerView.
 */
class TaskListPage : Gtk.Grid {
    private TxtList task_list = null;
    private TaskTimer task_timer;

    /* Various GTK Widgets */
    private Gtk.Stack activity_stack;
    private ViewSwitcher activity_switcher;

    private Gtk.Widget first_page;
    private TimerView timer_view;
    private Gtk.Widget last_page;

    public signal void removing_list ();

    /**
     * The constructor of the MainWindow class.
     */
    public TaskListPage (TaskTimer task_timer)
    {
        this.task_timer = task_timer;

        this.orientation = Gtk.Orientation.VERTICAL;
        initial_setup ();
        task_timer.active_task_done.connect (on_task_done);
        get_style_context ().add_class ("task_layout");
    }

    /**
     * Initializes everything that doesn't depend on a TodoTask.
     */
    private void initial_setup () {
        /* Instantiation of available widgets */
        activity_stack = new Gtk.Stack ();
        activity_switcher = new ViewSwitcher ();
        timer_view = new TimerView (task_timer);

        // Activity Stack + Switcher
        activity_switcher.halign = Gtk.Align.CENTER;
        activity_switcher.icon_size = Gtk.IconSize.LARGE_TOOLBAR;
        activity_switcher.append ("primary", _("To-Do"), null);
        activity_switcher.append ("timer", _("Timer"), GOFI.ICON_NAME);
        activity_switcher.append ("secondary", _("Done"), null);
        activity_stack.set_transition_type (
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        );

        activity_switcher.notify["selected-item"].connect (() => {
            activity_stack.set_visible_child_name (activity_switcher.selected_item);
        });

        this.add (activity_stack);
    }

    public Gtk.Widget get_switcher () {
        return activity_switcher;
    }

    public void show_switcher (bool show) {
        activity_switcher.set_visible (show);
    }

    /**
     * Adds the widgets from task_list as well as timer_view to the stack.
     */
    private void add_widgets () {
        string first_page_name;
        string second_page_name;

        /* Instantiation of the Widgets */
        first_page = task_list.get_primary_page (out first_page_name);
        last_page = task_list.get_secondary_page (out second_page_name);

        if(first_page_name == null) {
           first_page_name = _("To-Do");
        }
        if(second_page_name == null) {
           second_page_name = _("Done");
        }

        // Add widgets to the activity stack
        activity_stack.add_titled (first_page, "primary", first_page_name);
        activity_stack.add_titled (timer_view, "timer", _("Timer"));
        activity_stack.add_titled (last_page, "secondary", second_page_name);

        if (task_timer.running) {
            // Otherwise no task will be displayed in the timer view
            task_timer.update_active_task ();
            // Otherwise it won't switch
            timer_view.show ();
            activity_stack.set_visible_child (timer_view);
        }
        else {
            first_page.show ();
            activity_stack.set_visible_child (first_page);
        }
    }

    /**
     * Updates this to display the new TxtList.
     */
    public void set_task_list (TxtList task_list) {
        if (this.task_list != null) {
            remove_task_list ();
        }
        this.task_list = task_list;
        this.task_list.load ();
        task_list.notify["active-task"].connect (on_active_task_changed);
        task_list.notify["selected-task"].connect (on_selected_task_changed);
        add_widgets ();
        this.show_all ();
        on_selected_task_changed ();
    }

    private void on_task_done () {
        task_list.mark_done (task_timer.active_task);
    }

    private void on_active_task_changed () {
        task_timer.active_task = task_list.active_task;
    }

    private void on_selected_task_changed () {
        // Don't change task, while timer is running
        if (!task_timer.running) {
            task_timer.active_task = task_list.selected_task;
            task_list.active_task = task_list.selected_task;
        }
    }

    /**
     * Restores this to its state from before set_task_list was called.
     */
    public void remove_task_list () {
        task_timer.stop ();
        if (task_list != null) {
            task_list.unload ();
            task_list.notify["active-task"].disconnect (on_active_task_changed);
            task_list.notify["selected-task"].disconnect (on_selected_task_changed);
        }
        foreach (Gtk.Widget widget in activity_stack.get_children ()) {
            activity_stack.remove (widget);
        }

        first_page = null;
        last_page = null;

        task_timer.reset ();

        task_list = null;
    }

    public void toggle_filter_bar () {
        warning("Stub!\n");
    }

    /**
     * Returns true if this widget has been properly initialized.
     */
    public bool ready {
        get {
            return (task_list != null);
        }
    }
}
