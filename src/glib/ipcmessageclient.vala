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

public errordomain MessageError
{
	REMOTE_ERROR,
	UNSUPPORTED,
	IOERROR,
	UNKNOWN,
	INVALID_RESPONSE,
	INVALID_REQUEST,
	INVALID_ARGUMENTS;
}

public class MessageClient: Client
{
	public MessageClient(string name, uint timeout)
	{
		base(name, timeout);
	}
	
	public Variant send_message(string name, Variant params) throws MessageError
	{
		var buffer = serialize_message(name, params);
		var request = new ByteArray.take((owned) buffer);
		ByteArray? response = null;
		string? response_status = null;
		Variant? response_params;
		
		try
		{
			send(request, out response);
			var bytes = ByteArray.free_to_bytes((owned) response);
			buffer = Bytes.unref_to_data((owned) bytes);
			if (!deserialize_message((owned) buffer, out response_status, out response_params))
				throw new MessageError.INVALID_RESPONSE("Server returned invalid response. Cannot deserialize message.");

			if (response_status == RESPONSE_OK)
				return response_params;
			
			if (response_status == RESPONSE_ERROR)
			{
				var e = deserialize_error(response_params);
				if (e is MessageError)
				{
					MessageError e2 = (MessageError) e;
					throw e2;
				}
				
				throw new MessageError.INVALID_RESPONSE("Server returned invalid error: %s", e.message);
			}
			
			throw new MessageError.INVALID_RESPONSE("Server returned invalid response status '%s'.", response_status);
		}
		catch (IOError e)
		{
			throw new MessageError.IOERROR("%s", e.message);
		}
	}
	
	/**
	 * @param timeout miliseconds
	 */
	public bool wait_for_echo(int timeout)
	{
		int sleep = 10000;
		int attempts = timeout * 1000 / sleep;
		var message = new Variant.string("HELLO");
		while (attempts-- > 0)
		{
			try
			{
				if (send_message("echo", message).equal(message))
					return true;
				
				Thread.usleep(sleep);
			}
			catch(MessageError e) {}
		}
		return false;
	}
}

} // namespace Diorote
