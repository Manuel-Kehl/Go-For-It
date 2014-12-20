# About

_Go For It!_ is a simple and stylish productivity app, featuring a to-do list, merged with a timer that keeps your focus on the current task.

![Screenshot](screenshot.png)

# How To

The general workflow is simple:

1. Add tasks to the _To-Do_ list whenever they come to mind.
2. Select a task from your _To-Do_ list.
3. Swtich to the _Go For It!_ pane and start the timer.
4. Work on the selected task. Be productive!
5. Take a break when the time is over. Relax!
7. Mark the task _Done_, when you finished it - directly from the timer pane.
8. Have a glance at your _Done_ list and be proud of what you have achieved lately :-)

# Synchronisation

_Go For It!_ is capable of reading and saving its data as [Todo.txt](http://todotxt.com/) files. 
By following this approach it is compatible with lots of other _Todo.txt_ frontends and synchronisation solutions (including Android and iOS apps).

More backends may be added in the future, but won't be available in the initial release.

# Information For Nerds 

_Go For It!_ is free and open source software published using the GPLv3. It has been written in _Vala_ making heavy use of the _GTK_ framework.

The user interface is inspired by the design philosophy of [elementary OS](http://elementaryos.org/) and [Gnome](http://www.gnome.org/) applications, striving for elegant simplicity.

## How To Build
- `mkdir build`
- `cmake ..`
- `make`
- `sudo make install`
