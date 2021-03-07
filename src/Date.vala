/* Copyright 2021 Go For It! developers
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
 * Helper class for DateTime instances without time or with floating time
 */
public class GOFI.Date {
    private GLib.DateTime _dt;
    private bool _has_time;
    private bool _time_is_floating;

    public GLib.DateTime dt {
        get {
            return _dt;
        }
    }

    /**
     * Should dt be interpreted as a DateTime value with a date.
     */
    public bool has_time {
        get {
            return _has_time;
        }
    }

    /**
     * Should dt be interpreted as a DateTime value with a timezone.
     */
    public bool time_is_floating {
        get {
            return _time_is_floating;
        }
    }

    public Date (GLib.DateTime dt, bool has_time = false, bool time_is_floating = true) {
        this._dt = dt;
        this._has_time = has_time;
        this._time_is_floating = time_is_floating;
    }

    public Date.from_ymd (int year, int month, int day) {
        _dt = new DateTime.utc (year, month, day, 0, 0, 0.0);
        this._has_time = false;
        this._time_is_floating = true;
    }

    /**
     * Returns DateTime contained in this converted to the timezone of tz.
     * If this has a floating time this time will be applied without timezone
     * conversions.
     * If this doesn't have a time set the returned time will be set 00:00:00.
     * If tz is null the local timezone will be used.
     */
    public GLib.DateTime to_timezone (TimeZone? tz) {
        int year, month, day;
        if (has_time) {
            if (time_is_floating) {
                dt.get_ymd (out year, out month, out day);
                if (tz == null) {
                    return new DateTime.local (
                        year, month, day,
                        dt.get_hour (), dt.get_minute (), dt.get_seconds ()
                    );
                }
                return new DateTime (
                    tz, year, month, day,
                    dt.get_hour (), dt.get_minute (), dt.get_seconds ()
                );
            }
            if (tz == null) {
                return dt.to_local ();
            }
            return dt.to_timezone (tz);
        }
        dt.get_ymd (out year, out month, out day);
        if (tz == null) {
            return new DateTime.local (year, month, day, 0, 0, 0.0);
        }
        return new DateTime (tz, year, month, day, 0, 0, 0.0);
    }

    public int dt_compare_date (DateTime dt) {
        int a_year, a_month, a_day;
        int b_year, b_month, b_day;

        this.dt.get_ymd (out a_year, out a_month, out a_day);
        dt.get_ymd (out b_year, out b_month, out b_day);

        int result = 0;

        if ((result = a_year - b_year) != 0) {
            return result;
        }
        if ((result = a_month - b_month) != 0) {
            return result;
        }
        return a_day - b_day;
    }

    public int compare (Date date) {
        return this.to_timezone (null).compare (date.to_timezone (null));
    }

    public int days_between (Date date) {
        int a_year, a_month, a_day;
        int b_year, b_month, b_day;
        GLib.Date a_date = GLib.Date ();
        GLib.Date b_date = GLib.Date ();

        this.dt.get_ymd (out a_year, out a_month, out a_day);
        dt.get_ymd (out b_year, out b_month, out b_day);

        a_date.set_dmy (
            (GLib.DateDay) a_day, (GLib.DateMonth) a_month, (GLib.DateYear) a_year
        );
        b_date.set_dmy (
            (GLib.DateDay) b_day, (GLib.DateMonth) b_month, (GLib.DateYear) b_year
        );

        return a_date.days_between (b_date);
    }
}
