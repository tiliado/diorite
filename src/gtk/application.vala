/*
 * Copyright 2011-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

private const string G_LOG_DOMAIN="DioriteGtk";
namespace Diorite
{
	
#if LINUX
[CCode (cheader_filename = "sys/prctl.h", cname = "prctl")]
extern int prctl (int option, string arg2, ulong arg3, ulong arg4, ulong arg5);
#endif

public errordomain AppError
{
	NOT_RUNNING,
	ALREADY_RUNNING,
	UNABLE_TO_TERMINATE,
	UNABLE_TO_ACTIVATE
}

#if LINUX
private const int XFCE_SESSION_END = 4;
private const string XFCE_SESSION_SERVICE_NAME = "org.xfce.SessionManager";
private const string XFCE_SESSION_SERVICE_OBJECT = "/org/xfce/SessionManager";
#endif

public abstract class Application : Gtk.Application
{
	private static Application? instance;
	public string desktop_name {get; protected set;}
	public string app_id {get; protected set;}
	public string app_name {get; protected set;}
	public string icon {get; protected set; default = "";}
	public string version {get; protected set; default = "";}
	public bool app_menu_shown {get; private set; default = false;}
	public bool menubar_shown {get; private set; default = false;}
	#if LINUX
	private XfceSessionManager? xfce_session = null;
	#endif
	
	public Application(string app_uid, string app_name, string desktop_name, string app_id,
	  GLib.ApplicationFlags flags=GLib.ApplicationFlags.FLAGS_NONE)
	{
		Object(application_id: app_uid, flags: flags);
		this.app_name = app_name;
		this.desktop_name = desktop_name;
		this.app_id = app_id;
		#if LINUX
		prctl(15, app_id, 0, 0, 0);
		#endif
		GLib.Environment.set_prgname(app_id);
		GLib.Environment.set_application_name(app_name);
	}
	
	public virtual signal void fatal_error(string title, string message)
	{
		critical("%s. %s", title, message);
		quit();
	}
	
	public virtual signal void show_error(string title, string message)
	{
		warning("%s. %s", title, message);
	}
	
	public virtual signal void show_warning(string title, string message)
	{
		warning("%s. %s", title, message);
	}
	
	public virtual signal void show_info(string title, string message)
	{
		GLib.message("%s. %s", title, message);
	}
	
	/**
	 * Try to show URI and show info bar warning on failure.
	 */
	public void show_uri(string uri, uint32 timestamp=Gdk.CURRENT_TIME)
	{
		try
		{
			Gtk.show_uri(null, uri, timestamp);
		}
		catch (GLib.Error e)
		{
			warning("Failed to show URI %s. %s", uri, e.message);
			var app_window = active_window as ApplicationWindow;
			if (app_window == null)
			{
				unowned List<weak Gtk.Window> windows = get_windows();
				foreach (var window in windows)
				{
					if (window is ApplicationWindow)
					{
						app_window = (ApplicationWindow) window;
						break;
					}
				}
			}
			if (app_window != null)
			{
				var info_bar = new Gtk.InfoBar();
				info_bar.show_close_button = true;
				info_bar.message_type = Gtk.MessageType.WARNING;
				var label = new Gtk.Label(Markup.printf_escaped(
					"Failed to open URI <a href=\"%1$s\">%1$s</a>", uri));
				label.use_markup = true;
				label.set_line_wrap(true);
				label.hexpand = false;
				label.selectable = false;
				info_bar.get_content_area().add(label);
				info_bar.response.connect((bar, resp) => {app_window.info_bars.remove(bar);});
				info_bar.show_all();
				app_window.info_bars.add(info_bar);
			}
			
		}
	}
	
	public override void startup()
	{
		/* Set program name */
		
		Gdk.set_program_class(app_id); // must be set after Gtk.init()!
		
		instance = this;
		
		#if LINUX
		Posix.signal(Posix.SIGINT, terminate_handler);
		Posix.signal(Posix.SIGTERM, terminate_handler);
		Posix.signal(Posix.SIGHUP, terminate_handler);
		Bus.watch_name(BusType.SESSION, XFCE_SESSION_SERVICE_NAME,
		BusNameWatcherFlags.NONE, on_xfce_session_appeared, on_xfce_session_vanished);
		#else
		// TODO: How about signal handling on Windows?
		#endif
		base.startup();
		
		var gtk_settings = Gtk.Settings.get_default();
		/* Use this enviroment variable only for debugging purposes */
		var gui_mode = Environment.get_variable("DIORITE_GUI_MODE");
		if (gui_mode != null)
		{
			switch (gui_mode)
			{
			case "unity":
				gtk_settings.gtk_shell_shows_app_menu = true;
				gtk_settings.gtk_shell_shows_menubar = true;
				break;
			case "gnome":
				gtk_settings.gtk_shell_shows_app_menu = true;
				gtk_settings.gtk_shell_shows_menubar = false;
				break;
			case "xfce":
				gtk_settings.gtk_shell_shows_app_menu = false;
				gtk_settings.gtk_shell_shows_menubar = false;
				break;
			case "":
			case "default":
				break;
			default:
				warning("DIORITE_GUI_MODE should be one of default|unity|gnome|xfce, not %s", gui_mode);
				break;
			}
		}
		
		if (gtk_settings.gtk_shell_shows_app_menu)
		{
			app_menu_shown = true;
			menubar_shown = gtk_settings.gtk_shell_shows_menubar;
		}
	}
	
	#if LINUX
	private static void terminate_handler(int sig_num)
	{
		debug("Caught signal %d, exiting ...", sig_num);
		if (instance == null)
			error("No instance to terminate");
		
		instance.quit();
	}
	
	private void on_xfce_session_appeared(DBusConnection conn, string name, string owner)
	{
		debug("XFCE session appeared: %s, %s", name, owner);
		try
		{
			xfce_session = Bus.get_proxy_sync(BusType.SESSION, XFCE_SESSION_SERVICE_NAME, XFCE_SESSION_SERVICE_OBJECT);
			xfce_session.state_changed.connect(on_xfce_session_state_changed);
		}
		catch(GLib.IOError e)
		{
			warning("Unable to get proxy for Xfce session: %s", e.message);
			xfce_session = null;
		}
	}
	
	/**
	 * Removes proxy object
	 */
	private void on_xfce_session_vanished(DBusConnection conn, string name)
	{
		debug("XFCE session vanished: %s", name);
		if (xfce_session == null)
			return;
		xfce_session.state_changed.disconnect(on_xfce_session_state_changed);
		xfce_session = null;
	}
	
	private void on_xfce_session_state_changed(uint32 old_value, uint32 new_value)
	{
		if (new_value == XFCE_SESSION_END)
		{
			debug("XFCE session end");
			quit();
		}
	}
	#endif
}

} // namespace Diorite

#if LINUX
[DBus(name = "org.xfce.Session.Manager")]
private interface XfceSessionManager : Object
{
	public signal void state_changed(uint32 old_value, uint32 new_value);
}
#endif
