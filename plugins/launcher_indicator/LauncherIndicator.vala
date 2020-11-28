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

#if USE_GRANITE
using Granite.Services.Application;
#else
using Builtin.Granite.Services.Application;
#endif

class GOFI.Plugins.LauncherIndicator : GLib.Object, Peas.Activatable {
    private bool timer_running = false;
    private int64 displayed_count;

    /**
     * The plugin interface.
     */
    public Object object { owned get; construct; }

    private GOFI.PluginInterface iface {
        owned get {
            return (GOFI.PluginInterface) object;
        }
    }

    public void activate () {
        displayed_count = 0;
        connect_timer_signals ();
    }

    private void update_timer_count (uint timer_value) {
        if (!timer_running) {
            return;
        }
        uint hours, minutes, seconds;
        GOFI.Utils.uint_to_time (timer_value, out hours, out minutes, out seconds);
        minutes += hours * 60;
        int64 to_show = seconds;
        if (minutes > 0) {
            if (seconds >= 30) {
                minutes += 1;
            }
            to_show = minutes;
        }
        if (displayed_count != to_show) {
            set_badge.begin (to_show);
            displayed_count = to_show;
        }
    }

    private void on_timer_started () {
        timer_running = true;
        displayed_count = 0;
        set_badge_visible.begin (true);
        update_timer_count (iface.get_timer ().remaining_duration);
    }

    private void on_timer_stopped () {
        timer_running = false;
        set_badge_visible.begin (false);
    }

    private void connect_timer_signals () {
        var timer = iface.get_timer ();
        if (timer.running) {
            on_timer_started ();
        }
        timer.timer_updated.connect (update_timer_count);
        timer.timer_started.connect (on_timer_started);
        timer.timer_stopped.connect (on_timer_stopped);
    }

    private void disconnect_timer_signals () {
        var timer = iface.get_timer ();
        timer.timer_updated.disconnect (update_timer_count);
        timer.timer_started.disconnect (on_timer_started);
        timer.timer_stopped.disconnect (on_timer_stopped);
    }

    public void deactivate () {
        set_badge_visible.begin (false);
        disconnect_timer_signals ();
    }

    public void update_state () {}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                       typeof (GOFI.Plugins.LauncherIndicator));
}
