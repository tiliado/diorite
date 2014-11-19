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

public class Client
{
	public string name {get; private set;}
	private Channel channel;
	private uint timeout;
	
	public Client(string name, uint timeout)
	{
		this.name = name;
		this.timeout = timeout;
		channel = new Channel(name);
	}
	
	public void send(ByteArray request, out ByteArray? response) throws IOError
	{
		response = null;
		channel.connect(timeout);
		channel.write_bytes(request);
		channel.read_bytes(out response);
		channel.close();
	}
	
	public async void send_async(ByteArray request, out ByteArray response) throws IOError
	{
		var connection = channel.create_connection(null);
		
		var out_stream = new DataOutputStream(connection.output_stream);
		yield channel.write_bytes_async(out_stream, request);
		
		var in_stream = new DataInputStream(connection.input_stream);
		yield channel.read_bytes_async(in_stream, out response, timeout);
	}
}

} // namespace Diorote
