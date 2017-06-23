Diorite Changelog
=================

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
