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


int main(string[] args)
{
	Drt.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Gtk.init(ref args);
	Gtk.Settings.get_default().gtk_enable_animations = true;
	var window = new Gtk.Window();
	window.delete_event.connect(() => { quit(); return false;});
	window.show();
	var label = new Gtk.Label("THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS AS IS");
	label.margin = 5;
	label.show();
	var slide_in = new Drt.SlideInRevealer();
	slide_in.show();
	slide_in.add(label);
	var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
	vbox.pack_start(slide_in, false, false, 0);
	var text = new Gtk.TextView();
	text.show();
	vbox.pack_start(text, true, true, 0);
	window.add(vbox);
	vbox.show();
	Gtk.main();
	return 0;
}

private void quit()
{
	Gtk.main_quit();
}
