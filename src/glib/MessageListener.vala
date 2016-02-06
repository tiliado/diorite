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

namespace Diorite
{

public delegate Variant? MessageHandler(GLib.Object source, Variant? params) throws MessageError;

public errordomain MessageError
{
	REMOTE_ERROR,
	UNSUPPORTED,
	IOERROR,
	UNKNOWN,
	INVALID_RESPONSE,
	INVALID_REQUEST,
	INVALID_ARGUMENTS,
	NOT_READY;
}

public interface MessageListener : GLib.Object
{
	public static Variant? echo_handler(GLib.Object source, Variant? request) throws MessageError
	{
		return request;
	}
	
	public abstract void add_handler(string message_name, owned MessageHandler handler);
	
	public abstract bool remove_handler(string message_name);
}

public class HandlerAdaptor
{
	private MessageHandler handler;
	
	public HandlerAdaptor(owned MessageHandler handler)
	{
		this.handler = (owned) handler;
	}
	
	public void handle(GLib.Object source, Variant? params,  out Variant? response) throws MessageError
	{
		response = handler(source, params);
	}
}

} // namespace Diorite
