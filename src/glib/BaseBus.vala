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

public abstract class BaseBus<ChannelType, RouterType>: GLib.Object
{
	protected GLib.Object base_router;
	public RouterType router {get {return (RouterType) base_router; }}
	public uint timeout {get; set;}
	public string name {get; private set;}
	private string path;
	private SocketService? service=null;
	protected HashTable<void*, BaseChannel?> clients = null;
	uint last_client_id = 0;
	
	public BaseBus(string name, GLib.Object router, uint timeout)
	{
		this.name = name;
		this.timeout = timeout;
		this.path = Diorite.Ipc.create_path(name);
		this.base_router = router;
		clients = new HashTable<void*, BaseChannel>(direct_hash, direct_equal);
	}
	
	public void start() throws Diorite.IOError
	{
		create_service();
		service.start();
	}
	
	public ChannelType connect_channel(string name, uint timeout) throws Diorite.IOError
	{
		var id = get_next_client_id();
		var channel = (BaseChannel) GLib.Object.@new(typeof(ChannelType),
			id: id, channel: new Diorite.SocketChannel.from_name(id, name, timeout), router: base_router);
		clients[id.to_pointer()] = channel;
		return (ChannelType) channel;
	}
	
	public signal void incoming(ChannelType channel);
	
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
		var channel = (BaseChannel) GLib.Object.@new(typeof(ChannelType),
				id: id, channel: new Diorite.SocketChannel(id, path, connection, timeout), router: router);
		clients[id.to_pointer()] = channel;
		channel.notify["closed"].connect_after(on_channel_closed);
		incoming((ChannelType) channel);
		return true;
	}
	
	public void on_channel_closed(GLib.Object source, ParamSpec param)
	{
		var channel = source as BaseChannel;
		return_if_fail(channel != null);
		channel.notify["closed"].disconnect(on_channel_closed);
		clients.remove(channel.id.to_pointer());
	}
}

} // namespace Drt	
