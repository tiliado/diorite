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

public delegate void MessageHandler(MessageServer server, Variant? params,  out Variant? response) throws MessageError;

private class HandlerAdaptor
{
	private MessageHandler handler;
	
	public HandlerAdaptor(owned MessageHandler handler)
	{
		this.handler = (owned) handler;
	}
	
	public void handle(MessageServer server, Variant? params,  out Variant? response) throws MessageError
	{
		handler(server, params,  out response);
	}
}

public class MessageServer: Server
{
	private HashTable<string, HandlerAdaptor?> handlers;
	
	public MessageServer(string name)
	{
		base(name);
		handlers = new HashTable<string, HandlerAdaptor?>(str_hash, str_equal);
		add_handler("echo", echo_handler);
	}
	
	public void add_handler(string message_name, owned MessageHandler handler)
	{
		handlers[message_name] = new HandlerAdaptor((owned) handler);
	}
	
	public bool remove_handler(string message_name)
	{
		return handlers.remove(message_name);
	}
	
	public bool wait_for_listening(int timeout)
	{
		var client = new MessageClient(name, timeout);
		return client.wait_for_echo(timeout); 
	}
	
	public static void echo_handler(Diorite.Ipc.MessageServer server, Variant? request, out Variant? response) throws MessageError
	{
		response = request;
	}
	
	public static void check_type_str(Variant? request, string? type_str) throws MessageError
	{
		if (request == null && type_str != null)
			throw new Diorite.Ipc.MessageError.INVALID_ARGUMENTS("Invalid request type null, expected '%s'.", type_str);
		
		if (request != null)
		{
			unowned string request_type_str = request.get_type_string();
			
			if (type_str == null)
				throw new Diorite.Ipc.MessageError.INVALID_ARGUMENTS("Invalid request type '%s', expected null.", request_type_str);
			
			if (request_type_str != type_str)
				throw new Diorite.Ipc.MessageError.INVALID_ARGUMENTS("Invalid request type '%s', expected '%s'.", request_type_str, type_str);
		}
	}
	
	protected override bool handle(owned ByteArray request, out ByteArray response)
	{
		var bytes = ByteArray.free_to_bytes((owned) request);
		var buffer = Bytes.unref_to_data((owned) bytes);
		string? request_name = null;
		Variant? request_params = null;
		Variant? response_params = null;
		string? response_name;
		
		try 
		{
			if (!deserialize_message((owned) buffer, out request_name, out request_params))
				throw new MessageError.INVALID_REQUEST("Received invalid request. Cannot deserialize message.");
		
			var adaptor = handlers[request_name];
			if (adaptor == null)
				throw new MessageError.UNSUPPORTED("No handler for message '%s'", request_name);
		
			adaptor.handle(this, request_params, out response_params);
			response_name = RESPONSE_OK;
		}
		catch (MessageError e)
		{
			response_name = RESPONSE_ERROR;
			response_params = serialize_error(e);
		}
		
		buffer = serialize_message(response_name, response_params);
		response = new ByteArray.take((owned) buffer);
		return true;
	}
}

} // namespace Diorote