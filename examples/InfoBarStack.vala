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

int counter;
Drt.InfoBarStack stack;

int main(string[] args)
{
	Drt.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Gtk.init(ref args);
	Gtk.Settings.get_default().gtk_enable_animations = true;
	var window = new Gtk.Window();
	window.delete_event.connect(() => { quit(); return false;});
	window.show();
	stack = new Drt.InfoBarStack();
	stack.show();
	var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
	vbox.pack_start(stack, false, false, 0);
	var text = new Gtk.TextView();
	text.show();
	vbox.pack_start(text, true, true, 0);
	window.add(vbox);
	vbox.show();
	Timeout.add_seconds(1, add_info_bar);
	Gtk.main();
	return 0;
}

private bool add_info_bar()
{
	var info_bar = new Gtk.InfoBar();
	info_bar.message_type = (Gtk.MessageType) (++counter % 5);
	var label = new Gtk.Label("Infobar %d: %s".printf(counter, info_bar.message_type.to_string()));
	label.margin = 5;
	label.show();
	info_bar.get_content_area().add(label);
	info_bar.show_close_button = true;
	info_bar.response.connect((w, r) => {stack.remove(w);});
	stack.add(info_bar);
	return counter < 5;
}

private void quit()
{
	Gtk.main_quit();
}
