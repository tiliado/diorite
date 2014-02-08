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
	public string name {get; private set;}
	private string path;
	#if WIN
	private Win32.NamedPipe pipe = Win32.NamedPipe.INVALID;
	#else
	// TODO
	#endif
	
	public Server(string name)
	{
		this.name = name;
		#if WIN
		var user = Environment.get_user_name().replace("\\", ".");
		this.path = PIPE_FORMAT.printf(name, user);
		#else
		assert_not_reached(); // TODO
		#endif
	}
	
	public void listen() throws IOError
	{
		#if WIN
		while (true)
		{
			pipe = Win32.NamedPipe.create((Win32.String) path,
			Win32.PIPE_ACCESS_DUPLEX,
			Win32.PIPE_TYPE_BYTE | Win32.PIPE_READMODE_BYTE | Win32.PIPE_WAIT, 
			Win32.PIPE_UNLIMITED_INSTANCES, PIPE_BUFSIZE, PIPE_BUFSIZE, 0, null);
			if (pipe == Win32.Handle.INVALID)
				throw new IOError.CONN_FAILED("Failed to create pipe '%s'. %s", path, Win32.get_last_error_msg());
			
			try
			{
				while (true)
				{
					if (!pipe.connect() && Win32.get_last_error() != Win32.ERROR_PIPE_CONNECTED)
						throw new IOError.CONN_FAILED("Failed to connect pipe '%s'. %s", path, Win32.get_last_error_msg());
					
					var request = new ByteArray();
					uint8[MESSAGE_BUFSIZE] buffer = new uint8[MESSAGE_BUFSIZE];
					ulong bytes_read;
					uint64 bytes_read_total = 0;
					uint64 request_size = 0;
					bool result = false;
					do
					{
						result = pipe.read(buffer, out bytes_read);
						if (!result && Win32.get_last_error() != Win32.ERROR_MORE_DATA)
							throw new IOError.READ("Failed to read from pipe. %s", Win32.get_last_error_msg());
						
						string str;
						if (bytes_read_total == 0)
						{
							uint32_from_bytes(ref buffer, out request_size);
							bytes_read_total += bytes_read - sizeof(uint32);
							unowned uint8[] shorter_buffer = (uint8[])((uint8*) buffer + sizeof(uint32));
							shorter_buffer.length = (int) (buffer.length - sizeof(uint32));
							request.append(shorter_buffer);
							str = (string) buffer[sizeof(uint32):bytes_read- sizeof(uint32)];
							
						}
						else
						{
							request.append(buffer);
							bytes_read_total += bytes_read;
							str = (string) buffer[0:bytes_read];
						}
						
						var extra = (uint) (MESSAGE_BUFSIZE - bytes_read);
						if (extra > 0)
							request.remove_range(request.len - extra, extra);
					}
					while (bytes_read_total < request_size);
					
					ByteArray response;
					
					if (!handle((owned) request, out response))
						response = new ByteArray();
					
					uint32 size = response.len;
					uint8[] size_buffer = new uint8[sizeof(uint32)];
					uint32_to_bytes(ref size_buffer, size);
					response.prepend(size_buffer);
					
					uint8* data = response.data;
					unowned uint8[] cursor;
					var total_size = response.len;
					ulong bytes_written_total = 0;
					ulong bytes_written;
					do
					{
						cursor = (uint8[])(data + bytes_written_total);
						cursor.length = (int)(total_size - bytes_written_total);
						if (!pipe.write(cursor, out bytes_written))
							throw new IOError.WRITE("Failed to write to pipe. %s", Win32.get_last_error_msg());
						bytes_written_total += bytes_written;
						pipe.flush();
					}
					while (bytes_written_total < total_size);
					pipe.disconnect();
				}
			}
			finally
			{
				pipe.close();
				pipe = Win32.NamedPipe.INVALID;
			}
		}
		#else
		assert_not_reached(); // TODO
		#endif
	}
	
	protected virtual bool handle(owned ByteArray request, out ByteArray? response)
	{
		response = (owned) request;
		return true;
	}
}

} // namespace Diorote
