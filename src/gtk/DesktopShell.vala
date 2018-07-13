/*
 * Copyright 2015-2017 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

using Drt;

namespace Drtgtk
{

public abstract class DesktopShell: GLib.Object
{
	private static DesktopShell? default_shell = null;
	private static GenericSet<string> shells = null;
	private static string? initial_gtk_theme = null;
	public bool shows_app_menu {get; protected set; default = false;}
	public bool shows_menu_bar {get; protected set; default = false;}
	public bool client_side_decorations {get; set; default = false;}
	public GLib.MenuModel? app_menu {get{return _app_menu;}}
	#if !FLATPAK
	public string? wm_name {get; protected set; default = null;}
	public string? wm_name_exact {get; protected set; default = null;}
	public string? wm_version {get; protected set; default = null;}
	#else
	public bool dialogs_use_header {get; protected set; default = false;}
	#endif
	private GLib.Menu _app_menu = null;
	
	public static DesktopShell get_default()
	{
		if (DesktopShell.default_shell == null)
			DesktopShell.default_shell = new DefaultDesktopShell();
		return DesktopShell.default_shell;
	}
	
	private static void gather_shell_info()
	{
		if (shells == null)
		{
			shells = new GenericSet<string>(str_hash, str_equal);
			foreach  (var variable in new string[]{"XDG_CURRENT_DESKTOP", "XDG_SESSION_DESKTOP", "DESKTOP_SESSION"})
			{
				var shell = Environment.get_variable(variable);
				debug("Shell: %s = %s", variable, shell);
				if (shell != null)
				{
					var parts = String.split_strip(shell.down(), ":");
					foreach (var part in parts)
						shells.add(part);
				}
			}
		}
	}
	
	public static bool have_shell(string name)
	{
		gather_shell_info();
		return name.down() in shells;
	}
	
	internal static void set_default(DesktopShell? default_shell)
	{
		DesktopShell.default_shell = default_shell;
	}
	
	/**
	 * Get the current GTK+ theme name.
	 * 
	 * @return The name of the current GTK+ theme.
	 */
	public static string get_gtk_theme() {
		var theme = Gtk.Settings.get_default().gtk_theme_name;
		return theme != "" ? theme : "Adwaita";
	}
	
	/**
	 * Get the initial GTK+ theme name.
	 * 
	 * @return The name of the initial GTK+ theme. May be an empty string but not null.
	 */
	public static unowned string get_initial_gtk_theme() {
		if (initial_gtk_theme == null) {
			initial_gtk_theme = Gtk.Settings.get_default().gtk_theme_name ?? "";
		}
		return initial_gtk_theme;
	}
	
	/**
	 * Set the current GTK+ theme name.
	 * 
	 * @param theme    The name of the GTK+ theme to set.
	 */
	public static void set_gtk_theme(string theme) {
		get_initial_gtk_theme();  // remember initial GTK+ theme
		Gtk.Settings.get_default().gtk_theme_name = theme;
	}
	
	/**
	 * Reset the initial GTK+ theme name.
	 */
	public static void reset_gtk_theme() {
		Gtk.Settings.get_default().gtk_theme_name = get_initial_gtk_theme();
	}
	
	/**
	 * Returns the directory of a GTK+ theme.
	 * 
	 * @param theme    The name of GTK+ theme to look up.
	 * @return Theme directory, or null if not found.
	 */ 
	public static File? lookup_gtk_theme_dir(string theme) {
		var gtk_css = new Drt.XdgStorage().get_data_file("themes/%s/gtk-3.0/gtk.css".printf(theme));
		return gtk_css != null ? gtk_css.get_parent() : null;
	}
	
	/**
	 * Check whether a GTK+ theme exists.
	 * 
	 * @param theme    The name of GTK+ theme to look up.
	 * @return true if the theme exists, false otherwise.
	 */
	public static bool gtk_theme_exists(string theme) {
		return lookup_gtk_theme_dir(theme) != null;
	}
	
	/**
	 * List available GTK+ themes.
	 * 
	 * @return A HashTable of GTK+ theme names and corresponding `gtk+3.0` theme directories.
	 */
	public static async HashTable<string, File> list_gtk_themes() {
		var storage = new Drt.XdgStorage();
		var theme_dirs = new HashTable<string, File>(str_hash, str_equal);
		foreach (unowned File data_dir in storage.data_dirs()) {
			var themes_dir = data_dir.get_child("themes");
			try {
				var enumerator = yield themes_dir.enumerate_children_async(
					"standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);
				FileInfo info;
				while ((info = enumerator.next_file(null)) != null) {
					var name = info.get_name();
					if (!(name in theme_dirs)) {
						var theme_dir = themes_dir.get_child(name).get_child("gtk-3.0");
						var gtk_css = theme_dir.get_child("gtk.css");
						try {
							yield gtk_css.query_info_async(FileAttribute.STANDARD_TYPE, 0, Priority.DEFAULT, null);
							theme_dirs[name] = theme_dir;
						} catch (GLib.Error e) {
							if (!(e is GLib.IOError.NOT_FOUND)) {
								warning("Failed to get file info for '%s': %s", gtk_css.get_path(), e.message);
							}
						}
					}
				}
			} catch (GLib.Error e) {
				if (!(e is GLib.IOError.NOT_FOUND)) {
					warning("Failed to enumerate '%s': %s", themes_dir.get_path(), e.message);
				}
			}
		}
		return theme_dirs;
	}
	
	public void set_app_menu_from_model(GLib.MenuModel model)
	{
		if (_app_menu == null)
			_app_menu = new Menu();
		Actions.replace_from_menu_model(_app_menu, model);
		app_menu_changed();
	}
	
	public signal void app_menu_changed();
	
	#if !FLATPAK
	protected Gdk.X11.Window? inspect_window_manager()
	{
		var net_wm_check_window = X11.get_net_wm_check_window();
		if (net_wm_check_window != null)
		{
			wm_name_exact = X11.get_window_property_as_utf8(net_wm_check_window, "_NET_WM_NAME");
			if (wm_name_exact != null)
				wm_name = wm_name_exact.down();
			
			switch (wm_name)
			{
			case "gnome shell":
			case "mutter":
			case "mutter(gala)":
				wm_version = X11.get_window_property_as_utf8(net_wm_check_window, "_MUTTER_VERSION");
				break;
			}
		}
		return net_wm_check_window;
	}
	#endif
}

