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

class GOFI.Notifications {
    private const string TIMER_NOTIFY_ID = "timer-notification";
    private SoundPlayer break_timer_elapsed_player;
    private SoundPlayer task_timer_elapsed_player;
    private unowned Application app;

    /**
     * Used to determine if a notification should be sent.
     */
    private bool break_previously_active { get; set; default = false; }

    public Notifications (Application app) {
        this.app = app;
        setup_notifications ();

        try {
            break_timer_elapsed_player = new CanberraPlayer (null);
        } catch (SoundPlayerError e) {
            warning (e.message);
            break_timer_elapsed_player = new DummyPlayer ();
        }
        try {
            task_timer_elapsed_player = new CanberraPlayer (null);
        } catch (SoundPlayerError e) {
            warning (e.message);
            task_timer_elapsed_player = new DummyPlayer ();
        }
        task_timer_elapsed_player.file = File.new_for_uri (get_absolute_uri ("singing-bowl.ogg"));
        break_timer_elapsed_player.file = File.new_for_uri (get_absolute_uri ("steel-bell.ogg"));
    }

    ~Notifications () {
        app.withdraw_notification (TIMER_NOTIFY_ID);
    }

    /**
     * Configures the emission of notifications when tasks/breaks are over
     */
    private void setup_notifications () {
        task_timer.active_task_changed.connect (task_timer_activated);
        task_timer.timer_almost_over.connect (display_almost_over_notification);
        task_timer.task_duration_exceeded.connect (display_duration_exceeded);
    }

    private void task_timer_activated (TodoTask? task) {
        if (task == null) {
            return;
        }
        var break_active = task_timer.break_active;
        if (break_previously_active != break_active) {
            GLib.Notification notification;
            if (break_active) {
                notification = new GLib.Notification (_("Take a Break"));
                notification.set_body (
                    _("Relax and stop thinking about your current task for a while")
                    + " :-)"
                );
            } else {
                notification = new GLib.Notification (_("The Break is Over"));
                notification.set_body (
                    _("Your current task is") + ": " + task.description
                );
            }
            notification.set_priority (NotificationPriority.HIGH);
            notification.set_icon (new ThemedIcon(GOFI.ICON_NAME));
            app.send_notification (TIMER_NOTIFY_ID, notification);
            if (break_active) {
                task_timer_elapsed_player.play ();
            } else {
                break_timer_elapsed_player.play ();
            }
        }
        break_previously_active = break_active;
    }

    private void display_almost_over_notification (uint remaining_time) {
        var notification = new GLib.Notification (_("Prepare for your break"));
        notification.set_body (
            _("You have %s seconds left").printf (remaining_time.to_string ())
        );
        notification.set_icon (new ThemedIcon(GOFI.ICON_NAME));
        app.send_notification (TIMER_NOTIFY_ID, notification);
    }

    private void display_duration_exceeded () {
        var notification = new GLib.Notification ( _("Task duration exceeded"));
        notification.set_body (_("Consider switching to a different task"));
        notification.set_icon (new ThemedIcon(GOFI.ICON_NAME));
        app.send_notification (TIMER_NOTIFY_ID, notification);
    }
}
