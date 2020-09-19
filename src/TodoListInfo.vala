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

    /**
     * The id of a to-do list must stay constant over the entire lifetime of
     * this list. On restarting the application the id must remain the same.
     */
    public abstract string id {
        construct set;
        get;
    }

    /**
     * Field that currently is not in use.
     * This field will be used when the application supports formats other than
     * Todo.txt.
     */
    public abstract string provider_name {
        get;
    }

    /**
     * The name the user assigned to the list corresponding with this object.
     */
    public abstract string name {
        get;
        set;
    }

    public int cmp (TodoListInfo other) {
        var provider_cmp = strcmp (this.provider_name, other.provider_name);
        if (provider_cmp == 0) {
            return strcmp (this.id, other.id);
        }
        return provider_cmp;
    }
}
