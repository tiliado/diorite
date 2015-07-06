/* 
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */



public class MyApp : Diorite.Application
{
	private Diorite.ApplicationWindow? main_window = null;
	
	public MyApp()
	{
		base("cz.fenryxo.MyApp", "My App", "myapp.desktop", "myapp");
		icon = "gedit";
		version = "0.1";
	}
	
	public override void activate()
	{
		if (main_window == null)
			start();
		main_window.present();
	}
	
	private void start()
	{
		main_window = new Diorite.ApplicationWindow(this, true);
		main_window.set_default_size(400, 400);
		main_window.set_title("My App Window");
		append_actions();
		
		var app_menu = actions.build_menu({
			Actions.FORMAT_SUPPORT, Actions.DONATE,
			Actions.PREFERENCES, Actions.HELP, Actions.ABOUT, Actions.QUIT}, true, false);
		set_app_menu(app_menu);
		
		main_window.create_toolbar({Actions.GO_BACK, Actions.GO_FORWARD, Actions.GO_RELOAD, Actions.GO_HOME, " ", Actions.DONATE});
		main_window.create_menu_button({Actions.ZOOM_IN, Actions.ZOOM_OUT, Actions.ZOOM_RESET, "|", Actions.TOGGLE_SIDEBAR});
		
		var menubar = new Menu();
		menubar.append_submenu("_Go", actions.build_menu({Actions.GO_HOME, Actions.GO_RELOAD, Actions.GO_BACK, Actions.GO_FORWARD}, true, false));
		menubar.append_submenu("_View", actions.build_menu({Actions.ZOOM_IN, Actions.ZOOM_OUT, Actions.ZOOM_RESET, "|", Actions.TOGGLE_SIDEBAR}, true, false));
		set_menubar(menubar);
		
		
		
		main_window.show_all();
	}
	
	private void append_actions()
	{
		Diorite.Action[] actions = {
		//          Action(group, scope, name, label?, mnemo_label?, icon?, keybinding?, callback?)
		new Diorite.SimpleAction("main", "app", Actions.QUIT, "Quit", "_Quit", "application-exit", "<ctrl>Q", on_quit),
		new Diorite.SimpleAction("main", "win", "menu", "Menu", null, "emblem-system-symbolic", null, null),
		new Diorite.SimpleAction("main", "app", Actions.ACTIVATE, "Activate main window", null, null, null, null),
		new Diorite.SimpleAction("main", "app", Actions.FORMAT_SUPPORT, "Format Support", "_Format support", null, null, null),
		new Diorite.SimpleAction("main", "app", Actions.ABOUT, "About", "_About", null, null, null),
		new Diorite.SimpleAction("main", "app", Actions.HELP, "Help", "_Help", null, "F1", null),
		new Diorite.SimpleAction("main", "app", Actions.DONATE, "Donate", null, "emblem-favorite", null, null),
		new Diorite.SimpleAction("main", "app", Actions.PREFERENCES, "Preferences", "_Preferences", null, null, null),
		new Diorite.ToggleAction("main", "win", Actions.TOGGLE_SIDEBAR, "Show sidebar", "Show _sidebar", null, null, null, true),
		new Diorite.SimpleAction("go", "app", Actions.GO_HOME, "Home", "_Home", "go-home", "<alt>Home", null),
		new Diorite.SimpleAction("go", "app", Actions.GO_BACK, "Back", "_Back", "go-previous", "<alt>Left", null),
		new Diorite.SimpleAction("go", "app", Actions.GO_FORWARD, "Forward", "_Forward", "go-next", "<alt>Right", null),
		new Diorite.SimpleAction("go", "app", Actions.GO_RELOAD, "Reload", "_Reload", "view-refresh", "<ctrl>R", null),
		new Diorite.SimpleAction("view", "win", Actions.ZOOM_IN, "Zoom in", null, "zoom-in", "<ctrl>plus", null),
		new Diorite.SimpleAction("view", "win", Actions.ZOOM_OUT, "Zoom out", null, "zoom-out", "<ctrl>minus", null),
		new Diorite.SimpleAction("view", "win", Actions.ZOOM_RESET, "Original zoom", null, "zoom-original", "<ctrl>0", null)
		};
		this.actions.add_actions(actions);
		
	}
	
	private void on_quit()
	{
		quit();
	}
}

namespace Actions
{
	public const string ABOUT = "about";
	public const string HELP = "help";
	public const string DONATE = "donate";
	public const string ACTIVATE = "activate";
	public const string GO_HOME = "go-home";
	public const string GO_BACK = "go-back";
	public const string GO_FORWARD = "go-forward";
	public const string GO_RELOAD = "go-reload";
	public const string FORMAT_SUPPORT = "format-support";
	public const string PREFERENCES = "preferences";
	public const string TOGGLE_SIDEBAR = "toggle-sidebar";
	public const string ZOOM_IN = "zoom-in";
	public const string ZOOM_OUT = "zoom-out";
	public const string ZOOM_RESET = "zoom-reset";
	public const string QUIT = "quit";
}

int main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	var me = args[0];
	debug("Debug: %s", me);
	var app = new MyApp();
	return app.run(args);
	
}
