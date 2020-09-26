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

using AppIndicator;

/**
 * The main window of Go For It!.
 */
class GOFI.Plugins.PanelIndicator : GLib.Object, Peas.Activatable {

    private Indicator indicator;
    private uint shown_hours = 0;
    private uint shown_minutes = 0;
    private uint shown_seconds = 0;
    private bool timer_running = false;
    private string? active_task_description = null;
    private Gtk.MenuItem task_descr_item;
    private Gtk.MenuItem show_item;
    private Gtk.MenuItem start_timer_item;

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
        if (indicator != null) {
            return;
        }
        indicator = new Indicator(GOFI.APP_ID, GOFI.ICON_NAME, IndicatorCategory.APPLICATION_STATUS);
        indicator.set_status(IndicatorStatus.ACTIVE);
        indicator.set_attention_icon("indicator-messages-new");

        var menu = new Gtk.Menu();

        show_item = new Gtk.MenuItem.with_label("Open %s".printf (GOFI.APP_NAME));
        show_item.activate.connect(show_application_window);
        show_item.show ();
        menu.append (show_item);

        var separator_item = new Gtk.SeparatorMenuItem ();
        separator_item.show ();
        menu.append (separator_item);

        task_descr_item = new Gtk.MenuItem.with_label("No task selected");
        task_descr_item.sensitive = false;
        task_descr_item.show ();
        menu.append (task_descr_item);

        start_timer_item = new Gtk.MenuItem.with_label("Start timer");
        start_timer_item.sensitive = false;
        start_timer_item.show ();
        start_timer_item.activate.connect (toggle_timer);
        menu.append (start_timer_item);

        indicator.set_menu(menu);
        indicator.set_secondary_activate_target(show_item);
        connect_timer_signals ();
    }

    private void toggle_timer () {
        var timer = iface.get_timer ();
        timer.toggle_running ();
    }

    private void show_application_window () {
        var win = iface.get_window ();
        win.show ();
        win.present ();
    }

    private void update_timer_label (uint timer_value) {
        if (!timer_running) {
            return;
        }
        uint hours, minutes, seconds;
        GOFI.Utils.uint_to_time (timer_value, out hours, out minutes, out seconds);
        if (hours > 0 || minutes > 0) {
            if (seconds >= 30) {
                minutes += 1;
            }
            if (minutes == 60) {
                minutes = 59;
                hours += 1;
            }
            if (hours > 0) {
                if (hours != shown_hours || minutes != shown_minutes) {
                    indicator.label = "%uh-%um".printf(hours, minutes);
                }
            } else if (minutes > 0) {
                if (minutes != shown_minutes) {
                    indicator.label = "%um".printf(minutes);
                }
            }
            seconds = 0;
        }
         else if (shown_seconds != seconds) {
            indicator.label = "%us".printf(seconds);
        }
        shown_minutes = minutes;
        shown_seconds = seconds;
        shown_hours = hours;
    }

    private void on_active_task_updated (TodoTask? task) {
        if (task == null) {
            task_descr_item.label = "No task selected";
            active_task_description = null;
            start_timer_item.sensitive = false;
        } else {
            active_task_description = task.description;
            task_descr_item.label = active_task_description;
            start_timer_item.sensitive = true;
        }
    }

    private void on_timer_started () {
        timer_running = true;
        start_timer_item.label = "Stop timer";
    }

    private void on_timer_stopped () {
        timer_running = false;
        indicator.label = "";
        start_timer_item.label = "Start timer";
    }

    private void connect_timer_signals () {
        var timer = iface.get_timer ();
        timer_running = timer.running;
        on_active_task_updated (timer.active_task);
        timer.timer_updated.connect (update_timer_label);
        timer.timer_started.connect (on_timer_started);
        timer.timer_stopped.connect (on_timer_stopped);
        timer.active_task_changed.connect (on_active_task_updated);
        timer.active_task_description_changed.connect (on_active_task_updated);
    }

    private void disconnect_timer_signals () {
        var timer = iface.get_timer ();
        timer.timer_updated.disconnect (update_timer_label);
        timer.timer_started.disconnect (on_timer_started);
        timer.timer_stopped.disconnect (on_timer_stopped);
        timer.active_task_changed.disconnect (on_active_task_updated);
        timer.active_task_description_changed.disconnect (on_active_task_updated);
    }

    public void deactivate () {
        disconnect_timer_signals ();
        indicator = null;
        task_descr_item = null;
        show_item = null;
        start_timer_item = null;
    }

    public void update_state () {}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                       typeof (GOFI.Plugins.PanelIndicator));
}
