/* Copyright 2014-2020 Go For It! developers
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

using GOFI.DialogUtils;

enum NotificationSoundPreset {
    INVALID,
    ALUMINIUM_BOWL,
    SINGING_BOWL,
    BELL,
    LOUD_BELL;

    public const string ALUMINIUM_BOWL_BASENAME = "aluminium-bowl.ogg";
    public const string SINGING_BOWL_BASENAME = "singing-bowl.ogg";
    public const string BELL_BASENAME = "bell.ogg";
    public const string LOUD_BELL_BASENAME = "loud-bell.ogg";

    public string get_name () {
        switch (this) {
            case ALUMINIUM_BOWL:
                return _("Aluminium bowl");
            case SINGING_BOWL:
                return _("Singing bowl");
            case BELL:
                return _("Bell");
            case LOUD_BELL:
                return _("Loud bell");
            default:
                assert_not_reached ();
        }
    }

    public string get_file_str () {
        switch (this) {
            case ALUMINIUM_BOWL:
                return ALUMINIUM_BOWL_BASENAME;
            case SINGING_BOWL:
                return SINGING_BOWL_BASENAME;
            case BELL:
                return BELL_BASENAME;
            case LOUD_BELL:
                return LOUD_BELL_BASENAME;
            default:
                assert_not_reached ();
        }
    }

    public static NotificationSoundPreset from_preset_basename (string str) {
        switch (str) {
            case ALUMINIUM_BOWL_BASENAME:
                return ALUMINIUM_BOWL;
            case SINGING_BOWL_BASENAME:
                return SINGING_BOWL;
            case BELL_BASENAME:
                return BELL;
            case LOUD_BELL_BASENAME:
                return LOUD_BELL;
            default:
                return INVALID;
        }
    }

    public static NotificationSoundPreset[] presets () {
        return {SINGING_BOWL, ALUMINIUM_BOWL, BELL, LOUD_BELL};
    }
}

class GOFI.NotificationsPage : Gtk.Grid {

    Gtk.Label reminder_lbl1;
    Gtk.Label reminder_lbl2;
    Gtk.SpinButton reminder_spin;

    Gtk.Label break_start_sound_lbl;
    Gtk.ComboBoxText break_start_sound_cbox;
    Gtk.VolumeButton break_start_sound_volume_button;

    Gtk.Label break_end_sound_lbl;
    Gtk.ComboBoxText break_end_sound_cbox;
    Gtk.VolumeButton break_end_sound_volume_button;

    Gtk.Label reminder_sound_lbl;
    Gtk.ComboBoxText reminder_sound_cbox;
    Gtk.VolumeButton reminder_sound_volume_button;

    const string CUSTOM_ID = "custom\x07";
    const string SILENT_ID = "";

    public NotificationsPage () {
        int row = 0;
        setup_notification_settings_widgets (ref row);

        apply_grid_spacing (this);
    }

    private void setup_notification_settings_widgets (ref int row) {
        /* Instantiation */
        reminder_lbl1 = new Gtk.Label (_("Reminder before task ends") + ":");
        reminder_lbl2 = new Gtk.Label (_("seconds"));

        // More than ten minutes would not make much sense
        reminder_spin = new Gtk.SpinButton.with_range (0, 600, 1);

        reminder_sound_lbl = new Gtk.Label (_("Reminder sound") + ":");
        break_start_sound_lbl = new Gtk.Label (_("Start of break sound") + ":");
        break_end_sound_lbl = new Gtk.Label (_("End of break sound") + ":");

        reminder_sound_cbox = new Gtk.ComboBoxText ();
        break_start_sound_cbox = new Gtk.ComboBoxText ();
        break_end_sound_cbox = new Gtk.ComboBoxText ();

        reminder_sound_volume_button = new Gtk.VolumeButton ();
        break_start_sound_volume_button = new Gtk.VolumeButton ();
        break_end_sound_volume_button = new Gtk.VolumeButton ();

        /* Configuration */
        reminder_spin.value = settings.reminder_time;

        reminder_sound_volume_button.value =
            notification_service.reminder_player.model.volume;
        break_start_sound_volume_button.value =
            notification_service.break_start_player.model.volume;
        break_end_sound_volume_button.value =
            notification_service.break_end_player.model.volume;

        foreach (var preset in NotificationSoundPreset.presets ()) {
            reminder_sound_cbox.append (preset.get_file_str (), preset.get_name ());
            break_start_sound_cbox.append (preset.get_file_str (), preset.get_name ());
            break_end_sound_cbox.append (preset.get_file_str (), preset.get_name ());
        }
        add_misc_presets (reminder_sound_cbox);
        add_misc_presets (break_start_sound_cbox);
        add_misc_presets (break_end_sound_cbox);

        set_sound_cbox_active_id (
            reminder_sound_cbox, notification_service.reminder_player
        );
        set_sound_cbox_active_id (
            break_start_sound_cbox, notification_service.break_start_player
        );
        set_sound_cbox_active_id (
            break_end_sound_cbox, notification_service.break_end_player
        );

        /* Signal Handling */
        reminder_spin.value_changed.connect (() =>
            settings.reminder_time = reminder_spin.get_value_as_int ()
        );
        reminder_sound_volume_button.value_changed.connect (() => {
            notification_service.reminder_player.model.volume =
                reminder_sound_volume_button.value;
        });
        break_start_sound_volume_button.value_changed.connect (() => {
            notification_service.break_start_player.model.volume =
                break_start_sound_volume_button.value;
        });
        break_end_sound_volume_button.value_changed.connect (() => {
            notification_service.break_end_player.model.volume =
                break_end_sound_volume_button.value;
        });
        reminder_sound_cbox.changed.connect (() =>
            update_sound_file_from_cbox (
                reminder_sound_cbox, notification_service.reminder_player
            )
        );
        break_start_sound_cbox.changed.connect (() =>
            update_sound_file_from_cbox (
                break_start_sound_cbox, notification_service.break_start_player
            )
        );
        break_end_sound_cbox.changed.connect (() =>
            update_sound_file_from_cbox (
                break_end_sound_cbox, notification_service.break_end_player
            )
        );

        /* Add widgets */
        add_option (this, reminder_lbl1, reminder_spin, ref row, 1, reminder_lbl2);
        add_section (this, new Gtk.Label (_("Notification sounds")), ref row);
        add_option (this, reminder_sound_lbl, reminder_sound_cbox, ref row, 1, reminder_sound_volume_button);
        add_option (this, break_start_sound_lbl, break_start_sound_cbox, ref row, 1, break_start_sound_volume_button);
        add_option (this, break_end_sound_lbl, break_end_sound_cbox, ref row, 1, break_end_sound_volume_button);
    }

    private void add_misc_presets (Gtk.ComboBoxText cbox) {
        cbox.append (CUSTOM_ID, _("Custom"));
        cbox.append (SILENT_ID, _("Silent"));
    }

    private void set_sound_cbox_active_id (Gtk.ComboBoxText cbox, SoundPlayer player) {
        var file_str = player.model.file_str;
        var preset = NotificationSoundPreset.from_preset_basename (file_str);
        if (preset == NotificationSoundPreset.INVALID) {
            var basename = File.new_for_uri (file_str).get_basename ();
            if (basename != null && basename != "") {
                cbox.prepend (file_str, basename);
            } else {
                file_str = "";
            }
        }
        cbox.active_id = file_str;
    }

    private void update_sound_file_from_cbox (Gtk.ComboBoxText cbox, SoundPlayer player) {
        var active_id = cbox.active_id;
        switch (active_id) {
            case CUSTOM_ID:
                var file = get_custom_sound_file ();
                if (file == null) {
                    cbox.active_id = player.model.file_str;
                } else {
                    var uri = file.get_uri ();
                    cbox.prepend (uri, file.get_basename ());
                    cbox.active_id = uri;
                }

                return;
            case SILENT_ID:
                player.model.file_str = "";
                break;
            default:
                player.model.file_str = active_id;
                break;
        }
        player.play ();
    }

    private GLib.File? get_custom_sound_file () {
        var window = this.get_toplevel () as Gtk.Window;
        var dialog_title = _("Select notification sound file");
#if HAS_GTK322
        var file_chooser = new Gtk.FileChooserNative (
            dialog_title, window, Gtk.FileChooserAction.OPEN,
            _("_Select"), null
        );
#else
        var file_chooser = new Gtk.FileChooserDialog (
            dialog_title, window, Gtk.FileChooserAction.OPEN,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("_Select"), Gtk.ResponseType.ACCEPT
        );
#endif
        file_chooser.select_multiple = false;
        file_chooser.local_only = true;

        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("audio/x-vorbis+ogg");
        filter.add_mime_type ("audio/x-wav");

        file_chooser.filter = filter;
        int response_id = file_chooser.run ();
        if (response_id == Gtk.ResponseType.OK ||
            response_id == Gtk.ResponseType.ACCEPT
        ) {
            return file_chooser.get_file ();
        }
        file_chooser.destroy ();
        return null;
    }
}
