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

void main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	
	var tree = new Diorite.KeyValueTree();
	tree.set_value("a", "a");
	tree.set_value("b", "b");
	tree.set_value("c.a", "c.a");
	tree.set_value("c.b", "c.b");
	tree.set_value("c.c", "c.c");
	tree.set_value("c.d.a", "c.d.a");
	tree.set_value("c.d.b", "c.d.b");
	tree.set_value("c.d.c", "c.d.c");
	tree.set_value("c.d.d", "c.d.d");
	stdout.puts("Locally filled tree\n");
	stdout.puts(tree.to_string());
	
	
	// Process 1
	// a) Provider server provides access to key-value storages
	var provider_server = new Diorite.Ipc.MessageServer("test");
	try
	{
		provider_server.start_service();
	}
	catch (Diorite.IOError e)
	{
		error("Cannot start server service %s: %s", provider_server.name, e.message);
	}
	// b) Create provider server IPC interface and add one storage provider KeyValueTree "tree"
	var storage_server = new Diorite.KeyValueStorageServer(provider_server);
	tree = new Diorite.KeyValueTree();
	storage_server.add_provider("tree", tree);
	
	// Process 2
	// a) Listener server receives "changed" signal notifications
	var listener_server = new Diorite.Ipc.MessageServer("test-listener");
	try
	{
		listener_server.start_service();
	}
	catch (Diorite.IOError e)
	{
		error("Cannot start server service %s: %s", listener_server.name, e.message);
	}
	// b) Provider client communicates with provider server
	var provider_client = new Diorite.Ipc.MessageClient("test", 15);
	assert(provider_client.wait_for_echo(10000));
	// c) Storage client communicates with interface provided by provider server
	var storage_client = new Diorite.KeyValueStorageClient(provider_client, listener_server);
	// d) Create a proxy object for a storage provider "tree"
	var proxy = storage_client.get_proxy("tree", 15);
	proxy.set_value("a", "a");
	proxy.set_value("b", "b");
	proxy.set_value("c.a", "c.a");
	proxy.set_value("c.b", "c.b");
	proxy.set_value("c.c", "c.c");
	proxy.set_value("c.d.a", "c.d.a");
	proxy.set_value("c.d.b", "c.d.b");
	proxy.set_value("c.d.c", "c.d.c");
	proxy.set_value("c.d.d", "c.d.d");
	
	stdout.puts("Remotely filled tree\n");
	stdout.puts(tree.to_string());
	
	var loop = new MainLoop();
	loop.run();
}
