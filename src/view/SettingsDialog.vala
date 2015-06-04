/* Copyright 2014 Manuel Kehl (mank319)
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
public class SettingsDialog : Gtk.Dialog {
    private SettingsManager settings;
    /* GTK Widgets */
    private Gtk.Grid main_layout;
    private Gtk.Label directory_lbl;
    private Gtk.Label directory_explanation_lbl;
    private Gtk.FileChooserButton directory_btn;
    private Gtk.Label task_lbl;
    private Gtk.SpinButton task_spin;
    private Gtk.Label break_lbl;
    private Gtk.SpinButton break_spin;
    private Gtk.Label reminder_lbl;
    private Gtk.SpinButton reminder_spin;
    
    public SettingsDialog (Gtk.Window? parent, SettingsManager settings) {
        this.set_transient_for (parent);
        this.settings = settings;
        /* Initalization */
        main_layout = new Gtk.Grid ();
        
        /* General Settigns */
        // Default to minimum possible size
        this.set_default_size (1, 1);
        this.get_content_area ().margin = 10;
        this.get_content_area ().pack_start (main_layout);
        this.set_modal (true);
        main_layout.visible = true;
        main_layout.orientation = Gtk.Orientation.VERTICAL;
        main_layout.row_spacing = 15;
        
        this.title = _("Settings");
        setup_settings_widgets (true);
        this.add_button (_("Close"), Gtk.ResponseType.CLOSE);
        
        /* Settings that apply for all widgets in the dialog */
        foreach (var child in main_layout.get_children ()) {
            child.visible = true;
            child.halign = Gtk.Align.START;
        }
        
        /* Action Handling */
        this.response.connect ((s, response) => {
            if (response == Gtk.ResponseType.CLOSE) {
                this.destroy ();
            }
        });
    }
    
    private void setup_settings_widgets (bool advanced) {
        /* Instantiation */
        directory_btn = new Gtk.FileChooserButton ("Todo.txt " + _("directory"),
            Gtk.FileChooserAction.SELECT_FOLDER);
            
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
        directory_btn.create_folders = true;
        directory_btn.set_current_folder (settings.todo_txt_location);
        
        /* Signal Handling */
        directory_btn.file_set.connect ((e) => {
            var todo_dir = directory_btn.get_file ().get_path ();
            settings.todo_txt_location = todo_dir;
        });
        
        /* Add widgets */
        main_layout.add (directory_lbl);
        main_layout.add (directory_explanation_lbl);
        main_layout.add (directory_btn);
        
        if (advanced) {
            setup_advanced_settings_widgets ();
        }
        
    }
    
    // This function allows for advanced settings in the future
    private void setup_advanced_settings_widgets () {
        /* Instantiation */
        task_lbl = new Gtk.Label (_("Task duration in minutes") + ":");
        break_lbl = new Gtk.Label (_("Break duration in minutes") + ":");
        reminder_lbl = new Gtk.Label (_("Reminder before task ends in seconds") +":");
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
        main_layout.add (task_lbl);
        main_layout.add (task_spin);
        main_layout.add (break_lbl);
        main_layout.add (break_spin);
        main_layout.add (reminder_lbl);
        main_layout.add (reminder_spin);
    }
}
