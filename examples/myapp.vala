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
	private Gtk.ApplicationWindow? main_window = null;
	
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
		var menu = new GLib.Menu();
		menu.append("Quit", "app.quit");
		var action = new GLib.SimpleAction("quit", null);
		action.activate.connect(on_quit);
		add_action(action);
		set_app_menu(menu);
		main_window = new Gtk.ApplicationWindow(this);
		menu = new GLib.Menu();
		menu.append("View", "win.view");
		action = new GLib.SimpleAction("view", null);
		main_window.add_action(action);
		set_menubar(menu);
	}
	
	private void on_quit()
	{
		quit();
	}
}

int main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	var me = args[0];
	debug("Debug: %s", me);
	var app = new MyApp();
	return app.run(args);
	
}
