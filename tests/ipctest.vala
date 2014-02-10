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
	private bool error;
	private Diorite.Ipc.Server? bytes_server;
	private Diorite.Ipc.MessageServer? message_server;
	
	[DTest(start=8, end=1000, step=8)]
	public void test_communication_bytes(int repeat)
	{
		bytes_server = null;
		error = false;
		var thread = new Thread<void*>("server", run_bytes_server);
		bool listening = false;
		while (!listening)
		{
			Thread.yield();
			lock (error)
			{
				if (error)
					return;
			}
			
			lock (bytes_server)
			{
				if (bytes_server != null)
					listening = bytes_server.listening;
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
			client.send(request, out response);
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
	
	private void* run_bytes_server()
	{ 
		try
		{
			lock (bytes_server)
			{
				bytes_server = new Diorite.Ipc.Server("test");
			}
			bytes_server.listen();
		}
		catch (Diorite.IOError e)
		{
			expectation_failed("%s:%d:%s Server error: %s".printf(Log.FILE, Log.LINE, mark, e.message));
			bytes_server.stop();
			lock (error)
			{
				error = true;
			}
		}
		return null;
	}
	
	[DTest(start=1, end=20)]
	public void test_communication_messages(int repeat)
	{
		message_server = null;
		error = false;
		var thread = new Thread<void*>("server", run_messages_server);
		
		bool listening = false;
		while (!listening)
		{
			Thread.yield();
			lock (error)
			{
				if (error)
					return;
			}
			
			lock (message_server)
			{
				if (message_server != null)
					listening = message_server.listening;
			}
			Thread.yield();
		}
		assert(message_server != null);
		var type_sig = "(ssbynqiuxthdas)";
		var builder = new VariantBuilder(new VariantType ("as"));
		builder.add("s", "Chemotherapy");
		builder.add("s", "is");
		builder.add("s", "exhausting");
		builder.add("s", "treatment.");
		var variant = new Variant(type_sig, "hello", "world", true,
		(uchar) 1, (int16) 2, (uint16) 3, (int32) 4, (uint32) 5, (int64) 6,
		(uint64) 7, (int32) 8, (double) 8.0, builder);
		
		var client = new Diorite.Ipc.MessageClient("test", 5000);
		try
		{
			Variant response = client.send_message("echo", variant);
			
			string s1 = "";
			string s2 = "";
			bool b = false;
			uchar y = 0;
			int16 n = 0;
			uint16 q = 0;
			int32 i = 0;
			uint32 u = 0;
			int64 x = 0;
			uint64 t = 0;
			int32 h = 0;
			double d = 0.5;
			response.get(type_sig, &s1, &s2, &b, &y, &n, &q, &i, &u, &x, &t, &h, &d);
			expect(s1 == "hello");
			expect(s2 == "world");
			expect(b == true);
			expect(y == (uchar) 1);
			expect(n == (int16) 2);
			expect(q == (uint16) 3);
			expect(i == (int32) 4);
			expect(u == (uint32) 5);
			expect(x == (int64) 6);
			expect(t == (uint64) 7);
			expect(h == (int32) 8);
			expect(d == (double) 8.0);
		}
		catch(Diorite.Ipc.MessageError e)
		{
			expectation_failed("%s:%d:%s Client error: %s".printf(Log.FILE, Log.LINE, mark, e.message));
		}
		
		try
		{
			Variant response = client.send_message("do_anything", variant);
			expect(false);
		}
		catch(Diorite.Ipc.MessageError e)
		{
			expect(e is Diorite.Ipc.MessageError.UNSUPPORTED);
		}
		
		try
		{
			Variant response = client.send_message("error", variant);
			expect(false);
		}
		catch(Diorite.Ipc.MessageError e)
		{
			expect(e is Diorite.Ipc.MessageError.REMOTE_ERROR);
			if (!(e is Diorite.Ipc.MessageError.REMOTE_ERROR))
				warning("%s: %s", e.code.to_string(), e.message);
		}
	}
	
	private void* run_messages_server()
	{
		lock (message_server)
		{
			message_server = new Diorite.Ipc.MessageServer("test");
		}
		
		message_server.add_handler("echo", this, (Diorite.Ipc.MessageHandler) IpcTest.echo_handler);
		message_server.add_handler("error", this, (Diorite.Ipc.MessageHandler) IpcTest.error_handler);
		
		try
		{
			message_server.listen();
		}
		catch (Diorite.IOError e)
		{
			expectation_failed("%s:%d:%s Server error: %s".printf(Log.FILE, Log.LINE, mark, e.message));
			message_server.stop();
			lock (error)
			{
				error = true;
			}
		}
		return null;
	}
	
	private bool echo_handler(Diorite.Ipc.MessageServer server, Variant request, out Variant? response)
	{
		response = request;
		return true;
	}
	
	private bool error_handler(Diorite.Ipc.MessageServer server, Variant request, out Variant? response)
	{
		return server.create_error("error", out response);
	}
}
