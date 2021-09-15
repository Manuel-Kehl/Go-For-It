using GOFI;

/**
 * The entry point for running the application.
 */
public static int main (string[] args) {
    Intl.setlocale (LocaleCategory.MESSAGES, "");
    Intl.textdomain (GOFI.GETTEXT_PACKAGE);
    Intl.bind_textdomain_codeset (GOFI.GETTEXT_PACKAGE, "utf-8");
    string locale_dir = Path.build_filename (GOFI.INSTALL_PREFIX, "share", "locale");
    Intl.bindtextdomain (GOFI.GETTEXT_PACKAGE, locale_dir);

    apply_desktop_specific_tweaks ();
    Main app = new Main ();
    int status = app.run (args);
    return status;
}

/**
 * This function handles different tweaks that have to be applied to
 * make GoForIt! work properly on certain desktop environments.
 */
public static void apply_desktop_specific_tweaks () {
    string desktop = Environment.get_variable ("DESKTOP_SESSION");

    if (desktop == "ubuntu") {
        // Disable overlay scrollbars on unity, to avoid a strange Gtk bug
        Environment.set_variable ("LIBOVERLAY_SCROLLBAR", "0", true);
    }
}
