/* Copyright 2013 Manuel Kehl (mank319)
*
* This file is part of Just Do It!.
*
* Just Do It! is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Just Do It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Just Do It!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * The JDI namespace is a central collection of static constants that are 
 * realted to "Just Do it!".
 *
 * The naming rules are as follows:
 * - Entries describing a KeyFile group: CONF_GROUP_groupname
 * - Entries describing a KeyFile entry: CONF_groupname_configname
 * - Entries describing file names: FILE_filename
 */
namespace JDI {
    /* Strings */
    const string APP_NAME = "Just Do It!";
    const string APP_ID = "de.manuel-kehl.just-do-it";
    const string CONF_GROUP_TODO_TXT = "Todo.txt";
    const string CONF_TODO_TXT_LOCATION = "location";
    const string FILE_CONF = "just-do-it.conf";
    const string[] TEST_DIRS = {
        "Todo", "todo", ".todo", 
        "Dropbox/Todo", "Dropbox/todo"
    };
    
    /* Numeric Values */
    const int DEFAULT_WIN_WIDTH = 350;
    const int DEFAULT_WIN_HEIGHT = 700;
    
    /** 
     * A collection of static utility functions.
     */
    public class Utils {
        public static Time hms_to_time (int h, int m, int s) {
            int time = s + m * 60 + h * 3600;
            return Time.local (time);
        }
    }
}
