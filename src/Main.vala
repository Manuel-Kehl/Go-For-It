/* Copyright 2014 Manuel Kehl (mank319)
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
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
 * The main application class that is responsible for initiating all
 * necessary steps to create a running instance of "Go For It!".
 */
public class Main : Gtk.Application {
    private SettingsManager settings;
    private TaskManager task_manager;
    private TaskTimer task_timer;
    private MainWindow win;
    /**
     * Constructor of the Application class.
     */
    private Main () {
        Object (application_id: GOFI.APP_ID, flags: ApplicationFlags.FLAGS_NONE);
    }
    
    /**
     * The entry point for running the application.
     */
    public static int main (string[] args) {
        Main app = new Main ();
        int status = app.run (args);
        return status;
    }
    
    public override void activate () {
        // Don't create a new window, if one already exists
        if (win != null) {
            win.show_all ();
            win.present ();
            return;
        }
        
        settings = new SettingsManager.load_from_key_file ();
        task_manager = new TaskManager(settings);
        task_timer = new TaskTimer (settings);
        task_timer.active_task_done.connect (task_manager.mark_task_done);
        win = new MainWindow (this, task_manager, task_timer, settings);
        win.show_all ();
        
        /*
         * If the timer is currently active, create a new hidden instance of
         * MainWindow, so that the app keeps running in the background.
         */
        this.window_removed.connect ((e) => {
            if (task_timer.running) {
                win = new MainWindow (this, task_manager, task_timer, settings);
            }
        });
        
    }
}
