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

class GOFI.Notifications : GLib.Object {
    private const string TIMER_NOTIFY_ID = "timer-notification";
    private unowned Application app;

    private const string KEY_REMINDER_SOUND_FILE = "reminder-sound-file";
    private const string KEY_BREAK_START_SOUND_FILE = "break-start-sound-file";
    private const string KEY_BREAK_END_SOUND_FILE = "break-end-sound-file";
    private const string KEY_REMINDER_SOUND_VOLUME = "reminder-sound-volume";
    private const string KEY_BREAK_START_SOUND_VOLUME = "break-start-sound-volume";
    private const string KEY_BREAK_END_SOUND_VOLUME = "break-end-sound-volume";
    public const string KEY_MUTE_SOUND = "mute";
    private GLib.Settings sound_settings;

    public SoundPlayer break_start_player { get; private set; }
    public SoundPlayer break_end_player { get; private set; }
    public SoundPlayer reminder_player { get; private set; }
    public bool mute_sounds { get; set; default = false; }

    /**
     * Used to determine if a notification should be sent.
     */
    private bool break_previously_active { get; set; default = false; }

    public Notifications (Application app) {
        this.app = app;
        setup_notifications ();

        try {
            break_end_player = new CanberraPlayer ("gofi-break-end");
        } catch (SoundPlayerError e) {
            warning (e.message);
            break_end_player = new DummyPlayer ();
        }
        try {
            break_start_player = new CanberraPlayer ("gofi-break-start");
        } catch (SoundPlayerError e) {
            warning (e.message);
            break_start_player = new DummyPlayer ();
        }
        try {
            reminder_player = new CanberraPlayer ("gofi-reminder");
        } catch (SoundPlayerError e) {
            warning (e.message);
            reminder_player = new DummyPlayer ();
        }

        sound_settings = new GLib.Settings (GOFI.APP_ID + ".settings.sounds");
        var sbf = GLib.SettingsBindFlags.DEFAULT;
        sound_settings.bind (KEY_BREAK_START_SOUND_FILE, break_start_player.model, "file_str", sbf);
        sound_settings.bind (KEY_BREAK_END_SOUND_FILE, break_end_player.model, "file_str", sbf);
        sound_settings.bind (KEY_REMINDER_SOUND_FILE, reminder_player.model, "file_str", sbf);
        sound_settings.bind (KEY_BREAK_START_SOUND_VOLUME, break_start_player.model, "volume", sbf);
        sound_settings.bind (KEY_BREAK_END_SOUND_VOLUME, break_end_player.model, "volume", sbf);
        sound_settings.bind (KEY_REMINDER_SOUND_VOLUME, reminder_player.model, "volume", sbf);
        sound_settings.bind (KEY_MUTE_SOUND, this, "mute_sounds", sbf);
    }

    ~Notifications () {
        app.withdraw_notification (TIMER_NOTIFY_ID);
    }

    public Action[] create_actions () {
        return {sound_settings.create_action (KEY_MUTE_SOUND)};
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
            notification.set_icon (new ThemedIcon (GOFI.ICON_NAME));
            app.send_notification (TIMER_NOTIFY_ID, notification);
            if (!mute_sounds) {
                if (break_active) {
                    break_start_player.play ();
                } else {
                    break_end_player.play ();
                }
            }
        }
        break_previously_active = break_active;
    }

    private void play_misc_notification_sound () {
        if (!mute_sounds) {
            reminder_player.play ();
        }
    }

    private void display_almost_over_notification (uint remaining_time) {
        var notification = new GLib.Notification (_("Prepare for your break"));
        notification.set_body (
            _("You have %s seconds left").printf (remaining_time.to_string ())
        );
        notification.set_icon (new ThemedIcon (GOFI.ICON_NAME));
        app.send_notification (TIMER_NOTIFY_ID, notification);
        play_misc_notification_sound ();
    }

    private void display_duration_exceeded () {
        var notification = new GLib.Notification ( _("Task duration exceeded"));
        notification.set_body (_("Consider switching to a different task"));
        notification.set_icon (new ThemedIcon (GOFI.ICON_NAME));
        app.send_notification (TIMER_NOTIFY_ID, notification);
        play_misc_notification_sound ();
    }
}
