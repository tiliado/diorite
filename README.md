Diorite Library
===============

_Private utility and widget library for Nuvola Player project based on GLib, GIO and GTK._

Status: Early alpha
--------------------

  - No API & ABI stability
  - Dependencies are not frozen
  - No test case
  - No documentation
  - Not suitable for your project

Dependencies
------------

  - Python 2 to run ./waf
  - Python 3 to run ./testgen.py
  - glib-2.0 2.34
  - ghread-2.0 2.34
  - gio-2.0 2.38
  - gtk+-3.0 3.4

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

Because Diorite Library doesn't have any API nor ABI stability guarantee yet,
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
