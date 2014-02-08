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

public void uint32_to_bytes(ref uint8[] buffer, uint32 data, uint offset=0)
{
	var size = sizeof(uint32);
	assert(buffer.length >= offset + size);
	for(var i = 0; i < size; i ++)
		buffer[offset + i] = (uint8)((data >> ((3 - i) * 8)) & 0xFF);
}

public void uint32_from_bytes(ref uint8[] buffer, out uint32 data, uint offset=0)
{
	var size = sizeof(uint32);
	assert(buffer.length >= offset + size);
	data = 0;
	for(var i = 0; i < size; i ++)
		data += buffer[offset + i] * (1 << (3 - i) * 8);
} 

public class Client
{
	public string name {get; private set;}
	public uint timeout {get; private set;}
	private string path;
	#if WIN
	private Win32.NamedPipe pipe = Win32.FileHandle.INVALID;
	#else
	// TODO
	#endif
	
	public Client(string name, uint timeout)
	{
		this.name = name;
		this.timeout = timeout;
		#if WIN
		var user = Environment.get_user_name().replace("\\", ".");
		this.path = PIPE_FORMAT.printf(name, user);
		#else
		assert_not_reached(); // TODO
		#endif
	}
	
	public bool send(ByteArray request, out ByteArray? response) throws IOError
	{
		response = null;
		if (request.len > uint32.MAX - 8)
			return false;
		
		uint32 size = request.len;
		uint8[] size_buffer = new uint8[sizeof(uint32)];
		uint32_to_bytes(ref size_buffer, size);
		request.prepend(size_buffer);
		#if WIN
		while (true)
		{
			pipe = Win32.NamedPipe.open((Win32.String) path,
			Win32.GENERIC_READ | Win32.GENERIC_WRITE, 0,
			null, Win32.OPEN_EXISTING, 0);
			if (pipe != Win32.FileHandle.INVALID)
				break;
			
			if (Win32.get_last_error() != Win32.ERROR_PIPE_BUSY) 
				throw new IOError.CONN_FAILED("Failed to connect to pipe '%s'. %s", path, Win32.get_last_error_msg()); 
		
			if (!Win32.NamedPipe.wait((Win32.String) name, timeout))
				throw new IOError.TIMEOUT("Timeout reached for pipe '%s'. %s", path, Win32.get_last_error_msg()); 
		}
		
		try
		{
			ulong mode = Win32.PIPE_READMODE_BYTE;
			if (!pipe.set_state(ref mode, null, null) && Win32.get_last_error() != 0)
				throw new IOError.CONN_FAILED("Failed to set up pipe '%s'. %s", path, Win32.get_last_error_msg()); 
			
			uint8* data = request.data;
			unowned uint8[] cursor;
			var total_size = request.len;
			ulong bytes_written_total = 0;
			ulong bytes_written;
			do
			{
				cursor = (uint8[])(data + bytes_written_total);
				cursor.length = (int)(total_size - bytes_written_total);
				if (!pipe.write(cursor, out bytes_written))
					throw new IOError.RW_FAILED("Failed send request to pipe '%s': %s", path, Win32.get_last_error_msg());
				bytes_written_total += bytes_written;
				pipe.flush();
			}
			while (bytes_written_total < total_size);
			
			response = new ByteArray();
			uint8[MESSAGE_BUFSIZE] buffer = new uint8[MESSAGE_BUFSIZE];
			ulong bytes_read;
			uint64 bytes_read_total = 0;
			uint64 message_size = 0;
			bool result = false;
			do
			{
				result = pipe.read(buffer, out bytes_read);
				if (!result && Win32.get_last_error() != Win32.ERROR_MORE_DATA)
					throw new IOError.READ("Failed to read from pipe. %s", Win32.get_last_error_msg());
				
				string str;
				if (bytes_read_total == 0)
				{
					uint32_from_bytes(ref buffer, out message_size);
					bytes_read_total += bytes_read - sizeof(uint32);
					unowned uint8[] shorter_buffer = (uint8[])((uint8*) buffer + sizeof(uint32));
					shorter_buffer.length = (int) (buffer.length - sizeof(uint32));
					response.append(shorter_buffer);
					str = (string) buffer[sizeof(uint32):bytes_read- sizeof(uint32)];
				}
				else
				{
					response.append(buffer);
					bytes_read_total += bytes_read;
					str = (string) buffer[0:bytes_read];
				}
				
				var extra = (uint) (MESSAGE_BUFSIZE - bytes_read);
				if (extra > 0)
					response.remove_range(response.len - extra, extra);
			}
			while (bytes_read_total < message_size);
		}
		finally
		{
			pipe.close();
			pipe = Win32.NamedPipe.INVALID;
		}
		
		return (response.len > 0);
		#else
		return false;
		#endif
	}
}

} // namespace Diorote
