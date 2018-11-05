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
 *
 * Tests are under public domain because they might contain useful sample code.
 */
#if FIXME
namespace Drt {

public class KeyValueProxyTest: KeyValueStorageTest {
    private KeyValueTree tree;
    private KeyValueStorageClient storage_client;
    private KeyValueStorageServer storage_server;

    public override void set_up() {
        tree = new KeyValueTree();
        var listener_server = new Ipc.MessageServer("test-listener");
        try {
            listener_server.start_service();
        } catch (Drt.IOError e) {
            fail("Cannot start server service %s: %s", listener_server.name, e.message);
        }
        var provider_server = new Ipc.MessageServer("test");
        try {
            provider_server.start_service();
        } catch (Drt.IOError e) {
            fail("Cannot start server service %s: %s", provider_server.name, e.message);
        }
        var provider_client = new Ipc.MessageClient("test", 15);
        assert(provider_client.wait_for_echo(10000), "");
        storage_server = new KeyValueStorageServer(provider_server);
        storage_server.add_provider("tree", tree);
        storage_client = new KeyValueStorageClient(provider_client, listener_server);
        var proxy = storage_client.get_proxy("tree", 15);
        storage = proxy;
    }

    public override void tear_down() {
        tree = null;
        storage = null;
        storage_client = null;
        storage_server = null;
    }
}

} // namespace Drt
#endif
