/*
 *  Copyright 2019 elementary, Inc. (https://elementary.io)
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

/**
 * LauncherEntry implementation from the Granite library.
 * This file is used if Granite isn't used to compile GoForIt!.
 * It doesn't pull in additional dependencies and doesn't depend on the rest of
 * Granite.
 */
namespace Builtin.Granite.Services {
    /**
     * Utilities for Applications
     */
    namespace Application {
        [DBus (name = "com.canonical.Unity.LauncherEntry")]
        private class UnityLauncherEntry : GLib.Object {
            private static AsyncMutex? instance_mutex = null;
            private static UnityLauncherEntry instance;
            internal static async unowned UnityLauncherEntry get_instance () throws GLib.Error {
                if (instance_mutex == null) {
                    instance_mutex = new AsyncMutex ();
                }

                yield instance_mutex.lock ();

                if (instance != null) {
                    instance_mutex.unlock ();
                    return instance;
                }

                weak GLib.Application app = GLib.Application.get_default ();
                if (app == null) {
                    instance_mutex.unlock ();
                    throw new GLib.IOError.FAILED ("No GApplication has been defined");
                }

                if (app.application_id == null) {
                    instance_mutex.unlock ();
                    throw new GLib.IOError.FAILED ("The GApplication has no application-id defined");
                }

                var local_instance = new UnityLauncherEntry ();
                local_instance.app_uri = "application://%s.desktop".printf (app.application_id);
                var object_path = new GLib.ObjectPath (
                    "/com/canonical/unity/launcherentry/%u".printf (local_instance.app_uri.hash ())
                );
                try {
                    var session_connection = yield GLib.Bus.@get (GLib.BusType.SESSION, null);
                    session_connection.register_object (object_path, local_instance);
                    instance = local_instance;
                } catch (GLib.Error e) {
                    instance_mutex.unlock ();
                    throw e;
                }

                instance_mutex.unlock ();
                return instance;
            }

            construct {
                properties = new GLib.HashTable<string,GLib.Variant> (str_hash, str_equal);
                properties["urgent"] = new GLib.Variant.boolean (false);
                properties["count"] = new GLib.Variant.int64 (0);
                properties["count-visible"] = new GLib.Variant.boolean (false);
                properties["progress"] = new GLib.Variant.double (0.0);
                properties["progress-visible"] = new GLib.Variant.boolean (false);
            }

            private string app_uri;
            private GLib.HashTable<string,GLib.Variant> properties;

            internal void set_app_property (string property, GLib.Variant var) {
                var updated_properties = new GLib.HashTable<string,GLib.Variant> (str_hash, str_equal);
                updated_properties[property] = var;
                properties[property] = var;
                update (app_uri, updated_properties);
            }

            public signal void update (string app_uri, GLib.HashTable<string,GLib.Variant> properties);

            public GLib.HashTable<string,Variant> query () throws GLib.Error {
                return properties;
            }
        }

        /**
         * Set the badge count, usually visible with the dock in the desktop. There is no guarantee
         * that the target environment supports it in any way.
         * For it to be visible, one has to make sure to call set_badge_visible().
         */
        public static async bool set_badge (int64 count) throws GLib.Error {
            unowned UnityLauncherEntry instance = yield UnityLauncherEntry.get_instance ();
            instance.set_app_property ("count", new GLib.Variant.int64 (count));
            return true;
        }

        /**
         * Set the badge visibility.
         */
        public static async bool set_badge_visible (bool visible) throws GLib.Error {
            unowned UnityLauncherEntry instance = yield UnityLauncherEntry.get_instance ();
            instance.set_app_property ("count-visible", new GLib.Variant.boolean (visible));
            return true;
        }

        /**
         * Set the progress of the application, usually visible with the dock in the desktop.
         * There is no guarantee that the target environment supports it in any way.
         * For it to be visible, one has to make sure to call set_progress_visible().
         */
        public static async bool set_progress (double progress) throws GLib.Error {
            unowned UnityLauncherEntry instance = yield UnityLauncherEntry.get_instance ();
            instance.set_app_property ("progress", new GLib.Variant.double (progress));
            return true;
        }

        /**
         * Set the progress visibility.
         */
        public static async bool set_progress_visible (bool visible) throws GLib.Error {
            unowned UnityLauncherEntry instance = yield UnityLauncherEntry.get_instance ();
            instance.set_app_property ("progress-visible", new GLib.Variant.boolean (visible));
            return true;
        }
    }

    /**
     * AsyncMutex implementation with Gee.ArrayQueue replaced with GLib.Queue
     */
    internal class AsyncMutex {
        private class Callback {
            public SourceFunc callback;

            public Callback (owned SourceFunc cb) {
                callback = (owned)cb;
            }
        }

        private GLib.Queue<Callback> callbacks;
        private bool locked;

        public AsyncMutex () {
            locked = false;
            callbacks = new GLib.Queue<Callback> ();
        }

        public async void lock () {
            while (locked) {
                SourceFunc cb = lock.callback;
                callbacks.push_head (new Callback ((owned)cb));
                yield;
            }

            locked = true;
        }

        public void unlock () {
            locked = false;
            var callback = callbacks.pop_head ();
            if (callback != null) {
                Idle.add ((owned)callback.callback);
            }
        }
    }
}
