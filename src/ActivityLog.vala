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
 * This class is used to log which tasks the user worked on as well as when
 * the user worked on this task and for how long.
 */
class GOFI.ActivityLog {
    private File? log_file;

    public ActivityLog (File? log_file) {
        this.log_file = log_file;
    }

    public void log_task (string list_name, string task_description, DateTime start_time, uint runtime) {
        if (log_file == null) {
            return;
        }

        var start_time_local = start_time.to_local ();

        try {
            if (!log_file.query_exists ()) {
                DirUtils.create_with_parents (log_file.get_parent ().get_path (), 0700);
                log_file.create (FileCreateFlags.NONE);
            }
            var file_out_stream =
                log_file.append_to (FileCreateFlags.NONE, null);
            var stream_out =
                new DataOutputStream (file_out_stream);

            stream_out.put_string ("\"%s\", \"%s\", %u, %s, %s\r\n".printf (
                list_name.replace ("\"", "\"\""),
                task_description.replace ("\"", "\"\""),
                runtime,
                start_time_local.to_string (),
                start_time_local.add (((int64)runtime)*1000000).to_string ()
            ));
        } catch (Error e) {
            warning (_("Couldn't write to %s: %s"), log_file.get_path (), e.message);
        }
    }
}
