/*
 * Copyright 2016 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt
{

public class MessageBus: GLib.Object, Diorite.MessageListener
{
	private static bool log_comunication;
	public MessageRouter? router {get; protected set;}
	public uint timeout {get; set;}
	public string name {get; private set;}
	private string path;
	private SocketService? service=null;
	protected HashTable<void*, MessageChannel?> clients = null;
	uint last_client_id = 0;
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_MESSAGE_SERVER") == "yes" || true;
	}
	
	public MessageBus(string name, MessageRouter? router, uint timeout=5000)
	{
		this.name = name;
		this.timeout = timeout;
		this.path = Diorite.Ipc.create_path(name);
		this.router = router ?? new HandlerRouter(null);
		clients = new HashTable<void*, MessageChannel?>(direct_hash, direct_equal);
	}
	
	public void start() throws Diorite.IOError
	{
		create_service();
		service.start();
	}
	
	public MessageChannel connect_channel(string name, uint timeout=500) throws Diorite.IOError
	{
		var id = get_next_client_id();
		var channel = new MessageChannel.from_name(id, name, router, timeout);
		clients[id.to_pointer()] = channel;
		return channel;
	}
	
	public virtual void add_handler(string message_name, string? type_string, owned Diorite.MessageHandler handler)
	{
		router.add_handler(message_name, type_string, (owned) handler);
	}
	
	public virtual bool remove_handler(string message_name)
	{
		return router.remove_handler(message_name);
	}
	
	/**
	 * Convenience method to invoke message handler from server's process.
	 */
	public Variant? send_local_message(string name, Variant? data) throws GLib.Error
	{
		if (log_comunication)
			debug("Local request '%s': %s", name, data != null ? data.print(false) : "NULL");
		var response = router.handle_message(this, name, data);
		if (log_comunication)
			debug("Local response: %s", response != null ? response.print(false) : "NULL");
		return response;
	}
	
	public signal void incoming(MessageChannel channel);
	
	private void create_service() throws Diorite.IOError
	{
		if (service != null)
			return;
		try
		{
			File.new_for_path(path).delete();
		}
		catch (GLib.Error e)
		{
		}
		
		var address = new UnixSocketAddress(path);
		service = new SocketService();
		SocketAddress effective_address;
		try
		{
			service.add_address(address, SocketType.STREAM, SocketProtocol.DEFAULT, null, out effective_address);
		}
		catch (GLib.Error e)
		{
			throw new Diorite.IOError.CONN_FAILED("Failed to add socket '%s'. %s", path, e.message);
		}
		service.incoming.connect(on_incoming);
	}
	
	protected uint get_next_client_id()
	{
		uint id = last_client_id;
		do
		{
			if (id == uint.MAX)
				id = 1;
			else
				id++;
		}
		while (clients.contains(id.to_pointer()));
		clients[id.to_pointer()] = null;
		last_client_id = id;
		return id;
	}
	
	private bool on_incoming(SocketConnection connection, GLib.Object? source_object)
	{
		var id = get_next_client_id();
		var channel = new MessageChannel(id, new Diorite.SocketChannel(path, connection), router);
		clients[id.to_pointer()] = channel;
		channel.notify["closed"].connect_after(on_channel_closed);
		incoming(channel);
		return true;
	}
	
	public void on_channel_closed(GLib.Object source, ParamSpec param)
	{
		var channel = source as MessageChannel;
		return_if_fail(channel != null);
		channel.notify["closed"].disconnect(on_channel_closed);
		clients.remove(channel.id.to_pointer());
	}
}

} // namespace Drt	
