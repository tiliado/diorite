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


void main(string[] args){
	Drt.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Gtk.init(ref args);
	var win = new Gtk.Window();
	win.delete_event.connect(() => {Gtk.main_quit(); return false;});
	var grid = new Gtk.Grid();
	grid.row_spacing = grid.column_spacing = grid.margin = 10;
	win.add(grid);
	var line = 0;
	
	var label = new Gtk.Label("Current GTK+ theme:");
	grid.attach(label, 0, line, 1, 1);
	var theme_name = Drtgtk.DesktopShell.get_gtk_theme();
	label = new Gtk.Label(theme_name);
	grid.attach(label, 1, line, 1, 1);
	
	var theme_dir = Drtgtk.DesktopShell.lookup_gtk_theme_dir(theme_name);
	label = new Gtk.Label("Theme dir:");
	grid.attach(label, 0, ++line, 1, 1);
	label = new Gtk.Label(theme_dir != null ? theme_dir.get_path() : "(not found)");
	grid.attach(label, 1, line, 1, 1);
	win.show_all();
	
	lookup_gtk_themes.begin((o, res) => lookup_gtk_themes.end(res));
	
	Gtk.main();
}

async void lookup_gtk_themes() {
	var themes = yield Drtgtk.DesktopShell.list_gtk_themes();
	var names = themes.get_keys();
	names.sort(strcmp);
	foreach (var name in names) {
		stdout.printf("- %s: %s\n", name, themes[name].get_path());
	}
}
