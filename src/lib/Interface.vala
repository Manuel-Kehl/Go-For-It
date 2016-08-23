/* Copyright 2016 Go For It! developers
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
 * Interface to be used by plugins.
 */
public class GOFI.Interface : GLib.Object {
    
    private weak PluginManager plugin_manager;
    
    /**
     * This signal is emitted whenever the time of the timer is updated.
     * @param remaining_duration time remaining untill the break or untill the 
     * end of the break
     */
    public signal void timer_updated (DateTime remaining_duration);
    
    /**
     * This signal is emitted whenever the time of the timer is updated.
     * @param progress value between 0 and 1: the amount of time that has passed
     * relative to the total time.
     */
    public signal void timer_updated_relative (double progress);
    
    /**
     * This signal is emitted when the timer is either stopped or started.
     * @param running whether the timer is currently running
     */
    public signal void timer_running_changed (bool running);
    
    /**
     * This signal is emitted when it's almost time for a break.
     * @param remaining_duration time remaining untill the break
     */
    public signal void timer_almost_over (DateTime remaining_duration);
    
    /**
     * This signal is emitted once the timer reaches 0.
     * @param break_active whether the break is currently active
     */
    public signal void timer_finished (bool break_active);
    
    internal Interface (PluginManager plugin_manager) {
        this.plugin_manager = plugin_manager;
    }
}

namespace GOFI {
    
    /**
     * Returns the string representation of version of Go For It!
     */
    public static string get_version () {
        return APP_VERSION;
    }
}
