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

public class GOFI.Schedule {
    private int[] durations;
    public uint length {
        get {
            return _length;
        }
        private set {
            _length = value;
        }
    }
    private uint _length;

    public bool valid {
        get {
            return length > 0;
        }
    }

    public Schedule () {
        durations = {};
        length = 0;
    }

    public void append_multiple (int[] durations) {
        var added_length = durations.length;
        if (added_length % 2 == 1) {
            added_length -= 1;
            warning ("The added durations array has an uneven length, discarding the last entry");
        }
        this.durations.resize ((int) (2 * _length + added_length));
        Memory.copy (((int*) this.durations) + _length*2, durations, sizeof(int)*added_length);
        length += added_length;
    }

    public void append (int task_duration, int break_duration) {
        durations += task_duration;
        durations += break_duration;
        length++;
    }

    public int get_task_duration (uint iteration) {
        return durations[(iteration % _length)*2].abs ();
    }

    public int get_break_duration (uint iteration) {
        return durations[(iteration % _length)*2+1].abs ();
    }

    public void set_durations (int[] durations) {
        var new_length = durations.length;
        if (new_length % 2 == 1) {
            new_length -= 1;
            warning ("The new durations array has an uneven length, discarding the last entry");
        }
        if (new_length != this.durations.length) {
            this.durations.resize ((int) (new_length));
        }
        Memory.copy (this.durations, durations, sizeof(int)*new_length);
        length = new_length / 2;
    }

    public unowned int[] get_durations () {
        return durations;
    }
}
