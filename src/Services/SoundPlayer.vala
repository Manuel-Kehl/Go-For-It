/*
 * Copyright (c) 2016 gnome-pomodoro contributors, 2020 Go For It! developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace GOFI
{
    public errordomain SoundPlayerError {
        FAILED_TO_INITIALIZE
    }

    /**
     * Preset sounds are defined relative to data directory,
     * and used URIs are not particulary valid.
     */
    private string get_absolute_uri (string uri) {
        var scheme = GLib.Uri.parse_scheme (uri);

        if (scheme == null && uri != "") {
            var path = GLib.Path.build_filename (GOFI.DATADIR, "sounds", uri);

            try {
                return GLib.Filename.to_uri (path);
            } catch (GLib.ConvertError error) {
                warning ("Failed to convert \"%s\" to uri: %s", path, error.message);
            }
        }

        return uri;
    }

    public interface SoundPlayer : GLib.Object {
        public abstract GLib.File? file { get; set; }

        public abstract double volume { get; set; }

        public abstract void play ();

        public abstract void stop ();

        public virtual string[] get_supported_mime_types () {
            string[] mime_types = {
                "audio/*"
            };

            return mime_types;
        }
    }

    private class CanberraPlayer : GLib.Object, SoundPlayer {
        public GLib.File? file {
            get {
                return this._file;
            }
            set {
                this._file = value != null
                        ? GLib.File.new_for_uri (get_absolute_uri (value.get_uri ()))
                        : null;

                if (this.is_cached) {
                    /* there is no way to invalidate old value, so at least refresh cache */
                    this.cache_file ();
                }
            }
        }

        public string event_id { get; private construct set; }
        public double volume { get; set; default = 1.0; }

        private GLib.File _file;
        private Canberra.Context context;
        private bool is_cached = false;

        public CanberraPlayer (string? event_id) throws SoundPlayerError {
            Canberra.Context context;

            /* Create context */
            var status = Canberra.Context.create (out context);
            var application = GLib.Application.get_default ();

            if (status != Canberra.SUCCESS) {
                throw new SoundPlayerError.FAILED_TO_INITIALIZE (
                        "Failed to initialize canberra context - %s".printf (Canberra.strerror (status)));
            }

            /* Set properties about application */
            status = context.change_props (
                    Canberra.PROP_APPLICATION_ID, application.application_id,
                    Canberra.PROP_APPLICATION_NAME, GOFI.APP_NAME,
                    Canberra.PROP_APPLICATION_ICON_NAME, GOFI.ICON_NAME);

            if (status != Canberra.SUCCESS) {
                throw new SoundPlayerError.FAILED_TO_INITIALIZE (
                        "Failed to set context properties - %s".printf (Canberra.strerror (status)));
            }

            /* Connect to the sound system */
            status = context.open ();

            if (status != Canberra.SUCCESS) {
                throw new SoundPlayerError.FAILED_TO_INITIALIZE (
                        "Failed to open canberra context - %s".printf (Canberra.strerror (status)));
            }

            this.context = (owned) context;
            this.event_id = event_id;
        }

        ~CanberraPlayer ()
        {
            if (this.context != null) {
                this.stop ();
            }
        }

        private static double amplitude_to_decibels (double amplitude)
        {
            return 20.0 * Math.log10 (amplitude);
        }

        public void play () requires (this.context != null) {
            if (this._file != null)
            {
                if (this.context != null)
                {
                    Canberra.Proplist properties = null;

                    var status = Canberra.Proplist.create (out properties);
                    properties.sets (Canberra.PROP_MEDIA_ROLE, "alert");
                    properties.sets (Canberra.PROP_MEDIA_FILENAME, this._file.get_path ());
                    properties.sets (Canberra.PROP_CANBERRA_VOLUME,
                                     ((float) amplitude_to_decibels (this.volume)).to_string ());

                    if (this.event_id != null) {
                        properties.sets (Canberra.PROP_EVENT_ID, this.event_id);

                        if (!this.is_cached) {
                            this.cache_file ();
                        }
                    }

                    status = this.context.play_full (
                        0, properties, this.on_play_callback
                    );

                    if (status != Canberra.SUCCESS) {
                        warning ("Couldn't play sound '%s' - %s",
                            this._file.get_uri (),
                            Canberra.strerror (status)
                        );
                    }
                }
                else {
                    warning ("Couldn't play sound '%s'",
                        this._file.get_uri ()
                    );
                }
            }
        }

        public void stop () requires (this.context != null) {
            /* we dont need it for event sounds */
        }

        public string[] get_supported_mime_types () {
            string[] mime_types = {
                "audio/x-vorbis+ogg",
                "audio/x-wav"
            };

            return mime_types;
        }

        private void cache_file () {
            Canberra.Proplist properties = null;

            if (this.context != null &&
                this.event_id != null &&
                this._file != null
            ) {
                var status = Canberra.Proplist.create (out properties);
                properties.sets (Canberra.PROP_EVENT_ID, this.event_id);
                properties.sets (Canberra.PROP_MEDIA_FILENAME, this._file.get_path ());

                status = this.context.cache_full (properties);

                if (status != Canberra.SUCCESS) {
                    warning ("Couldn't clear libcanberra cache - %s",
                        Canberra.strerror (status)
                    );
                }
                else {
                    this.is_cached = true;
                }
            }
        }

        private void on_play_callback (Canberra.Context context,
                                       uint32           id,
                                       int              code)
        {
        }
    }

    private class DummyPlayer : GLib.Object, SoundPlayer {
        public GLib.File? file {
            get {
                return this._file;
            }
            set {
                this._file = value != null
                        ? GLib.File.new_for_uri (get_absolute_uri (value.get_uri ()))
                        : null;
            }
        }

        public double volume { get; set; default = 1.0; }

        private GLib.File _file;

        public void play () {
        }

        public void stop () {
        }
    }
}
