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

public class SocketChannel : DuplexChannel
{
	public SocketConnection connection {get; private set;}
	private uint io_condition_id;
	
	public SocketChannel(string name, SocketConnection connection)
	{
		base(name,  connection.input_stream, connection.output_stream);
		this.connection = connection;
		io_condition_id = Timeout.add(1, check_io_condition);
	}
	
	public bool can_read()
	{
		return Flags.is_set(connection.socket.condition_check(IOCondition.IN), IOCondition.IN);
	}
	
	public bool can_write()
	{
		return Flags.is_set(connection.socket.condition_check(IOCondition.OUT), IOCondition.OUT);
	}
	
	public signal void io_condition(IOCondition condition);
	
	
	private bool check_io_condition()
	{
		io_condition(connection.socket.condition_check(IOCondition.IN|IOCondition.OUT));
		return true;
	}
}

} // namespace Diorote

#endif
