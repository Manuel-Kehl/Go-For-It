class TaskRow: DragListBoxRow {
    unowned Gtk.Box content_layout;
    private Gtk.CheckButton check_button;
    private TaskLabel title_label;

    public TodoTask task {
        get;
        construct set;
    }
    
    public signal void link_clicked (string uri);
    
    public TaskRow (TodoTask task) {
        this.task = task;
        content_layout = get_content ();
        
        check_button = new Gtk.CheckButton ();
        check_button.active = task.done;
        
        title_label = new TaskLabel (task.title, task.done);
        title_label.hexpand = true;
        
        content_layout.add (check_button);
        content_layout.add (title_label);
        
        connect_signals ();
        show_all ();
    }
    
    public void edit () {
        title_label.edit ();
    }
    
    private void connect_signals () {
        check_button.toggled.connect (() => {
            task.done = !task.done;
        });
        task.status_changed.connect (() => {
            destroy ();
        });
        task.notify["title"].connect (update);
        title_label.activate_link.connect ((uri) => {
            link_clicked (uri);
            return true;
        });
        title_label.string_changed.connect (() => {
            task.title = title_label.txt_string;
        });
        title_label.single_click.connect (() => {
            Gtk.ListBox? parent = this.get_parent () as Gtk.ListBox;
            if (parent != null) {
                parent.select_row (this);
            }
            grab_focus ();
        });
    }
    
    private void update () {
        title_label.txt_string = task.title;
    }
    
    /**
     * An editable label that supports wrapping and markup
     */
    class TaskLabel : Gtk.Stack {
        private Gtk.Label label;
        private Gtk.Entry entry;
        
        private bool task_done;
        private bool double_click;
        private bool entry_visible;
        
        private string markup_string;
        
        private string _txt_string;
        public string txt_string {
            public get {
                return _txt_string;
            }
            public set {
                _txt_string = value;
                update ();
            }
        }
        
        public signal bool activate_link (string uri);
        public signal void string_changed ();
        public signal void single_click ();
        
        public TaskLabel (string txt_string, bool task_done) {
            _txt_string = txt_string;
            this.task_done = task_done;
            double_click = false;
            entry_visible = false;
            setup_widgets ();
        }
        
        public void setup_widgets () {
            label = new Gtk.Label(null);
            
            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            label.width_request = 200;
            // Workaround for: "undefined symbol: gtk_label_set_xalign"
            ((Gtk.Misc) label).xalign = 0f;
            
            update ();
            
            label.activate_link.connect ( (uri) => {
                return activate_link (uri);
            });
            
            // Workaround for Gtk.ListBox stealing focus after activating a row
            // by double clicking it, which would cause editing to be aborted.
            button_press_event.connect ((event_button) => {
                if (event_button.type == Gdk.EventType.2BUTTON_PRESS) {
                    double_click = true;
                }
                return true;
            });
            button_release_event.connect ((event_button) => {
                if (entry_visible) {
                    return true;
                }
                if (double_click) {
                    double_click = false;
                    edit ();
                } else {
                    single_click ();
                }
                return true;
            });
            
            add (label);
        }
        
        public void edit () {
            if (entry != null) {
                return;
            }
            entry = new Gtk.Entry ();
            entry.can_focus = true;
            entry.text = _txt_string;
            
            add (entry);
            entry.show ();
            set_visible_child (entry);
            entry.grab_focus ();
            entry.activate.connect(stop_editing);
            entry.focus_out_event.connect (on_entry_focus_out);
            entry_visible = true;
        }
        
        private bool on_entry_focus_out () {
            abort_editing ();
            return false;
        }
        
        private void abort_editing () {
            if (entry != null) {
                var _entry = entry;
                entry = null;
                set_visible_child (label);
                remove (_entry);
            }
            entry_visible = false;
        }
        
        private void stop_editing () {
            txt_string = entry.text;
            string_changed ();
            abort_editing ();
        }
        
        private void update () {
            gen_markup ();
            label.set_markup (markup_string);
        }
        
        private void gen_markup () {
            markup_string = make_links (
                GLib.Markup.escape_text (_txt_string), 
                {"+", "@"}, 
                {"project:", "context:"}
            );
            if (task_done) {
                markup_string = "<s>" + markup_string + "</s>";
            }
        }
        
        /**
         * Used to find projects and contexts and replace those parts with a 
         * link.
         * @param title the string to took for contexts or projects
         * @param delimiters prefixes of the context or project (+/@)
         * @param prefixes prefixes of the new links
         */
        private string make_links (string title, string[] delimiters, 
                                   string[] prefixes)
        {
            string parsed = "";
            string delimiter, prefix;
            
            int n_delimiters = delimiters.length;
            
            foreach (string part in title.split (" ")) {
                string? val = null;
                
                for (int i = 0; val == null && i < n_delimiters; i++) {
                    val = part.split (delimiters[i], 2)[1];
                    if (val != null && val != "") {
                        delimiter = delimiters[i];
                        prefix = prefixes[i];
                        parsed += @" <a href=\"$prefix$val\" title=\"$val\">" +
                                  @"$delimiter$val</a>";
                    }
                }
                
                if (val == null || val == "") {
                    parsed += " " + part;
                }
            }
            
            return parsed.chug ();
        }
    }
}
