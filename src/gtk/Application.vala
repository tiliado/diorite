/*
 * Copyright 2011-2018 Jiří Janoušek <janousek.jiri@gmail.com>
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

private const string G_LOG_DOMAIN="DioriteGtk";

namespace Drtgtk {

[CCode (cheader_filename = "sys/prctl.h", cname = "prctl")]
extern int prctl (int option, string arg2, ulong arg3, ulong arg4, ulong arg5);

public errordomain AppError {
    NOT_RUNNING,
    ALREADY_RUNNING,
    UNABLE_TO_TERMINATE,
    UNABLE_TO_ACTIVATE
}

private const int XFCE_SESSION_END = 4;
private const string XFCE_SESSION_SERVICE_NAME = "org.xfce.SessionManager";
private const string XFCE_SESSION_SERVICE_OBJECT = "/org/xfce/SessionManager";

public abstract class Application : Gtk.Application {
    private static Application? instance;
    public string desktop_name {get; protected set;}
    public string app_id {get; protected set;}
    public string app_name {get; protected set;}
    public string icon {get; protected set; default = "";}
    public string version {get; protected set; default = "";}
    public Actions? actions {get; private set; default = null;}
    public DesktopShell? shell {get; private set; default = null;}
    private XfceSessionManager? xfce_session = null;
    private Menu? menubar_app_submenu = null;
    private Menu? default_menubar = null;

    public Application(
        string uid, string name, string? dbus_name = null,
        GLib.ApplicationFlags flags=GLib.ApplicationFlags.FLAGS_NONE
    ) {
        Object(application_id: dbus_name ?? uid, flags: flags);
        this.app_name = name;
        this.desktop_name = uid + ".desktop";
        this.app_id = uid;
        actions = new Actions(this);
        prctl(15, uid, 0, 0, 0);
        GLib.Environment.set_prgname(uid);
        GLib.Environment.set_application_name(name);
    }

    public virtual signal void fatal_error(string title, string message, bool markup=false) {
        critical("%s. %s", title, message);
        quit();
    }

    public virtual signal void show_error(string title, string message, bool markup=false) {
        warning("%s. %s", title, message);
    }

    public virtual signal void show_warning(string title, string message, bool markup=false) {
        warning("%s. %s", title, message);
    }

    public virtual signal void show_info(string title, string message, bool markup=false) {
        GLib.message("%s. %s", title, message);
    }

    /**
     * Try to show URI and show info bar warning on failure.
     */
    public void show_uri(string uri, uint32 timestamp=Gdk.CURRENT_TIME) {
        var app_window = active_window as ApplicationWindow;
        if (app_window == null) {
            unowned List<weak Gtk.Window> windows = get_windows();
            foreach (var window in windows) {
                if (window is ApplicationWindow) {
                    app_window = (ApplicationWindow) window;
                    break;
                }
            }
        }
        try {
            var reference_window = active_window;
            if (reference_window != null) {
                var toplevels = Gtk.Window.list_toplevels();
                foreach (var toplevel in toplevels) {
                    if (toplevel.visible && active_window == toplevel.get_transient_for()) {
                        /* Do not show XDG Desktop Portal web browser selector under a dialog. */
                        reference_window = toplevel;
                        break;
                    }
                }
            }
            Gtk.show_uri_on_window(reference_window, uri, timestamp);
        } catch (GLib.Error e) {
            warning("Failed to show URI %s. %s", uri, e.message);
            if (app_window != null) {
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

    public override void startup() {
        /* Set program name */
        Gdk.set_program_class(app_id); // must be set after Gtk.init()!
        instance = this;
        Posix.sigaction_t sig_action = {};
        sig_action.sa_sigaction = terminate_handler;
        sig_action.sa_flags |= Posix.SA_SIGINFO;
        Posix.sigaction(Posix.Signal.TERM, sig_action, null);
        Posix.sigaction(Posix.Signal.TERM, sig_action, null);
        Posix.sigaction(Posix.Signal.HUP, sig_action, null);
        Bus.watch_name(BusType.SESSION, XFCE_SESSION_SERVICE_NAME,
            BusNameWatcherFlags.NONE, on_xfce_session_appeared, on_xfce_session_vanished);
        base.startup();

        /* Use this enviroment variable only for debugging purposes */
        var gui_mode = Environment.get_variable("DIORITE_GUI_MODE");
        if (gui_mode != null) {
            switch (gui_mode) {
            case "unity":
                DesktopShell.set_default(new UnityDesktopShell());
                break;
            case "gnome":
                DesktopShell.set_default(new GnomeDesktopShell());
                break;
            case "xfce":
                DesktopShell.set_default(new XfceDesktopShell());
                break;
            case "":
            case "default":
                break;
            default:
                warning("DIORITE_GUI_MODE should be one of default|unity|gnome|xfce, not %s", gui_mode);
                break;
            }
        }

        shell = DesktopShell.get_default();
        shell.app_menu_changed.connect(on_app_menu_changed);
        set_menubar(reset_menubar());
        apply_custom_styles(Gdk.Screen.get_default());
    }

    public void set_app_menu_items(string[] items) {
        shell.set_app_menu_from_model(actions.build_menu(items, true, false));
    }

    public Menu reset_menubar() {
        if (default_menubar == null) {
            default_menubar = new Menu();
        } else {
            default_menubar.remove_all();
        }
        menubar_app_submenu = null;
        var unity = shell.shows_app_menu && shell.shows_menu_bar;
        if (!unity && shell.app_menu != null) {
            menubar_app_submenu = Actions.copy_menu_model(shell.app_menu);
            default_menubar.append_submenu("_App", menubar_app_submenu);
        }
        return default_menubar;
    }

    /**
     * Apply custom CSS styles.
     *
     * @param screen    Screen to apply styles to.
     */
    public virtual void apply_custom_styles(Gdk.Screen screen) {
        try {
            Css.apply_custom_styles(screen);
        } catch (GLib.Error e) {
            warning("Failed to load custom CSS: %s", e.message);
        }
    }

    private static void terminate_handler(int sig_num, Posix.siginfo_t info, void* data) {
        var sig_pid = (int) info.si_pid;
        var cmdline = System.get_cmdline_for_pid(sig_pid);
        if (sig_num == Posix.Signal.TERM && sig_pid == Posix.getpid()) {
            warning("Ignoring signal %d from PID %d (%s).", sig_num, sig_pid, cmdline);
        } else {
            debug("Caught signal %d from PID %d (%s), exiting ...", sig_num, sig_pid, cmdline);
            if (instance == null) {
                error("No instance to terminate");
            } else {
                instance.quit();
            }
        }
    }

    private void on_xfce_session_appeared(DBusConnection conn, string name, string owner) {
        debug("XFCE session appeared: %s, %s", name, owner);
        try {
            xfce_session = Bus.get_proxy_sync(BusType.SESSION, XFCE_SESSION_SERVICE_NAME, XFCE_SESSION_SERVICE_OBJECT);
            xfce_session.state_changed.connect(on_xfce_session_state_changed);
        } catch(GLib.IOError e) {
            warning("Unable to get proxy for Xfce session: %s", e.message);
            xfce_session = null;
        }
    }

    private void on_app_menu_changed(DesktopShell shell) {
        if (shell.shows_app_menu && app_menu != shell.app_menu) {
            if (app_menu != null) {
                warning("An attempt to overwrite app menu.");
            } else if (get_windows() != null) {
                warning("Cannot set an app menu because an app window has been already created.");
            } else {
                set_app_menu(shell.app_menu);
            }
        }
        if (menubar_app_submenu != null && shell.app_menu != null) {
            Actions.replace_from_menu_model(menubar_app_submenu, shell.app_menu);
        }
    }

    /**
     * Removes proxy object
     */
    private void on_xfce_session_vanished(DBusConnection conn, string name) {
        debug("XFCE session vanished: %s", name);
        if (xfce_session == null) {
            return;
        }
        xfce_session.state_changed.disconnect(on_xfce_session_state_changed);
        xfce_session = null;
    }

    private void on_xfce_session_state_changed(uint32 old_value, uint32 new_value) {
        if (new_value == XFCE_SESSION_END) {
            debug("XFCE session end");
            quit();
        }
    }
}

} // namespace Drtgtk

[DBus(name = "org.xfce.Session.Manager")]
private interface XfceSessionManager : Object {
    public signal void state_changed(uint32 old_value, uint32 new_value);
}
