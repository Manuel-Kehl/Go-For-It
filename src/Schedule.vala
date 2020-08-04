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

    public void import_raw (int[] durations) {
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

    public unowned int[] export_raw () {
        return durations;
    }

    /**
     * Populates the schedule with the contents of a variant with variant type
     * "a(ii)"
     */
    public void load_variant (Variant variant) {
        size_t schedule_length = variant.n_children ();
        durations = new int[schedule_length*2];
        for (size_t i = 0; i < schedule_length; i++) {
            int t_duration, b_duration;
            variant.get_child (i, "(ii)", out t_duration, out b_duration);

            // Input sanitizing
            if (t_duration <= 0) {
                t_duration = 1500;
            }
            if (b_duration < 0) {
                b_duration = 300;
            }

            durations[2*i]   = t_duration;
            durations[1+2*i] = b_duration;
        }
        _length = (uint) schedule_length;
    }

    /**
     * Exports the contents of this to a variant with variant type "a(ii)"
     */
    public Variant to_variant () {
        Variant[] sched_tuples = new Variant[_length];
        for (uint i = 0; i < _length; i++) {
            sched_tuples[i] = new Variant.tuple ({
                new Variant.int32 (durations[2*i]),
                new Variant.int32 (durations[1+2*i])
                }
            );
        }
        return new Variant.array (new VariantType ("(ii)"), sched_tuples);
    }
}
