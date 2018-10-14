Diorite Changelog
=================

 * Release announcements for users are posted to [Nuvola News blog](https://medium.com/nuvola-news)
   and social network channels.
 * Developers, maintainers and packagers are supposed to subscribe to
   [Nuvola Devel mailing list](https://groups.google.com/d/forum/nuvola-player-devel)
   to receive more technical announcements and important information about future development.

Release 4.12.0 - July 21st, 2018
--------------------------------

* A continuous integration job was added to test builds with a Fedora image.
* New utility functions were added: Utils.datetime_to_iso_8601 and Add Utils.human_datetime.
* Following GNOME's [App Menu Migration proposal](https://wiki.gnome.org/Design/Whiteboards/AppMenuMigration),
  ApplicationWindow uses a "hamburger" icon for menu button in the header bar and app menu button is always appended to
  the hamburger menu.
* DesktopShell.client_side_decorations is writeable to override auto detection. Issue: tiliado/nuvolaruntime#451

Release 4.11.0 - May 8th, 2018
------------------------------

* Fix "The name Priority' does not exist" Vala 0.40 error. Issue: tiliado/diorite#19
* Fix "Type X can not be used for a GLib.Object property" Vala 0.40 warning. Issue: tiliado/diorite#20
* Fix test case for Valac 0.40. Issue: tiliado/diorite#23
* Add OverlayNotification.
* Catch also GLib.DBusError.TIMED_OUT. Issue: tiliado/nuvolaruntime#419
* Add JsonBuilder.set_string_or_null.


Release 4.10.0 - March 4th, 2018
--------------------------------

* Increased requirements: Vala >= 0.38.4.
* The VAPIDIR environment variable is supported to set extra Vala API directories.
* GIR generation is now optional, you can pass `--no-gir` to disable it.
* Fixed bug in Entry widget that prevented user input.
* Fixed bug when XDG Desktop Portal web browser selector was shown under a dialog window instead of above it.
* RequirementsParser supports 4 states:
* New utility functions: Drt.print_variant()
* Added Drt.Event thread synchronization primitive.

Release 4.9.0 - December 17th, 2017
-------------------------------

  * New widget: Drtgtk.Entry - an enhanced version og Gtk.Entry.
  * Fixed parsing of RPC notifications. Issue: tiliado/nuvolaruntime#385
  * New widget: Drtgtk.HeaderBarTitle - a custom title widget for Gtk.HeaderBar.
  * New utility function: System.cmdline_for_pid - Get command line of a process with given PID.
  * Better debugging: Distinguish between socket creation errors. Issue: tiliado/nuvolaruntime#378
  * New namespace: Drt.Dbus -  DBus introspection and service activation.
  * New utility method: Drt.Flatpak.check_desktop_portal_available - to check whether a proper XDG Desktop Portal
    DBus interface is present.
  * New functionality: Functions to get, set and look up GTK+ 3 themes - see Drtgtk.DesktopShell.
  * New widget: Drtgtk.GtkThemeSelector - a selector to list and change a GTK+ theme.

Release 4.8.0 - September 28th, 2017
--------------------------------

  * Various IPC classes were refactored and united into new API (Rpc prefix) and it is possible to respond
    to IPC messages asynchronously.
  * KeyValueStorage got async equivalents of non-void methods.

Release 4.7.0 - September 1st, 2017
--------------------------------

  * Diorite no longer bundles *.vapi files and depends on those of Vala 0.36.3.
  * GLib dependency has been raised to 2.52.0 to make use of Valac's GTask support.
  * Diorite GTK namespace was changed to Drtgtk.
  * GIR XML and typelib files are generated. Introduces new dependency on g-ir-compiler.

Release 4.6.0 - July 29th, 2017
-------------------------------

  * Namespaces have been united: Drt for Diorite and Drtdb for Diorite DB.
  * Added utils to interact with GLib event loop (Drt.EventLoop).
  * Added workaround for extra Variant unref in ApiNotifications (Drt.ApiChannel.(un)subscribe).
  * Added methods to (un)subscribe for ApiNotifications.
  * Added CSS style classes for badges (Drt.Css.BADGE_*).
  * Added various utility functions (Drt.Time.get_unix_time_now_utc, Drt.String.concat, Drt.String.append,
    Drt.variant_dump, Drt.variant_ref, Drt.variant_unref).
  * ApplicationWindow.app field is now protected (private previously).

Release 4.5.0 - June 23rd, 2017
-------------------------------

  * Fix wscript for non-git builds. Issue: tiliado/diorite#16
  * Dioritedb has been refactored significantly.
  * Bundled glib.vapi is no longer used.
  * Various utility functions were added, see git log for details.

Release 4.4.0 - May 27th, 2017
------------------------------

  * Versioning scheme is synchronized with Nuvola Apps 4.4. Library names have been changed accordingly:
    dioriteglib-0.3 → dioriteglib4 and dioritegtk-0.3 → dioritegtk4.
  * Vala documentation is built by default. Requires valadoc >= 0.36 but can be disabled with --novaladoc
    flag.
  * Various utility functions were added. See git log for details.

Release 0.3.4 - April 30th, 2017
--------------------------------

  * Development snapshot for Nuvola 3.1.3.
  * Build script was reworked and ported to Waf 1.9.10. See Readme.md for more information.
  * Modernisation has begun. Dependencies were raised and legacy code is being removed.
  * All Python scripts require Python >= 3.4.
  * Code has been ported to Valac 0.36.
  * Client-side decorations are enabled for Pantheon desktop environment (elementaryOS).
  * Added license file.
  * Appmenu, toolbar & menubar handling was refactored and double appmenus fixed. Issue: tiliado/diorite#4

Releases 0.3.x
--------------

  * Development snapshots.

Release 0.2.0 - December 30, 2015
---------------------------------

  * Initial release.

Releases 0.1.x
--------------

  * Development snapshots.
