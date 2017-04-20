Diorite Library 0.3.x
=====================

![Diorite stone](diorite.jpg)

 * Diorite is a a grey to dark-grey intermediate intrusive igneous rock.
 * Diorite library is a private utility and widget library for Nuvola Apps project based on GLib, GIO and GTK.
 * Diorite code is rolling as stones from a hill. There are no stable releases since 0.3.0 but only blessed
   snapshots because users expect that version numbers increase from time to time.
 * The only upstream supported version is the latest git master commit, anything older is for archaeologists.

*Photo by Michael C. Rygel via Wikimedia Commons, [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/deed.en)*

Dependencies
------------

  - Python 3 and the pyparsing module
  - glib-2.0 >= 2.42
  - gio-2.0 >= 2.42
  - gtk+-3.0 >= 3.22
  - sqlite >= 3.7
  - x11

Build
-----

    $ ./waf configure
    $ ./waf build

Install
-------

    # ./waf install
    
Uninstall
---------

    # ./waf uninstall

Usage
-----

Because Diorite Library doesn't have any API nor ABI stability guarantee,
it uses 0.x version suffix in library name to make multiple versions co-installable:

  * pkg-config files: ``dioriteglib-0.x.pc`` and ``dioritegtk-0.x.pc``
  * header files: ``diorite-1.0/dioriteglib-0.x.h`` and ``diorite-1.0/dioritegtk-0.x.h``
  * VAPI files: ``dioriteglib-0.x.{deps,vapi}`` and ``dioritegtk-0.x.{deps,vapi}``
  * shared libraries: ``libdioriteglib-0.x.so`` and ``libdioritegtk-0.x.so``

You probably want to use ``pkg-config``:

    $ pkg-config --libs --cflags dioriteglib-0.1
    -I/usr/local/include/diorite-1.0 -I/usr/include/glib-2.0 \
    -I/usr/lib/x86_64-linux-gnu/glib-2.0/include \
    -L/usr/local/lib -ldioriteglib-0.1
    
    $ pkg-config --libs --cflags dioritegtk-0.1
    -I/usr/local/include/diorite-1.0 -I/usr/include/glib-2.0 \
    -I/usr/lib/x86_64-linux-gnu/glib-2.0/include \
    -L/usr/local/lib -ldioritegtk-0.1

Environment Variables
---------------------

Diorite recognizes several environment variables for debugging:

  * `DIORITE_SHOW_MENUBAR` - if `true` ApplicationWindow shows menubar. This is useful if you test
    menubar in other environments than Unity, because the menubar is not show by default.
 
  * `DIORITE_GUI_MODE` - set to `unity`, `gnome`, `xfce` or `default` to simulate look of
    a application window (menu bar, header bar, app menu, etc.) in different environment.
  
  * `DIORITE_LOG_MESSAGE_CHANNEL` - if `yes` MessageChannel communication will be logged
  * `DIORITE_LOG_DUPLEX_CHANNEL` - if `yes` DuplexChannel communication will be logged
  * `DIORITE_LOG_API_ROUTER` - if `yes` ApiRouter communication will be logged
  
  * `DIORITE_DUPLEX_CHANNEL_FATAL_TIMEOUT` - if `yes`, DuplexChannel timeout will abort
  * `DIORITE_LOGGER_FATAL_STRING` - abort program when message matching the fatal
    [string pattern](https://developer.gnome.org/glib/stable/glib-Glob-style-pattern-matching.html) is logged.

Changelog
---------

See [CHANGELOG.md](./CHANGELOG.md).
