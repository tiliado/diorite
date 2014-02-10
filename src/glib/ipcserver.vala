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
	private Channel channel;
	private bool quit = false;
	public bool listening
	{
		get {return channel.listening;}
	}
	
	public Server(string name)
	{
		channel = new Channel(name);
	}
	
	~Server()
	{
		stop();
	}
	
	public void listen() throws IOError
	{
		Server? @ref = this; // Prevent destroying before disconnect is called
		while (!quit)
		{
			channel.create();
			while (!quit)
			{
				try
				{
					channel.listen();
					ByteArray request;
					ByteArray response;
					
					channel.read_bytes(out request);
					
					if (!handle((owned) request, out response))
						response = new ByteArray();
					
					channel.write_bytes(response);
					channel.disconnect();
					@ref = null;
				}
				catch (IOError e)
				{
					try
					{
						channel.disconnect();
					}
					catch (IOError e)
					{
						// ignored
					}
					@ref = null;
					throw e;
				}
				
			}
		}
		@ref = null;
	}
	
	public void stop()
	{
		quit = true;
	}
	
	protected virtual bool handle(owned ByteArray request, out ByteArray? response)
	{
		response = (owned) request;
		return true;
	}
}

} // namespace Diorote
