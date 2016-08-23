/* Copyright 2014-2016 Go For It! developers
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

/**
 * A dialog for changing the application's settings.
 */
class GOFI.SettingsDialog : Gtk.Dialog {
    private SettingsManager settings;
    private PluginManager plugin_manager;
    
    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Stack stack;
    private Gtk.StackSwitcher switcher;
    // pages
    private SettingsGrid plugins_page;
    private SettingsGrid txt_page; // to be moved elsewhere later
    private SettingsGrid behavior_page;
    private SettingsGrid appearance_page;
    
    public SettingsDialog (Gtk.Window? parent, SettingsManager settings, 
                           PluginManager plugin_manager)
    {
        this.set_transient_for (parent);
        this.settings = settings;
        this.plugin_manager = plugin_manager;
        
        setup_main_layout ();
        
        /* General Settigns */
        // Default to minimum possible size
        this.set_default_size (1, 1);
        this.get_content_area ().pack_start (main_layout);
        this.set_modal (true);
        
        this.title = _("Settings");
        this.add_button (_("Close"), Gtk.ResponseType.CLOSE);
        
        /* Action Handling */
        this.response.connect ((s, response) => {
            if (response == Gtk.ResponseType.CLOSE) {
                plugin_manager.save_loaded ();
                this.destroy ();
            }
        });
        
        this.show_all ();
    }
    
    private void setup_main_layout () {
        /* Initalization */
        main_layout = new Gtk.Grid ();
        stack = new Gtk.Stack ();
        switcher = new Gtk.StackSwitcher ();
        
        /* Configuration */
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        
        // Stack + Switcher
        switcher.set_stack (stack);
        switcher.halign = Gtk.Align.CENTER;
        switcher.vexpand = false;
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        
        // pages
        setup_plugins_page ();
        setup_txt_page ();
        setup_behavior_page ();
        setup_appearance_page ();
        
        /* Add widgets */
        main_layout.add (switcher);
        main_layout.add (stack);
        stack.add_titled (plugins_page, "plugins", _("Plugins"));
        stack.add_titled (txt_page, "txt", _("Todo.txt"));
        stack.add_titled (behavior_page, "behavior", _("Behavior"));
        stack.add_titled (appearance_page, "appearance", _("Appearance"));
    }
    
    private void setup_plugins_page () {
        /* Declaration */
        Gtk.Widget plugin_settings_widget;
        
        /* Instantiation */
        plugins_page = new SettingsGrid ();
        plugin_settings_widget = plugin_manager.get_settings_widget ();
        
        /* Configuration */
        plugin_settings_widget.expand = true;
        
        /* Add widgets */
        plugins_page.add (plugin_settings_widget);
    }
    
    private void setup_txt_page () {
        /* Declaration */
        Gtk.Label txt_sect_lbl;
        Gtk.Label directory_lbl;
        Gtk.Label directory_explanation_lbl;
        Gtk.FileChooserButton directory_btn;
        
        /* Instantiation */
        txt_page = new SettingsGrid ();
        txt_sect_lbl = new Gtk.Label ("Todo.txt");
        directory_btn = new Gtk.FileChooserButton (
            "Todo.txt " + _("directory"), Gtk.FileChooserAction.SELECT_FOLDER
        );    
        directory_lbl = new Gtk.Label (
            "<a href=\"http://todotxt.com\">Todo.txt</a> "
            + _("directory") + ":"
        );
        directory_explanation_lbl = new Gtk.Label (
            _("If no appropriate folder was found, Go For It! defaults to creating a Todo folder in your home directory.")
        );
        
        /* Configuration */
        directory_lbl.set_line_wrap (false);
        directory_lbl.set_use_markup (true);
        directory_explanation_lbl.set_line_wrap (true);
        ((Gtk.Misc) directory_explanation_lbl).xalign = 0f;
        directory_btn.create_folders = true;
        directory_btn.set_current_folder (settings.todo_txt_location);
        
        /* Signal Handling */
        directory_btn.file_set.connect ((e) => {
            var todo_dir = directory_btn.get_file ().get_path ();
            settings.todo_txt_location = todo_dir;
        });
        
        txt_page.add_section (txt_sect_lbl);
        txt_page.add_explanation (directory_explanation_lbl);
        txt_page.add_setting (directory_lbl, directory_btn);
    }
    
