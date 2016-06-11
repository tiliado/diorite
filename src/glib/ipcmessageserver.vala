/*
 * Copyright 2014-2016 Jiří Janoušek <janousek.jiri@gmail.com>
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

public class MessageServer: Server, MessageListener
{
	private HashTable<string, HandlerAdaptor?> handlers;
	protected static bool log_comunication;
	private uint message_number = 0;
	
	public MessageServer(string name)
	{
		base(name);
		handlers = new HashTable<string, HandlerAdaptor?>(str_hash, str_equal);
		add_handler("echo", TYPE_STRING_ANY, MessageListener.echo_handler);
	}
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_MESSAGE_SERVER") == "yes";
	}
	
	public void add_handler(string message_name, string? type_string, owned MessageHandler handler)
	{
		handlers[message_name] = new HandlerAdaptor((owned) handler, type_string);
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
	
	/**
	 * Convenience method to invoke message handler from server's process.
	 */
	public Variant? send_local_message(string name, Variant? data) throws MessageError
	{
		if (log_comunication)
			debug("Local request '%s': %s", name, data != null ? data.print(false) : "NULL");
		
		var response = handle_message(name, data);
		
		if (log_comunication)
			debug("Local response: %s", response != null ? response.print(false) : "NULL");
		
		return response;
	}
	
	protected virtual Variant? handle_message(string name, Variant? data) throws MessageError
	{
		Variant? response = null;
		var adaptor = handlers[name];
		if (adaptor == null)
			throw new MessageError.UNSUPPORTED("No handler for message '%s'", name);
	
		adaptor.handle(this, data, out response);
		return response;
	}
	
	protected override bool handle(owned ByteArray request, out ByteArray response)
	{
		var bytes = ByteArray.free_to_bytes((owned) request);
		var buffer = Bytes.unref_to_data((owned) bytes);
		string? request_name = null;
		Variant? request_params = null;
		Variant? response_params = null;
		string? response_name;
		uint number;
		
		lock (message_number)
		{
			message_number++;
			number = message_number;
		}
		
		try 
		{
			if (!deserialize_message((owned) buffer, out request_name, out request_params))
				throw new MessageError.INVALID_REQUEST("Received invalid request. Cannot deserialize message.");
			
			if (log_comunication)
				debug("Request %u '%s': %s", number, request_name, request_params != null ? request_params.print(false) : "NULL");
			
			response_params = handle_message(request_name, request_params);
			response_name = RESPONSE_OK;
		}
		catch (MessageError e)
		{
			response_name = RESPONSE_ERROR;
			response_params = serialize_error(e);
		}
		
		if (log_comunication)
				debug("Response %u '%s': %s", number, response_name, response_params != null ? response_params.print(false) : "NULL");
		
		buffer = serialize_message(response_name, response_params);
		response = new ByteArray.take((owned) buffer);
		return true;
	}
}

} // namespace Diorote
