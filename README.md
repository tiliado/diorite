Diorite Library 4.x [![CircleCI](https://circleci.com/gh/tiliado/diorite.svg?style=svg)](https://circleci.com/gh/tiliado/diorite)
===================

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
  - valac >= 0.41.91 (built with valadoc or pass --novaladoc)
  - glib-2.0 >= 2.56.1
  - gio-2.0 >= 2.56.1
  - gtk+-3.0 >= 3.22.30
  - sqlite >= 3.7
  - x11
  - g-ir-compiler


Waf
---

Diorite uses [waf build system](https://waf.io). You are supposed to use the waf binary bundled with
Diorite's source code. The build script `wscript` may not be compatible with other versions. If you manage
to port wscript to a newer stable waf release, you may provide us with patches to be merged once we decide
to update our waf binary. Meantime, you can carry them downstream.

To find out what build parameters can be set run ./waf --help 

Build
-----

    $ ./waf configure [--prefix=...] [--libdir=...] [--nodebug] [--novaladoc]
    $ ./waf build

Test
----

    LD_LIBRARY_PATH=./build ./build/run-dioritetests

Install
-------

    # ./waf install [--destdir=...]
    
Uninstall
---------

    # ./waf uninstall

Usage
-----

Because Diorite Library doesn't have any API nor ABI stability guarantee,
it uses version suffix in library name to make multiple versions co-installable:

  * pkg-config files: ``dioriteglib4.pc`` and ``dioritegtk4.pc``
  * header files: ``diorite-1.0/dioriteglib4.h`` and ``diorite-1.0/dioritegtk4.h``
  * VAPI files: ``dioriteglib4.{deps,vapi}`` and ``dioritegtk4.{deps,vapi}``
  * shared libraries: ``libdioriteglib4.so`` and ``libdioritegtk4.so``

You probably want to use ``pkg-config``:

    $ pkg-config --libs --cflags dioriteglib4
    -I/usr/local/include/diorite-1.0 -I/usr/include/glib-2.0 \
    -I/usr/lib/x86_64-linux-gnu/glib-2.0/include \
    -L/usr/local/lib -ldioriteglib4
    
    $ pkg-config --libs --cflags dioritegtk4
    -I/usr/local/include/diorite-1.0 -I/usr/include/glib-2.0 \
    -I/usr/lib/x86_64-linux-gnu/glib-2.0/include \
    -L/usr/local/lib -ldioritegtk4

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