    private void setup_behavior_page () {
        /* Declaration */
        Gtk.Label timer_sect_lbl;
        Gtk.Label task_lbl;
        Gtk.SpinButton task_spin;
        Gtk.Label break_lbl;
        Gtk.SpinButton break_spin;
        Gtk.Label reminder_lbl;
        Gtk.SpinButton reminder_spin;
        
        /* Instantiation */
        behavior_page = new SettingsGrid ();
        timer_sect_lbl = new Gtk.Label (_("Timer"));
        task_lbl = new Gtk.Label (_("Task duration (minutes)") + ":");
        break_lbl = new Gtk.Label (_("Break duration (minutes)") + ":");
        reminder_lbl = new Gtk.Label (_("Reminder before task ends (seconds)") +":");

        // No more than one day: 60 * 24 -1 = 1439
        task_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        break_spin = new Gtk.SpinButton.with_range (1, 1439, 1);
        // More than ten minutes would not make much sense
        reminder_spin = new Gtk.SpinButton.with_range (0, 600, 1);
        
        /* Configuration */
        task_spin.value = settings.task_duration / 60;
        break_spin.value = settings.break_duration / 60;
        reminder_spin.value = settings.reminder_time;
        
        /* Signal Handling */
        task_spin.value_changed.connect ((e) => {
            settings.task_duration = task_spin.get_value_as_int () * 60;
        });
        break_spin.value_changed.connect ((e) => {
            settings.break_duration = break_spin.get_value_as_int () * 60;
        });
        reminder_spin.value_changed.connect ((e) => {
            settings.reminder_time = reminder_spin.get_value_as_int ();
        });
        
        /* Add widgets */
        behavior_page.add_section(timer_sect_lbl);
        behavior_page.add_setting (task_lbl, task_spin);
        behavior_page.add_setting (break_lbl, break_spin);
        behavior_page.add_setting (reminder_lbl, reminder_spin);
    }
    
    private void setup_appearance_page () {
        /* Declaration */
        Gtk.Label csd_sect_lbl;
        Gtk.Label csd_explanation_lbl;
        Gtk.Label headerbar_lbl;
        Gtk.Switch headerbar_switch;
        
        /* Instantiation */
        appearance_page = new SettingsGrid ();
        csd_sect_lbl = new Gtk.Label (_("Client side decorations"));
        csd_explanation_lbl = new Gtk.Label (_("Go For It! needs to restart for changes to have an effect."));
        headerbar_lbl = new Gtk.Label (_("Use a header bar") + (":"));
        headerbar_switch = new Gtk.Switch ();
        
        /* Configuration */
        headerbar_switch.active = settings.use_header_bar;
        
        /* Signal Handling */
        headerbar_switch.notify["active"].connect ( () => {
            settings.use_header_bar = headerbar_switch.active;
        });
        
        /* Add widgets */
        appearance_page.add_section (csd_sect_lbl);
        appearance_page.add_explanation (csd_explanation_lbl);
        appearance_page.add_setting (headerbar_lbl, headerbar_switch);
    }
}

/**
 * A container to help make a consistent settings screen for Go For It!
 * 
 * The class contains several functions that aligning, styling and add widgets 
 * to it.
 */
public class GOFI.SettingsGrid : Gtk.Grid {
    private int row;
    
    public SettingsGrid () {
        orientation = Gtk.Orientation.VERTICAL;
        row_spacing = 10;
        column_spacing = 10;
        margin = 10;
        
        row = 0;
    }
    
    /**
     * Adds a section label to the grid.
     * Markup is applied to the label, the label is aligned and added below the
     * previous row.
     * @param label title label of the section
     */
    public void add_section (Gtk.Label label) {
        label.set_markup ("<b>%s</b>".printf (label.get_text()));
        label.halign = Gtk.Align.START;
        
        attach (label, 0, row, 2, 1);
        row++;
    }
    
    /**
     * Adds a row containing a label and an other widget to the grid.
     * @param label a label clarifying what setting is modified
     * @param switcher widget to change the setting with
     */
    public void add_setting (Gtk.Widget label, Gtk.Widget switcher) {
        label.hexpand = true;
        label.margin_left = 20; // indentation relative to the section label
        label.halign = Gtk.Align.START;
        
        switcher.hexpand = true;
        switcher.halign = Gtk.Align.FILL;
        
        if (switcher is Gtk.Switch || switcher is Gtk.Entry) {
            switcher.halign = Gtk.Align.START;
        }
        
        attach (label, 0, row, 1, 1);
        attach (switcher, 1, row, 1, 1);
        row++;
    }
    
    /**
     * Adds an explanation to the grid.
     * @param label a label containing an explanation for a setting or section
     */
    public void add_explanation (Gtk.Label label) {
        label.hexpand = true;
        label.margin_left = 20; // indentation relative to the section label
        label.halign = Gtk.Align.START;
        
        attach (label, 0, row, 2, 1);
        row++;
    }
}
