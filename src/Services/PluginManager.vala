/* Copyright 2016-2020 GoForIt! developers
*
* This file is part of GoForIt!.
*
* GoForIt! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* GoForIt! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with GoForIt!. If not, see http://www.gnu.org/licenses/.
*/

#if !NO_PLUGINS
/**
 * PluginManager loads and controls all plugins.
 */
class GOFI.PluginManager : GLib.Object {

    private Peas.Engine engine;
    private Peas.ExtensionSet exts;
    public PluginInterface plugin_iface;

    private GLib.Settings plugin_settings;
    const string ID_PLUGINS = GOFI.APP_ID + ".plugins";
    const string KEY_PLUGINS = "enabled-plugins";

    internal bool show_on_timer_elapsed {
        get {
            return plugin_iface.show_on_timer_elapsed;
        }
    }

    /**
     * Constructor of PluginManager
     */
    public PluginManager (TaskTimer timer) {
        plugin_iface = new PluginInterface (this, timer);

        plugin_settings = new GLib.Settings (ID_PLUGINS);

        engine = Peas.Engine.get_default ();
        engine.add_search_path (GOFI.PLUGINDIR, null);

        var sbf = GLib.SettingsBindFlags.DEFAULT;
        plugin_settings.bind (KEY_PLUGINS, engine, "loaded_plugins", sbf);

        exts = new Peas.ExtensionSet (engine, typeof (Peas.Activatable),
            "object", plugin_iface, null);
    }

    /**
     * Activates the found plugins.
     */
    public void load_plugins () {
        exts.foreach (on_extension_foreach);
        exts.extension_added.connect (on_extension_added);
        exts.extension_removed.connect (on_extension_removed);
    }

    public Gtk.Widget get_settings_widget () {
        return new PeasGtk.PluginManager (engine);
    }

    private void on_extension_foreach (
        Peas.ExtensionSet set, Peas.PluginInfo info, Peas.Extension extension
    ) {
        ((Peas.Activatable)extension).activate ();
    }

    private void on_extension_added (Peas.PluginInfo info, Object extension) {
        ((Peas.Activatable)extension).activate ();
    }

    private void on_extension_removed (Peas.PluginInfo info, Object extension) {
        ((Peas.Activatable) extension).deactivate ();
    }
}
#endif
