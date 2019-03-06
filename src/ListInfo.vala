/* Copyright 2019 Go For It! developers
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
 * Information used to display and select the lists in SelectionPage, also used
 * to keep track of which list is currently loaded.
 * This interface is subject to change.
 */
public interface GOFI.TodoListInfo : Object{

    public abstract string id {
        get;
    }

    public abstract string plugin_name {
        get;
    }

    public abstract string name {
        get;
        set;
    }
}
