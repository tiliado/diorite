/*
 * Copyright 2016-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt {

/**
 * RPC Bus with associated {@link RpcRouter} and multiple instances of {@link RpcChannel}.
 */
public class RpcBus: GLib.Object {
	public RpcRouter router {get; construct;}
	public RpcLocalConnection local {get; private set;}
	public uint timeout {get; set;}
	public string name {get; construct;}
	private string path;
	private SocketService? service = null;
	protected HashTable<void*, RpcChannel?> clients = null;
	uint last_client_id = 0;
	protected static bool log_comunication;
	
	static construct {
		log_comunication = Environment.get_variable("DIORITE_LOG_API_BUS_BUS") == "yes";
	}
	
	/**
	 * Create new RpcBus.
	 * 
	 * @param name       Bus name.
	 * @param router     RPC router defining callback for RPC calls.
	 * @param timeout    Timeout for requests.
	 */
	public RpcBus(string name, RpcRouter router, uint timeout) {
		GLib.Object(router: router, timeout: timeout, name: name);
		this.path = Rpc.create_path(name);
		clients = new HashTable<void*, RpcChannel>(direct_hash, direct_equal);
		local = new RpcLocalConnection(0, router); 
	}
	
	/**
	 * Emitted when there is a new incoming connection.
	 * 
	 * @param channel    New RpcChannel.
	 */
	public signal void incoming(RpcChannel channel);
	
	/**
	 * Start RPC Bus.
	 * 
	 * @throws IOError on failure.
	 */
	public void start() throws IOError {
		create_service();
		service.start();
	}
	
	/**
	 * Add new channel to the bus.
	 * 
	 * @param name       Channel name.
	 * @param timeout    Request timeout.
	 * @return New RpcChannel.
	 * @throws IOError on failure.
	 */
	public RpcChannel connect_channel(string name, uint timeout) throws IOError	{
		var id = get_next_client_id();
		var channel = (RpcChannel) GLib.Object.@new(typeof(RpcChannel),
			id: id, channel: new SocketChannel.from_name(id, name, timeout), router: router);
		clients[id.to_pointer()] = channel;
		return channel;
	}
	
	/**
	 * Add new channel from a socket connection.
	 * 
	 * @param socket    Socket connection
	 * @param timeout   Request timeout.
	 * @return New RpcChannel.
	 * @throws IOError on failure.
	 */
	public RpcChannel connect_channel_socket(Socket socket, uint timeout) throws IOError	{
		var id = get_next_client_id();
		var channel = (RpcChannel) GLib.Object.@new(typeof(RpcChannel),
			id: id, channel: new SocketChannel.from_socket(id, socket, timeout), router: router);
		clients[id.to_pointer()] = channel;
		return channel;
	}
	
	/**
	 * Create new socket service for this bus.
	 * 
	 * @throws IOError on failure.
	 */
	private void create_service() throws IOError {
		if (service != null) {
			return;
		}
		try	{
			File.new_for_path(path).delete();
		} catch (GLib.Error e) 	{
		}
		
		var address = new UnixSocketAddress(path);
		service = new SocketService();
		SocketAddress effective_address;
		try	{
			service.add_address(address, SocketType.STREAM, SocketProtocol.DEFAULT, null, out effective_address);
		} catch (GLib.Error e) {
			throw new IOError.CONN_FAILED("Failed to add socket '%s'. %s", path, e.message);
		}
		service.incoming.connect(on_incoming);
	}
	
	/**
	 * Get id for the next client.
	 * 
	 * @return The next client id.
	 */
	protected uint get_next_client_id() {
		uint id = last_client_id;
		do {
			if (id == uint.MAX) {
				id = 1;
			} else {
				id++;
			}
		}
		while (clients.contains(id.to_pointer()));
		clients[id.to_pointer()] = null;
		last_client_id = id;
		return id;
	}
	
	/**
	 * Called when there is a new incoming client socket connection.
	 * 
	 * @param connection       Incoming socket connection.
	 * @param source_object    The source of the connection.
	 */
	private bool on_incoming(SocketConnection connection, GLib.Object? source_object) {
		var id = get_next_client_id();
		var channel = (RpcChannel) GLib.Object.@new(typeof(RpcChannel),
				id: id, channel: new SocketChannel(id, path, connection, timeout), router: router);
		clients[id.to_pointer()] = channel;
		channel.notify["closed"].connect_after(on_channel_closed);
		incoming(channel);
		return true;
	}
	
	/**
	 * Called when channel is closed.
	 * 
	 * @param source   RpcChannel.
	 * @param param    Param spec.
	 */
	public void on_channel_closed(GLib.Object source, ParamSpec param) {
		var channel = source as RpcChannel;
		return_if_fail(channel != null);
		channel.notify["closed"].disconnect(on_channel_closed);
		clients.remove(channel.id.to_pointer());
	}
}

} // namespace Drt
