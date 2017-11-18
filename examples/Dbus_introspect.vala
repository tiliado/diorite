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
	var loop = new MainLoop();
	introspect.begin((o, res) => {
		try {
			introspect.end(res);
		} catch (GLib.Error e) {
			critical("Introspect error: %s", e.message);
		}		
		loop.quit();
	});
	loop.run();
}

async void introspect() throws GLib.Error {
	var bus = yield Bus.get(BusType.SESSION, null);
	var xml = yield Drt.Dbus.introspect_xml(bus, "org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop");
	stdout.printf("%s\n", xml);
	var meta = yield Drt.Dbus.introspect(bus, "org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop");
	assert(meta.has_interface("org.freedesktop.portal.OpenURI"));
	assert(meta.has_method("org.freedesktop.portal.OpenURI", "OpenURI"));
	assert(meta.has_interface("org.freedesktop.portal.ProxyResolver"));
	assert(meta.has_method("org.freedesktop.portal.ProxyResolver", "Lookup"));
	assert(!meta.has_method("org.freedesktop.portal.ProxyResolver", "LookupProxy"));
	assert(!meta.has_method("org.freedesktop.portal.ProxyResolvers", "Lookup"));
	yield Drt.Flatpak.check_desktop_portal_available();
}
