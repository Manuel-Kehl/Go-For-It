/* Copyright 2014-2017 Go For It! developers
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
 * A class to provide simple notifications on Windows using notify-send
 */
class WinNotification {
    private string title;
    private string message;
    
    public WinNotification (string title, string message) {
        this.title = title;
        this.message = message;
    }
    
    public void show () throws GLib.SpawnError {
        string command = "notify-send \"%s\" \"%s\"".printf (title, message);
        
        GLib.Process.spawn_command_line_async (command);
    }
}

