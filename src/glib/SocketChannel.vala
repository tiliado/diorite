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

#if LINUX

namespace Diorite
{

public class SocketChannel : Drt.DuplexChannel
{
	public SocketConnection connection {get; private set;}
	public bool can_read {get; private set; default = false;}
	public bool can_write {get; private set; default = false;}
	private SocketSource socket_source;
	
	public SocketChannel(string name, SocketConnection connection)
	{
		base(name,  connection.input_stream, connection.output_stream);
		this.connection = connection;
		socket_source = connection.socket.create_source(IOCondition.IN|IOCondition.OUT);
		socket_source.set_callback(on_socket_source);
		check_io_condition();
	}
	
	private void check_io_condition()
	{
		var condition = connection.socket.condition_check(IOCondition.IN|IOCondition.OUT);
		set_condition(condition);
		socket_source.attach(MainContext.@default());
	}
	
	private void set_condition(IOCondition condition)
	{
		var read = Flags.is_set(condition, IOCondition.IN);
		var write = Flags.is_set(condition, IOCondition.OUT);
		if (can_read != read)
			can_read = read;
		if (can_write != write)
			can_write = write;
	}
	
	private bool on_socket_source(Socket socket, IOCondition condition)
	{
		set_condition(condition);
		return false;
	}
}

} // namespace Diorite

#endif
