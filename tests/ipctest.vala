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

using Diorite.Test;

class IpcTest: Diorite.TestCase
{
	private bool listening;
	
	[DTest(start=8, end=1000, step=8)]
	public void test_communication_bytes(int repeat)
	{
		listening = false;
		var thread = new Thread<void*>("server", run_string_server);
		bool listening = false;
		while (!listening)
		{
			Thread.yield();
			lock(this.listening)
			{
				listening = this.listening;
			}
			Thread.yield();
		}
		
		var client = new Diorite.Ipc.Client("test", 5000);
		var request = new ByteArray.sized(repeat);
		for (var i = 0; i < repeat; i++)
			request.append({1});
		ByteArray? response;
		try
		{
			assert(client.send(request, out response));
			assert(repeat == response.len);
			var orig_mark = mark;
			for (var i = 0; i < repeat; i++)
			{
				mark = "%s:i%d".printf(orig_mark, i);
				expect(response.data[i] == (uint8) 1);
			}
			mark = orig_mark;
		}
		catch (Diorite.IOError e)
		{
			expectation_failed("%s:%d:%s Client error: %s".printf(Log.FILE, Log.LINE, mark, e.message));
		}
	}
	
	private void* run_string_server()
	{
		var server = new Diorite.Ipc.Server("test");
		try
		{
			lock(listening)
			{
				listening = true;
			}
			server.listen();
		}
		catch (Diorite.IOError e)
		{
			expectation_failed("%s:%d:%s Server error: %s".printf(Log.FILE, Log.LINE, mark, e.message));
		}
		return null;
	}
}
