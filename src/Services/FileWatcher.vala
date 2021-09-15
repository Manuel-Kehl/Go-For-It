/* Copyright 2017 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

/**
 * This class is used to monitor files, unlike FileMonitor it only emits changed
 * only a single time after a modification of a file, and it will only do so if
 * the etag has changed.
 */
class GOFI.FileWatcher {
    private FileMonitor monitor;
    private string etag;
    private bool changed_received;

    public bool watching {
        set {
            _watching = value;
            update_etag ();
        }
        get {
            return _watching;
        }
    }
    bool _watching;

    public bool being_updated {
        get;
        private set;
    }

    public File file {
        set {
            _file = value;
            try {
                monitor = _file.monitor_file (FileMonitorFlags.NONE, null);
                update_etag ();
            } catch (IOError e) {
                warning ("%s", e.message);
            }
        }
        get {
            return _file;
        }
    }
    File _file;

    public signal void changed ();

    public FileWatcher (File file) {
        etag = "";
        this.file = file;
        being_updated = false;
        watching = true;

        monitor.changed.connect (on_file_changed);
    }

    private string get_etag () {
        try {
            FileInfo file_info;
            file_info = _file.query_info (GLib.FileAttribute.ETAG_VALUE, 0);
            return file_info.get_etag ();
        } catch (Error e) {
            warning (e.message);
            return "";
        }
    }

    private bool update_etag () {
        string new_etag = get_etag ();
        if (new_etag != etag) {
            etag = new_etag;
            return true;
        }
        return false;
    }

    /**
     * Calls emit_signal_if_changed after a delay so the application or service
     * that is writing to the file has a chance to finish.
     * If we are already going to call emit_signal_if_changed we set
     * changed_received to true which will cause the next call to this function
     * to abort and repeat with a delay.
     */
    private void on_file_changed () {
        if (!_watching) {
            return;
        }
        if (being_updated) {
            changed_received = true;
        } else {
            being_updated = true;

            GLib.Timeout.add (
                100, emit_signal_if_changed, GLib.Priority.DEFAULT_IDLE
            );
        }
    }

    private bool emit_signal_if_changed () {
        if (changed_received) {
            changed_received = false;
            return true;
        }
        if (watching && update_etag ()) {
            changed ();
        }

        being_updated = false;

        return false;
    }
}
