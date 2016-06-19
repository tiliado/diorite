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

public interface MessageRouter : GLib.Object
{
	public abstract void add_handler(string message_name, string? type_string, owned Diorite.MessageHandler handler);
	
	public abstract bool remove_handler(string message_name);
	
	public abstract Variant? handle_message(string name, Variant? data) throws GLib.Error;
	
}

public class HandlerRouter: GLib.Object, MessageRouter
{
	protected HashTable<string, Diorite.HandlerAdaptor?>? handlers;
	
	public HandlerRouter(HashTable<string, Diorite.HandlerAdaptor?>? handlers)
	{
		this.handlers = handlers != null ? handlers : new HashTable<string, Diorite.HandlerAdaptor?>(str_hash, str_equal);
		add_handler("echo", Diorite.TYPE_STRING_ANY, Diorite.MessageListener.echo_handler);
	}
	
	/**
	 * Handle incoming request message
	 * 
	 * @param name    request name
	 * @param data    request parameters
	 * @return response data
	 * @throw error on failure
	 */
	public virtual Variant? handle_message(string name, Variant? data) throws GLib.Error
	{
		if (handlers == null)
			throw new Diorite.MessageError.UNSUPPORTED("This message channel doesn't support requests.");
			
		Variant? response = null;
		var adaptor = handlers[name];
		if (adaptor == null)
			throw new Diorite.MessageError.UNSUPPORTED("No handler for message '%s'", name);
	
		adaptor.handle(this, data, out response);
		return response;
	}
	
	public void add_handler(string message_name, string? type_string, owned Diorite.MessageHandler handler)
	{
		handlers[message_name] = new Diorite.HandlerAdaptor((owned) handler, type_string);
	}
	
	public bool remove_handler(string message_name)
	{
		return handlers.remove(message_name);
	}
}

} // namespace Drt
