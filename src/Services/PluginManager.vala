/* Copyright 2016-2020 Go For It! developers
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
 * PluginManager loads and controls all plugins.
 */
class GOFI.PluginManager : GLib.Object {

    private Peas.Engine engine;
    private Peas.ExtensionSet exts;
    private PluginInterface plugin_iface;

    private GLib.Settings plugin_settings;
    const string ID_PLUGINS = GOFI.APP_ID + ".plugins";
    const string KEY_PLUGINS = "enabled-plugins";

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
        load_plugins ();
    }

    /**
     * Activates the found plugins.
     */
    private void load_plugins () {
        exts.foreach (on_extension_foreach);
        exts.extension_added.connect (on_extension_added);
        exts.extension_removed.connect (on_extension_removed);
    }

    public Gtk.Widget get_settings_widget () {
        return new PeasGtk.PluginManager (engine);
    }

    private void on_extension_foreach (Peas.ExtensionSet set,
                                       Peas.PluginInfo info,
                                       Peas.Extension extension)
    {
        ((Peas.Activatable)extension).activate ();
    }

    private void on_extension_added (Peas.PluginInfo info,
                                     Object extension)
    {
        ((Peas.Activatable)extension).activate ();
    }

    private void on_extension_removed (Peas.PluginInfo info,
                                       Object extension)
    {
        ((Peas.Activatable) extension).deactivate ();
    }
}