private class DefaultDesktopShell: DesktopShell
{
	public DefaultDesktopShell()
	{
		var gs = Gtk.Settings.get_default();
		shows_app_menu = gs.gtk_shell_shows_app_menu;
		shows_menu_bar = gs.gtk_shell_shows_menubar;
		#if FLATPAK
		dialogs_use_header = gs.gtk_dialogs_use_header;
		client_side_decorations = shows_app_menu && !shows_menu_bar || dialogs_use_header;
		if (!client_side_decorations)
			client_side_decorations = have_shell("pantheon");
			
		debug(
			"Shell %s: CSD %d, appmenu %d, menubar %d, dialog header %d",
			Environment.get_variable("XDG_CURRENT_DESKTOP"), (int) client_side_decorations,
			(int) shows_app_menu, (int) shows_menu_bar, (int) dialogs_use_header);
		#else
		inspect_window_manager();
		switch (wm_name)
		{
		case "gnome shell":
		case "mutter":
		case "mutter(gala)":
			client_side_decorations = true;
			break;
		case "mutter(budgie)":
			client_side_decorations = true;
			/* Budgie desktop hasn't added proper Xsettings overrides yet to say it doesn't support appmenus.
			 * https://github.com/tiliado/nuvolaplayer/issues/193 */
			gs.gtk_shell_shows_app_menu = shows_app_menu = false;
			break;
		}
		
		debug(
			"Shell: %s %s, CSD %d, appmenu %d, menubar %d", wm_name, wm_version,
			(int) client_side_decorations, (int) shows_app_menu, (int) shows_menu_bar);
		#endif
	}
}


private class GnomeDesktopShell: DesktopShell
{
	public GnomeDesktopShell()
	{
		
		var gs = Gtk.Settings.get_default();
		shows_app_menu = gs.gtk_shell_shows_app_menu = true;
		shows_menu_bar = gs.gtk_shell_shows_menubar = false;
		client_side_decorations = true;
		#if FLATPAK
		dialogs_use_header = gs.gtk_dialogs_use_header = true;
		debug("Shell GNOME: CSD %s", client_side_decorations ? "on" : "off");
		#else
		inspect_window_manager();
		debug("Shell (GNOME): %s %s, CSD %s", wm_name, wm_version, client_side_decorations ? "on" : "off");
		#endif
	}
}


private class UnityDesktopShell: DesktopShell
{
	public UnityDesktopShell()
	{
		var gs = Gtk.Settings.get_default();
		shows_app_menu = gs.gtk_shell_shows_app_menu = true;
		shows_menu_bar = gs.gtk_shell_shows_menubar = true;
		client_side_decorations = false;
		#if FLATPAK
		dialogs_use_header = gs.gtk_dialogs_use_header = false;
		debug("Shell Unity: CSD %s", client_side_decorations ? "on" : "off");
		#else
		inspect_window_manager();
		debug("Shell (Unity): %s %s, CSD %s", wm_name, wm_version, client_side_decorations ? "on" : "off");
		#endif
	}
}


private class XfceDesktopShell: DesktopShell
{
	public XfceDesktopShell()
	{
		var gs = Gtk.Settings.get_default();
		shows_app_menu = gs.gtk_shell_shows_app_menu = false;
		shows_menu_bar = gs.gtk_shell_shows_menubar = false;
		client_side_decorations = false;
		#if FLATPAK
		dialogs_use_header = gs.gtk_dialogs_use_header = false;
		debug("Shell XFCE: CSD %s", client_side_decorations ? "on" : "off");
		#else
		inspect_window_manager();
		debug("Shell (XFCE): %s %s, CSD %s", wm_name, wm_version, client_side_decorations ? "on" : "off");
		#endif
	}
}

} // namespace Drtgtk
