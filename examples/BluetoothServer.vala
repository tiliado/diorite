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

Drt.BluetoothConnection? connection = null;

void main(string[] args)
{
	Drt.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	var beef = "0000beef-0000-1000-1000-dead5f9b34fb";
	var service = new Drt.BluetoothService(beef, "DJ Beef", 0);
	service.incoming.connect(on_incoming);
	service.listen();
	var loop = new MainLoop();
	Timeout.add_seconds(15, () =>
	{
		service.close();
		connection = null;
		service.incoming.disconnect(on_incoming);
		return false;
	});
	loop.run();
}

void on_incoming(Drt.BluetoothService service, Drt.BluetoothConnection conn)
{
	connection = conn;
}
