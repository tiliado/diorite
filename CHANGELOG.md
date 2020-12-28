Diorite Changelog
=================

 * Release announcements for users are posted to [Nuvola News blog](https://medium.com/nuvola-news)
   and social network channels.
 * Developers, maintainers and packagers are supposed to subscribe to
   [Nuvola Devel mailing list](https://groups.google.com/d/forum/nuvola-player-devel)
   to receive more technical announcements and important information about future development.

Release 4.20.0 - December 28, 2020
----------------------------------

* Add Drt.System.get_hostname.

Release 4.19.0 - November 29, 2020
----------------------------------

* Use relative paths in pkg-config files. Issue: tiliado/nuvolaruntime#482
* Make application id and dbus id always equal. Issue: tiliado/diorite#32

Release 4.18.0 - October 30, 2020
---------------------------------

* Refactor convert_sqlite_error into throw_sqlite_error
* The names of git branches has changed:
  * release-4.x - stable version for immediate release
  * master - development branch, merged into stable when ready
* Pre-release git tag (e.g. 4.19.0-dev) are supported.

Release 4.17.0 - September 28, 2020
-----------------------------------

* KeyValueStorage: Tell which property cannot be bound.
* Fix Creation method of abstract class cannot be public (Vala 0.44.1.38-c900b4).
* Add String.repr(): Return a representation of a string.
* Add Types.to_string: Convert a type to a string.
* Drop printf style of TestCase expect/assert methods.
* Sort keys in JsonObject dump. Issue: tiliado/nuvolaruntime#541
* Make built-in theme Adwaita always available. Issue: tiliado/nuvolaruntime#586
* Remove Default from GTK theme selector. Issue: tiliado/nuvolaruntime#586
* Normalize the default GTK theme. Issue: tiliado/nuvolaruntime#586
* Fix warning from Valac 0.48.
* Make EventLoop test less strict.
* Fix syntax error with Vala master.
* Add Drtgtk.DEFAULT_GTK_THEME (Adwaita). Issue: tiliado/nuvolaruntime#636
* Always adjust Adwaita theme name.


Release 4.16.0 - February 24th, 2019
------------------------------------

* Vala 0.44.x is recommended as it fixes some memory leaks.
* Don't pass null to VariantUtils.to_strv. Issue: tiliado/nuvolaruntime#493
* Valadoc is now run with `--fatal-warnings`. This requires Vala 0.44.x but can be disabled with
  `./waf configure --no-strict`.
* Asynchronous tests were fixed.
* Various C warnings were fixed and marked as fatal to be caught in future.
* Various optimizations of memory usage.
* Refactoring continues, test cases and documentation are improved.
* Removed: System.overwrite_file, ConditionalExpression, Bluetooth classes, RichTextBuffer, RichTextView,
  EntryMultiCompletion, Flag.is_set.
* Renamed: System.make_directory_with_parents_sync → System.make_dirs_async,
  System.overwrite_file_async → System.write_to_file_async, TestCase.foo_equals → TestCase.foo_equal.
* New API: String.as_array_of_bytes, TestCase.get_tmp_dir, TestCase.expect_error_match, TestCase.unexpected_error,
  String.as_bytes.


Release 4.15.0 - December 28th, 2018
------------------------------------

* New dependency: gee-0.8 >= 0.20.1
* Build errors with Valac 0.43.x were addressed.
* Drt.TestCase.expect_variant_equal was added to test equality of Variant values.
* Array-comparison TestCase methods were improved to print the value of unequal array elements.
* Rarely used API were removed: Utils.(s)list_to_strv.
* Improved documentation, test cases and refactoring: VariantUtils, Arrays.from_2d_uint8, String.unmask
* Incorrect handling of the title widget and the menu button in ApplicationWindow header bar was fixed.
* The code style checker Valalint is run by default unless `--no-vala-lint` is passed.
* A memory corruption in Drt.String.unmask was fixed. Issue: tiliado/nuvolaruntime#488
* Unit tests are now run also with Valgrind to detect memory errors. A few memory leaks were fixed as a result.
* MALLOC_CHECK_=3 and MALLOC_PERTURB_ are used during development to detect some memory errors.
  Issue: tiliado/nuvolaruntime#490
* RcpRequest.pop_str_list() returns Gee.List instead of GLib.SList.


Release 4.14.0 - November 11th, 2018
------------------------------------

* Waf was updated to 2.0.12 (compatible with Python 3.7). Issue: tiliado/diorite#26
* Diorite testgen is now compatible with Python 3.7. Issue: tiliado/diorite#27
* Fedora 29 is used for continuous integration.
* Utility function `uint8v_equal` was removed. Use `Blobs.blob_equal` instead.
* Utility functions for conversion between binary and other formats were moved under Blobs namespace and renamed.
* New function: Arrays.from_2d_uint8 to extract one-dimensional uint8 array from two-dimensional array.
* Removed classes: VectorClock, Lst.
* Configure script `configure` was removed. Use `waf --configure` instead.
* PropertyBinding now supports int values.
* ApplicationWindow.create_toolbars no longer removes HeaderBar widgets not created with this function.
* The entire codebase was converted to a single code style, which is guarded by valalint (`make valalint`).
* A lot of refactoring and improvements of documentation comments.

Release 4.13.0 - October 14th, 2018
-----------------------------------

* GIR is no longer built by default. Use `--gir` configure flag to build it.
* Various utility functions to print errors were added.
* All deprecation warnings were resolved. Issue: tiliado/diorite#20
* Diorite is now built with fatal warnings but you can pass `--no-strict` to disable that.
* Dependencies were increased: valac >= 0.42.0, glib-2.0 >= 2.56.1, gtk+-3.0 >= 3.22.30.
  If your system contains a different version of Vala, we cannot guarantee that Diorite builds correctly and it
  may lead to memory leaks or [invalid memory access](https://github.com/tiliado/nuvolaruntime/issues/464).
  We recommend [building the correct Vala version from source](https://github.com/tiliado/diorite/commit/d56e4cf528237492cf30608d00fc6cd416e11437)
  prior to building Diorite. You can then throw it away as Vala compiler is not needed after Diorite is built.
* Theme selector uses more human-friendly labels for theme names, e.g. "Arc Darker Solid" instead of "Arc-Darker-solid".
* Added function to get an app-specific machine id hash.
* String.is_empty() check was improved and String.not_empty_or() utility function was added.
* Icons.get_icon_name_for_position was added.
* StackArrow widget was added to switch Gtk.Stack pages.
* Utility function EventLoop.sleep() was added.
* Drt.variant_ref and friends were removed. They were used as a workaround for Variant reference bugs in older Valac.
  Therefore, you now need Valac >= 0.42 which contains the fixes for these issues.
* CircleCI tasks now build Valac from source and you should do the same to avoid incompatibility issues.

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
