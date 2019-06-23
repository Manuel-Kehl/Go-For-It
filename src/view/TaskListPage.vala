/* Copyright 2018-2019 Go For It! developers
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* Go For It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Go For It!. If not, see http://www.gnu.org/licenses/.
*/

using GOFI.TXT;

/**
 * A widget containing a TaskList and its widgets and the TimerView.
 */
class GOFI.TaskListPage : Gtk.Grid {
    private TxtList task_list = null;
    private SettingsManager settings;
    private TaskTimer task_timer;

    /* Various GTK Widgets */
    private Gtk.Stack activity_stack;
    private ViewSwitcher activity_switcher;
    private Gtk.Stack switcher_stack;

    private Gtk.Widget first_page;
    private TimerView timer_view;
    private Gtk.Widget last_page;

    public signal void removing_list ();

    [Signal (action = true)]
    public virtual signal void switch_to_next () {
        if (task_list == null) {
            return;
        }
        var next = task_list.get_next ();

        if (next != null) {
            task_timer.stop ();
            task_list.active_task = next;
        }
    }

    [Signal (action = true)]
    public virtual signal void switch_to_prev () {
        if (task_list == null) {
            return;
        }
        var prev = task_list.get_prev ();

        if (prev != null) {
            task_timer.stop ();
            task_list.active_task = prev;
        }
    }

    [Signal (action = true)]
    public virtual signal void mark_task_done () {
        var visible_child = activity_stack.get_visible_child ();
        if (visible_child == first_page) {
            var selected_task = task_list.selected_task;
            if (selected_task != null) {
                task_list.mark_done (selected_task);
            }
        } else if (visible_child == timer_view) {
            task_timer.set_active_task_done ();
        }
    }

    /**
     * The constructor of the TaskListPage class.
     */
    public TaskListPage (SettingsManager settings, TaskTimer task_timer)
    {
        this.task_timer = task_timer;
        this.settings = settings;

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
        switcher_stack = new Gtk.Stack ();
        activity_switcher = new ViewSwitcher ();
        timer_view = new TimerView (task_timer);
        var activity_label = new Gtk.Label (_("Lists"));
        activity_label.get_style_context ().add_class ("title");

        // Activity Stack + Switcher
        activity_switcher.halign = Gtk.Align.CENTER;
        activity_switcher.icon_size = Gtk.IconSize.LARGE_TOOLBAR;
        activity_switcher.append ("primary", _("To-Do"), "go-to-list-symbolic");
        activity_switcher.append ("timer", _("Timer"), GOFI.ICON_NAME);
        activity_switcher.append ("secondary", _("Done"), "go-to-done");
        activity_stack.set_transition_type (
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        );
        switcher_stack.set_transition_type (
            Gtk.StackTransitionType.SLIDE_UP_DOWN
        );
        activity_switcher.icon_size = settings.toolbar_icon_size;
        activity_switcher.show_icons = settings.switcher_use_icons;

        activity_switcher.notify["selected-item"].connect (() => {
            var selected = activity_switcher.selected_item;
            activity_stack.set_visible_child_name (selected);
            if (selected == "timer") {
                timer_view.set_focus ();
            }
        });
        settings.toolbar_icon_size_changed.connect (on_icon_size_changed);
        settings.switcher_use_icons_changed.connect (on_switcher_use_icons);

        switcher_stack.add_named (activity_switcher, "switcher");
        switcher_stack.add_named (activity_label, "label");
        this.add (activity_stack);
    }

    public Gtk.Widget get_switcher () {
        return switcher_stack;
    }

    public void show_switcher (bool show) {
        if (show) {
            switcher_stack.set_visible_child_name ("switcher");
        } else {
            switcher_stack.set_visible_child_name ("label");
        }
    }

    public void action_add_task () {
        activity_switcher.selected_item = "primary";
        task_list.task_entry_focus ();
    }

    public bool switch_page_left () {
        switch (activity_switcher.selected_item) {
            case "timer":
                activity_switcher.selected_item = "primary";
                return false;
            case "secondary":
                activity_switcher.selected_item = "timer";
                return false;
            default:
                return true;
        }
    }

    public bool switch_page_right () {
        switch (activity_switcher.selected_item) {
            case "primary":
                activity_switcher.selected_item = "timer";
                return false;
            case "timer":
                activity_switcher.selected_item = "secondary";
                return false;
            default:
                return true;
        }
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
        task_list.timer_values_changed.connect (update_timer_values);
        update_timer_values (
            task_list.get_active_task_duration (),
            task_list.get_active_break_duration (),
            task_list.get_reminder_time ()
        );
        add_widgets ();
        this.show_all ();
        on_selected_task_changed ();
    }

    private void update_timer_values (int task_d, int break_d, int reminder_t) {
        task_timer.task_duration = task_d;
        task_timer.break_duration = break_d;
        task_timer.reminder_time = reminder_t;
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

    private void on_icon_size_changed (Gtk.IconSize size) {
        activity_switcher.icon_size = size;
    }

    private void on_switcher_use_icons (bool show_icons) {
        activity_switcher.show_icons = show_icons;
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
            task_list.timer_values_changed.disconnect (update_timer_values);
        }
        foreach (Gtk.Widget widget in activity_stack.get_children ()) {
            activity_stack.remove (widget);
        }

        first_page = null;
        last_page = null;

        task_timer.reset ();

        task_list = null;
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
