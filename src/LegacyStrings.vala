// vala-lint=skip-file
string[] unused_strings_1_8 {
    _("Todo.txt files were found in the destination folder.") /// For versions <= 1.8, shown in a dialog when destination folder contains either todo.txt or done.txt
    ,_("What should be done with these files?") /// For versions <= 1.8, shown in a dialog when destination folder contains either todo.txt or done.txt
    ,_("Overwrite"),
    ,_("The configured folder is already in use by another list.")
    ,"<a href=\"http://todotxt.com\">Todo.txt</a> "+ _("folder")
    , _("Inherit from GTK theme")
    ,_("Dark theme")
    ,_("Couldn't properly import settings from %s: %s") /// For versions <= 1.8, argument 1: filename, argument 2: error message
    ,_("The path to the todo.txt folder does not point to a folder, but to a file or mountable location. Please change the path in the settings to a suitable folder or remove this file."); /// For versions <= 1.8
};
