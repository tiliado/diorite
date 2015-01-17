/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Diorite.Ipc
{

public class Server
{
	private static bool log_comunication;
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_IPC_SERVER") == "yes";
	}
	
	private Channel channel;
	public bool listening
	{
		get {return channel.listening;}
	}
	
	public uint timeout {get; set;}
	public string name {get; private set;}
	private SocketService? service=null;
	
	public Server(string name, uint timeout=5000)
	{
		this.name = name;
		this.timeout = timeout;
		channel = new Channel(name);
	}
	
	public void start_service() throws IOError
	{
		service = channel.create_service();
		service.incoming.connect(on_incoming);
		service.start();
	}
	
	public void stop_service() throws IOError
	{
		if (service != null)
		{
			service.stop();
			service = null;
		}
	}
	
	public virtual signal void async_error(IOError e)
	{
		warning("Async IOError: %s", e.message);
	}
	
	private bool on_incoming(SocketConnection connection, GLib.Object? source_object)
	{
		process_connection.begin(connection, on_process_incoming_done);
		return true;
	}
	
	private void on_process_incoming_done(GLib.Object? o, AsyncResult result)
	{
		try
		{
			process_connection.end(result);
		}
		catch (IOError e)
		{
			if (log_comunication)
				debug("Connection processed with error: %s", e.message);
			async_error(e);
		}
	}
	
	private async void process_connection(SocketConnection connection) throws IOError
	{
		ByteArray request;
		var in_stream = new DataInputStream(connection.input_stream);
		yield channel.read_bytes_async(in_stream, out request, timeout);
		
		ByteArray response;
		if (!handle((owned) request, out response))
				response = new ByteArray();
		
		var out_stream = new DataOutputStream(connection.output_stream);
		yield channel.write_bytes_async(out_stream, response);
	}
	
	protected virtual bool handle(owned ByteArray request, out ByteArray response)
	{
		response = (owned) request;
		return true;
	}
}

} // namespace Diorote
