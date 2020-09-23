/* Copyright 2020 Go For It! developers
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
public class GOFI.PluginInterface : GLib.Object {

    private unowned PluginManager plugin_manager;
    private TaskTimer timer;

    public TaskTimer get_timer () {
        return timer;
    }

    internal PluginInterface (PluginManager plugin_manager, TaskTimer timer) {
        this.plugin_manager = plugin_manager;
        this.timer = timer;
    }
}
