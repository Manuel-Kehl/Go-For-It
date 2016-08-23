/* Copyright 2016 Go For It! developers
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
class GOFI.PluginManager {
    private SettingsManager settings;
    private TaskTimer timer;
    
    private Peas.Engine engine;
    private Peas.ExtensionSet exts;
    
    public Interface plugin_iface { private set; public get; }
    
    /**
     * Constructor of PluginManager
     */
    public PluginManager (SettingsManager settings, TaskTimer timer) {
        this.settings = settings;
        this.timer = timer;

        plugin_iface = new Interface (this);

        engine = Peas.Engine.get_default ();
        foreach (string dir in Utils.plugin_dirs) {
            engine.add_search_path (dir, null);
            message ("Adding search path: %s", dir);
        }
        engine.set_loaded_plugins (settings.enabled_plugins);
        
        Parameter param = Parameter ();
        param.value = plugin_iface;
        param.name = "object";
        exts = new Peas.ExtensionSet (engine, typeof (Peas.Activatable), 
            "object", plugin_iface, null);
        connect_signals ();
    }
    
    /**
     * Activates the found plugins.
     */
    public void load_plugins () {
        message ("Loading plugins");
        exts.foreach (on_extension_foreach);
        exts.extension_added.connect (on_extension_added);
        exts.extension_removed.connect (on_extension_removed);
    }
    
    /**
     * Passes signals from the timer on to the plugin interface.
     */
    private void connect_signals () {
        timer.timer_updated.connect ( (remaining_duration) => {
            plugin_iface.timer_updated (remaining_duration);
        });
        timer.timer_updated_relative.connect ( (progress) => {
            plugin_iface.timer_updated_relative (progress);
        });
        timer.timer_running_changed.connect ( (running) => {
            plugin_iface.timer_running_changed (running);
        });
        timer.timer_almost_over.connect ( (remaining_duration) => {
            plugin_iface.timer_almost_over (remaining_duration);
        });
        timer.timer_finished.connect ( (break_active) => {
            plugin_iface.timer_finished (break_active);
        });
    }
    
    /**
     * Returns a widget for enabling/disabling plugins.
     */
    public Gtk.Widget get_settings_widget () {
        return new PeasGtk.PluginManager (engine);
    }
    
    /**
     * Cant call this from on_extension_removed, as loaded_plugins is 
     * updated after giving off the extension_removed signal.
     */
    public void save_loaded () {
        settings.enabled_plugins = engine.get_loaded_plugins ();
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

