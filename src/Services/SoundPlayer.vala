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

namespace GOFI {
    errordomain SoundPlayerError {
        FAILED_TO_INITIALIZE
    }

    class SoundPlayerModel : GLib.Object {
        public GLib.File? file {
            get {
                return _file;
            }
            set {
                _file = value;

                if (internal_update) {
                    return;
                }
                internal_update = true;
                if (_file != null) {
                    file_str = _file.get_uri ();
                } else {
                    file_str = "";
                }
                internal_update = false;
            }
        }
        private GLib.File? _file;

        public string file_str {
            get {
                return _file_str;
            }
            set {
                _file_str = value;

                string uri = _file_str;

                if (internal_update) {
                    return;
                }
                internal_update = true;

                // Check if string needs to be interpreted as preset
                if (_file_str != "") {
                    var scheme = GLib.Uri.parse_scheme (_file_str);
                    if (scheme == null) {
                        var path = GLib.Path.build_filename (GOFI.DATADIR, "sounds", _file_str);
                        try {
                            uri = GLib.Filename.to_uri (path);
                        } catch (GLib.ConvertError error) {
                            warning ("Failed to convert \"%s\" to uri: %s", path, error.message);
                            uri = _file_str = "";
                        }
                    }
                }

                if (uri == "") {
                    file = null;
                } else {
                    file = File.new_for_uri (uri);
                }
                internal_update = false;
            }
        }
        private string _file_str;

        private bool internal_update;

        public double volume { get; set; default = 1.0; }

        public SoundPlayerModel () {
            _file_str = "";
            _file = null;
            internal_update = false;
        }
    }

    interface SoundPlayer : GLib.Object {
        public abstract SoundPlayerModel model { get; set; }

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
        public SoundPlayerModel model {
            get {
                return this._model;
            }
            set {
                if (this._model != null) {
                    this._model.notify["file"].disconnect (on_file_changed);
                }
                this._model = value;
                this._model.notify["file"].connect (on_file_changed);
                on_file_changed ();
            }
        }
        SoundPlayerModel _model;

        public string? event_id { get; construct set; }

        private Canberra.Context context;
        private bool is_cached = false;

        public CanberraPlayer (string? event_id) throws SoundPlayerError {
            Object (event_id: event_id);
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
            this.model = new SoundPlayerModel ();
        }

        ~CanberraPlayer () {
            if (this.context != null) {
                this.stop ();
            }
        }

        private void on_file_changed () {
            if (this.is_cached) {
                /* there is no way to invalidate old value, so at least refresh cache */
                this.cache_file ();
            }
        }

        private static double amplitude_to_decibels (double amplitude) {
            return 20.0 * Math.log10 (amplitude);
        }

        public void play () requires (this.context != null) {
            var file = this._model.file;
            var volume = this._model.volume;
            if (file != null) {
                if (this.context != null) {
                    Canberra.Proplist properties = null;

                    var status = Canberra.Proplist.create (out properties);
                    properties.sets (Canberra.PROP_MEDIA_ROLE, "alert");
                    properties.sets (Canberra.PROP_MEDIA_FILENAME, file.get_path ());
                    properties.sets (Canberra.PROP_CANBERRA_VOLUME,
                                     ((float) amplitude_to_decibels (volume)).to_string ());

                    if (this.event_id != null) {
                        properties.sets (Canberra.PROP_EVENT_ID, this.event_id);

                        if (!this.is_cached) {
                            this.cache_file ();
                        }
                    }

                    status = this.context.play_full (0, properties, null);

                    if (status != Canberra.SUCCESS) {
                        warning ("Couldn't play sound '%s' - %s",
                            file.get_uri (),
                            Canberra.strerror (status)
                        );
                    }
                }
                else {
                    warning ("Couldn't play sound '%s'",
                        this.model.file.get_uri ()
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
            var file = this._model.file;

            if (this.context != null &&
                this.event_id != null &&
                file != null
            ) {
                var status = Canberra.Proplist.create (out properties);
                properties.sets (Canberra.PROP_EVENT_ID, this.event_id);
                properties.sets (Canberra.PROP_MEDIA_FILENAME, file.get_path ());

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
    }

    private class DummyPlayer : GLib.Object, SoundPlayer {
        public SoundPlayerModel model { get; set; }

        public DummyPlayer () {
            this.model = new SoundPlayerModel ();
        }

        public void play () {}

        public void stop () {}
    }
}
