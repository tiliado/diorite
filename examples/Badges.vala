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

namespace Example
{

int main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Gtk.init(ref args);
	try
	{
		Drt.Css.apply_custom_styles(Gdk.Screen.get_default());
	}
	catch (GLib.Error e)
	{
		error("Failed to load CSS styles: %s", e.message);
	}
	var window = new Gtk.Window();
	window.delete_event.connect(() => { quit(); return false;});
	window.show();
	var grid = new Gtk.Grid();
	grid.column_spacing = grid.row_spacing = grid.margin = 10;
	string[] classes = {Drt.Css.BADGE_DEFAULT, Drt.Css.BADGE_INFO, Drt.Css.BADGE_OK, Drt.Css.BADGE_WARNING, Drt.Css.BADGE_ERROR};
	for (var i = 0; i < classes.length; i++)
	{
		var badge = classes[i];
		var label = new Gtk.Label(badge);
		label.get_style_context().add_class(badge);
		label.vexpand = label.hexpand = false;
		label.halign = label.valign = Gtk.Align.CENTER;
		grid.attach(label, 0, i, 1, 1);
		var button = new Gtk.Button.with_label(badge);
		button.vexpand = button.hexpand = false;
		button.halign = button.valign = Gtk.Align.CENTER;
		button.get_style_context().add_class(badge);
		grid.attach(button, 1, i, 1, 1);
	}
	window.add(grid);
	window.show_all();
	Gtk.main();
	return 0;
}

private void quit()
{
	Gtk.main_quit();
}	
	
}
