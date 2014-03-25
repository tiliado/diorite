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

Diorite.Form form;

int main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	Gtk.init(ref args);
	var window = new Gtk.Window();
	window.delete_event.connect(() => { quit(); return false;});
	window.show();
	
	var values = new HashTable<string, Variant>(str_hash, str_equal);
	values.insert("entrytype", new Variant.boolean(true));
	values.insert("shortstring", new Variant.string("Short string"));
	values.insert("longstring", new Variant.string("Very long string"));
	values.insert("address", new Variant.string("default"));
	values.insert("host", new Variant.string(""));
	values.insert("port", new Variant.string(""));
	
	form = new Diorite.Form.from_spec(values, new Variant.tuple({
		new Variant.tuple({new Variant.string("bool"), new Variant.string("entrytype"), new Variant.string("Use short string"), new Variant.strv({"shortstring"}), new Variant.strv({"longstring"})}),
		new Variant.tuple({new Variant.string("string"), new Variant.string("shortstring"), new Variant.string("Label")}),
		new Variant.tuple({new Variant.string("string"), new Variant.string("longstring")}),
		new Variant.tuple({new Variant.string("option"), new Variant.string("address:default"), new Variant.string("use default address ('localhost:9000')"), new Variant("mv", null), new Variant.strv({"host", "port"})}),
		new Variant.tuple({new Variant.string("option"), new Variant.string("address:custom"), new Variant.string("use custom address"), new Variant.strv({"host", "port"}), new Variant("mv", null)}),
		new Variant.tuple({new Variant.string("string"), new Variant.string("host"), new Variant.string("Host")}),
		new Variant.tuple({new Variant.string("string"), new Variant.string("port"), new Variant.string("Port")})
	}));
	
	form.check_toggles();
	window.add(form);
	form.show();
	Gtk.main();
	return 0;
}

private void quit()
{
	var values = form.get_values();
	foreach (var key in values.get_keys())
	{
		var val = values.get(key);
		message("'%s': %s", key, val != null ? val.print(true) : "null");
	}
	
	Gtk.main_quit();
}
