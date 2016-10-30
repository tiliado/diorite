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

public class MessageChannel: BaseChannel
{	
	public MessageRouter router {get; protected set;}
	private static bool log_comunication;
	private uint last_message_id = 0;
	private GenericSet<void*> allowed_errors;
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_MESSAGE_CHANNEL") == "yes";
	}
	
	public MessageChannel(uint id, Drt.DuplexChannel channel, MessageRouter? router)
	{
		GLib.Object(id: id, channel: channel, router: router ?? new MessageRouter(null));
	}
	
	public MessageChannel.from_name(uint id, string name, MessageRouter? router, uint timeout) throws Diorite.IOError
	{
		this(id, new Diorite.SocketChannel.from_name(id, name, timeout), router);
	}

	construct
	{
		allowed_errors = new GenericSet<void*>(null, null);
		allow_error_propagation(new Diorite.MessageError.UNKNOWN("").domain);
		allow_error_propagation(new Drt.ApiError.UNKNOWN("").domain);
		
		channel.notify["closed"].connect_after(on_channel_closed);
		channel.incoming_request.connect(on_incoming_request);
		channel.start_receiving();
	}
	
	~MessageChannel()
	{
		channel.notify["closed"].disconnect(on_channel_closed);
	}
	
	public void allow_error_propagation(Quark error_quark)
	{
		allowed_errors.add(((uint) error_quark).to_pointer());
	}
	
	public bool is_error_allowed(Quark error_quark)
	{
		return allowed_errors.contains(((uint) error_quark).to_pointer());
	}
	
	private uint next_message_id()
	{
		lock (last_message_id)
		{
			uint id = last_message_id;
			if (id == uint.MAX)
				id = 1;
			else
				id++;
			last_message_id = id;
			return id;
		}
	}
	
	public Variant? send_message(string name, Variant? params=null) throws GLib.Error
	{
		var id = next_message_id();
		var request = prepare_request(id, name, params);
		var response = channel.send_request(request);
		return process_response(id, (owned) response);
	}
	
	public async Variant? send_message_async(string name, Variant? params=null) throws GLib.Error
	{
		var id = next_message_id();
		var request = prepare_request(id, name, params);
		var response = yield channel.send_request_async(request);
		return process_response(id, (owned) response);
	}
	
	private ByteArray? prepare_request(uint id, string name, Variant? params)
	{
		if (log_comunication)
			debug("Channel(%u) Request #%u: %s => %s",
				channel.id, id, name, params != null ? params.print(false) : "null");
			
		var buffer = Diorite.serialize_message(name, params, 0);
		var payload = new ByteArray.take((owned) buffer);
		return payload;
	}
		
	private Variant? process_response(uint id, owned ByteArray? data) throws GLib.Error
	{
		var bytes = ByteArray.free_to_bytes((owned) data);
		var buffer = Bytes.unref_to_data((owned) bytes);
		string? label = null;
		Variant? params = null;
		if (!Diorite.deserialize_message((owned) buffer, out label, out params, 0))
			throw new Diorite.MessageError.INVALID_RESPONSE("Server returned invalid response. Cannot deserialize message.");
		
		if (log_comunication)
			debug("Channel(%u) Response #%u: %s => %s",
				channel.id, id, label, params != null ? params.print(false) : "null");
		
		if (label == Diorite.Ipc.RESPONSE_OK)
			return params;
			
		if (label == Diorite.Ipc.RESPONSE_ERROR)
		{
			if (params == null)
				throw new Diorite.MessageError.INVALID_RESPONSE("Server returned empty error.");
				
			var e = Diorite.deserialize_error(params);
			if (e == null)
				throw new Diorite.MessageError.UNKNOWN("Server returned unknown error.");
			if (!is_error_allowed(e.domain))
				throw new Diorite.MessageError.UNKNOWN("Server returned unknown error (%s).", e.domain.to_string());
			throw e;
		}
		
		throw new Diorite.MessageError.INVALID_RESPONSE("Server returned invalid response status '%s'.", label);
	}
	
	public bool close()
	{
		var result = true;
		try
		{
			channel.close();
		}
		catch (GLib.IOError e)
		{
			warning("Failed to close channel '%s': [%d] %s", name, e.code, e.message);
			result = false;
		}
		
		if (closed == false)
			closed = true;
		return result;
	}
	
	private void on_incoming_request(uint id, owned ByteArray? data)
	{
		string? name = null;
		Variant? params = null;
		string? status = null;
		Variant? response = null;
		
		var bytes = ByteArray.free_to_bytes((owned) data);
		var buffer = Bytes.unref_to_data((owned) bytes);
		if (!Diorite.deserialize_message((owned) buffer, out name, out params, 0))
		{
			warning("Server sent invalid request. Cannot deserialize message.");
			return;
		}
		
		handle_request(name, params, out status, out response);
		buffer = Diorite.serialize_message(status, response, 0);
		var payload = new ByteArray.take((owned) buffer);
		try
		{
			channel.send_response(id, payload);
		}
		catch (GLib.Error e)
		{
			warning("Failed to send response: %s", e.message);
		}
	}
	
		
	/**
	 * Handle incoming request
	 * 
	 * This method is similar to `handle_message`, but it uses `status` and `response` to indicate
	 * success/failure instead of throwing error.
	 *  
	 * @param name        request name
	 * @param params      request parameters
	 * @param status      response status
	 * @param response    response data
	 * @return true if request has been handled successfully
	 */
	protected virtual bool handle_request(string name, Variant? params, out string status, out Variant? response)
	{
		try 
		{
			response = router.handle_message(this, name, params);
			status = Diorite.Ipc.RESPONSE_OK;
		}
		catch (GLib.Error e)
		{
			status = Diorite.Ipc.RESPONSE_ERROR;
			if (!is_error_allowed(e.domain))
				response = Diorite.serialize_error(
					new Diorite.MessageError.UNKNOWN("Server returned unknown error (%s).", e.domain.to_string()));
			else
				response = Diorite.serialize_error(e);
		}
		return true;
	}	
	
	private void on_channel_closed(GLib.Object o, ParamSpec p)
	{
		if (closed != channel.closed)
			closed = channel.closed;
	}
}

} // namespace Drt
