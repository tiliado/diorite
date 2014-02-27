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

#if WIN
using Win32;
#endif

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

#if LINUX
[CCode(cheader_filename="socket.h")]
private extern int socket_connect(int fd, string path);
[CCode(cheader_filename="socket.h")]
private extern int socket_bind(int fd, string path);
[CCode(cheader_filename="socket.h")]
private extern int socket_accept(int fd);
#endif

public class Channel
{
	private string name;
	private string path;
	private bool _listening = false; 
	#if WIN
	private Handle pipe = INVALID_HANDLE_VALUE;
	private Overlapped? overlapped = null;
	private Handle[] events;
	#else
	private int local_socket = -1;
	private int remote_socket = -1;
	#endif
	private bool connected
	{
		get
		{
			#if WIN
			return pipe != INVALID_HANDLE_VALUE;
			#else
			return local_socket > -1;
			#endif
		}
	}
	
	public bool listening
	{
		get
		{
			return _listening;
		}
	}
	
	public Channel(string name)
	{
		this.name = name;
		this.path = create_path(name);
	}
	
	public void create()  throws IOError
	{
		#if WIN
		overlapped = {};
		events = {CreateEvent(null, true, false, null), CreateEvent(null, true, false, null)};
        if (((void*) events[0]) == null || ((void*) events[1]) == null)
			throw new IOError.CONN_FAILED("Failed to create event for pipe '%s'. %s", path, GetLastErrorMsg());
		
		overlapped.hEvent = events[1];
		pipe = CreateNamedPipe((String) path,
			PIPE_ACCESS_DUPLEX | FILE_FLAG_OVERLAPPED | FILE_FLAG_FIRST_PIPE_INSTANCE,
			PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT, 
			PIPE_UNLIMITED_INSTANCES, PIPE_BUFSIZE, PIPE_BUFSIZE, 0, null
		);
		if (pipe == INVALID_HANDLE_VALUE)
			throw new IOError.CONN_FAILED("Failed to create pipe '%s'. %s", path, GetLastErrorMsg());
		#else
		local_socket = Posix.socket(Posix.AF_UNIX, Posix.SOCK_STREAM, 0);
		if (local_socket < 0)
			throw new IOError.CONN_FAILED("Failed to create socket '%s'. %s", path, Posix.get_last_error_msg());
		Posix.unlink(path);
		var result = socket_bind(local_socket, path);
		if (result < 0)
		{
			close();
			throw new IOError.CONN_FAILED("Failed to bind socket '%s'. %s", path, Posix.get_last_error_msg());
		}
		#endif
	}
	
	#if WIN
	private void wait(ulong miliseconds=0) throws IOError
	{
		
		var index = WaitForMultipleObjects(events, false, miliseconds == 0 ? INFINITE : miliseconds);
		assert(index - WAIT_OBJECT_0 >= 0 && index - WAIT_OBJECT_0 < 2);
		index -= WAIT_OBJECT_0;
		if (index == 0)
			throw new IOError.OP_FAILED("Waiting for pipe '%s' canceled.", path); // stop() called
	}
	#endif
	
	public void listen() throws IOError
	{
		check_connected();
		try
		{
			#if WIN
			_listening = true;
			
			// Overlapped ConnectNamedPipe should return false
			if (ConnectNamedPipe(pipe, overlapped))
			{
				close();
				throw new IOError.CONN_FAILED("Failed to connect pipe '%s'. %s", path, GetLastErrorMsg());
			}
			
			switch (GetLastError())
			{
			case ERROR_IO_PENDING:
					wait(); // wait for connection
				break;
			case ERROR_PIPE_CONNECTED: 
				// connected
				break;
			default:
				throw new IOError.CONN_FAILED("Failed to connect pipe '%s'. %s", path, GetLastErrorMsg());
			}
			#else
			var result = Posix.listen(local_socket, 5);
			if (result < 0)
			{
				close();
				throw new IOError.CONN_FAILED("Failed to listen on socket '%s'. %s", path, Posix.get_last_error_msg());
			}
			
			_listening = true;
			
			remote_socket = socket_accept(local_socket);
			if (remote_socket < 0)
			{
				close();
				throw new IOError.CONN_FAILED("Failed to accept on socket '%s'. %s", path, Posix.get_last_error_msg());
			}
			#endif
		}
		finally
		{
			_listening = false;
		}
	}
	
	public void disconnect() throws IOError
	{
		check_connected();
		#if WIN
		DisconnectNamedPipe(pipe);
		#else
		Posix.close(remote_socket);
		remote_socket = -1;
		#endif
	}
	
	public void connect(uint timeout) throws IOError
	{
		#if WIN
		while (true)
		{
			pipe = CreateFile((String) path,
				GENERIC_READ | GENERIC_WRITE, 0,
				null, OPEN_EXISTING, 0
			);
			if (pipe != INVALID_HANDLE_VALUE)
				break;
			
			if (GetLastError() != ERROR_PIPE_BUSY) 
				throw new IOError.CONN_FAILED("Failed to connect to pipe '%s'. %s", path, GetLastErrorMsg()); 
		
			if (!WaitNamedPipe((String) name, timeout))
				throw new IOError.TIMEOUT("Timeout reached for pipe '%s'. %s", path, GetLastErrorMsg()); 
		}
		
		ulong mode = PIPE_READMODE_BYTE;
		if (!SetNamedPipeHandleState(pipe, ref mode, null, null) && GetLastError() != 0)
		{
			CloseHandle(pipe);
			pipe = INVALID_HANDLE_VALUE;
			throw new IOError.CONN_FAILED("Failed to set up pipe '%s'. %s", path, GetLastErrorMsg()); 
		}
		#else
		local_socket = Posix.socket(Posix.AF_UNIX, Posix.SOCK_STREAM, 0);
		if (local_socket < 0)
			throw new IOError.CONN_FAILED("Failed to create socket '%s'. %s", path, Posix.get_last_error_msg());
		var result = socket_connect(local_socket, path);
		if (result < 0)
		{
			close();
			throw new IOError.CONN_FAILED("Failed to connect to '%s'. %s", path, Posix.get_last_error_msg());
		}
		#endif
	}
	
	public void write_data(owned uint8[] data) throws IOError
	{
		var bytes = new ByteArray.take((owned) data);
		write_bytes(bytes);
	}
	
	public void stop() throws IOError
	{
		_listening = false;
		#if WIN
		if (!SetEvent(events[0]))
			throw new IOError.OP_FAILED("Failed to cancel io on pipe '%s'. %s", path, GetLastErrorMsg());
		#else
		if (Posix.shutdown(local_socket, 2) < 0)
			throw new IOError.CONN_FAILED("Failed to cancel io on socket '%s'. %s", path, Posix.get_last_error_msg());
		#endif
	}
	
	public void close()
	{
		#if WIN
		if (connected)
		{
			CloseHandle(pipe);
			pipe = INVALID_HANDLE_VALUE;
		}
		#else
		if (local_socket >= 0)
		{
			Posix.close(local_socket);
			local_socket = -1;
		}
		if (remote_socket >= 0)
		{
			Posix.close(remote_socket);
			remote_socket = -1;
		}
		#endif
	}
	
	public void flush() throws IOError
	{
		check_connected();
		#if WIN
		FlushFileBuffers(pipe);
		#endif
	}
	
	protected void write(uint8* buffer, int len, out ulong bytes_written) throws IOError
	{
		bytes_written = 0;
		#if WIN
		unowned uint8[] data = (uint8[]) buffer;
		data.length = len;
		if (!WriteFile(pipe, data, out bytes_written))
		{
			if (GetLastError() == ERROR_IO_PENDING)
			{
				wait(); // wait for reading
				if (!GetOverlappedResult(pipe, overlapped, out bytes_written, false) || bytes_written == 0)
					throw new IOError.WRITE("Failed to read overlapped result of pipe. %s", GetLastErrorMsg());
				
				if (!WriteFile(pipe, data, out bytes_written))
				{
					close();
					throw new IOError.WRITE("Failed write to pipe '%s': %s", path, GetLastErrorMsg());
				}
			}
			else
			{
				close();
				throw new IOError.WRITE("Failed write to pipe '%s': %s", path, GetLastErrorMsg());
			}
		}
		#else
		var fd = remote_socket >= 0 ? remote_socket : local_socket;
		var result = Posix.write(fd, (void*) buffer, len);
		if (result < 0)
		{
			close();
			throw new IOError.WRITE("Failed write to socket '%s': %s", path, Posix.get_last_error_msg());
		}
		bytes_written = (ulong) result;
		#endif
		flush();
	}
	
	public void write_bytes(ByteArray bytes) throws IOError
	{
		check_connected();
		if (bytes.len > get_max_message_size())
			throw new IOError.TOO_MANY_DATA("Only %s bytes can be sent.", get_max_message_size().to_string());
		
		uint32 size = bytes.len;
		uint8[] size_buffer = new uint8[sizeof(uint32)];
		uint32_to_bytes(ref size_buffer, size);
		bytes.prepend(size_buffer);
		
		uint8* data = bytes.data;
		var total_size = bytes.len;
		ulong bytes_written_total = 0;
		ulong bytes_written;
		do
		{
			write(data + bytes_written_total, int.min(MESSAGE_BUFSIZE, (int)(total_size - bytes_written_total)), out bytes_written);
			bytes_written_total += bytes_written;
		}
		while (bytes_written_total < total_size);
	}
	
	public void read_data(out uint8[] data) throws IOError
	{
		ByteArray bytes;
		read_bytes(out bytes);
		data = (owned) bytes.data;
	}
	
	public void read_bytes(out ByteArray bytes) throws IOError
	{
		check_connected();
		bytes = new ByteArray();
		uint8[MESSAGE_BUFSIZE] buffer = new uint8[MESSAGE_BUFSIZE];
		ulong bytes_read;
		uint64 bytes_read_total = 0;
		uint64 message_size = 0;
		do
		{
			read(buffer, out bytes_read);
			if (bytes_read_total == 0)
			{
				uint32_from_bytes(ref buffer, out message_size);
				bytes_read_total += bytes_read - sizeof(uint32);
				unowned uint8[] shorter_buffer = (uint8[])((uint8*) buffer + sizeof(uint32));
				shorter_buffer.length = (int) (buffer.length - sizeof(uint32));
				bytes.append(shorter_buffer);
			}
			else
			{
				bytes.append(buffer);
				bytes_read_total += bytes_read;
			}
			
			var extra = (uint) (MESSAGE_BUFSIZE - bytes_read);
			if (extra > 0)
				bytes.remove_range(bytes.len - extra, extra);
		}
		while (bytes_read_total < message_size);
	}
	
	protected void read(uint8[] buffer, out ulong bytes_read) throws IOError
	{
		bytes_read = 0;
		#if WIN
		var result = ReadFile(pipe, buffer, out bytes_read);
		if (!result && GetLastError() != ERROR_MORE_DATA)
		{
			if (GetLastError() == ERROR_IO_PENDING)
			{
				wait(); // wait for reading
				if (!GetOverlappedResult(pipe, overlapped, out bytes_read, false) || bytes_read == 0)
					throw new IOError.READ("Failed to read overlapped result of pipe. %s", GetLastErrorMsg());
				
				result = ReadFile(pipe, buffer, out bytes_read);
				if (!result && GetLastError() != ERROR_MORE_DATA)
				{
					close();
					throw new IOError.READ("Failed to read from pipe. %s", GetLastErrorMsg());
				}
			}
			else if(GetLastError() != ERROR_MORE_DATA)
			{
				close();
				throw new IOError.READ("Failed to read from pipe. %s", GetLastErrorMsg());
			}
		}
		#else
		var fd = remote_socket >= 0 ? remote_socket : local_socket;
		var result = Posix.read(fd, (void*) buffer, buffer.length);
		if (result < 0)
		{
			close();
			throw new IOError.READ("Failed to read from socket. %s", Posix.get_last_error_msg());
		}
		bytes_read = (ulong) result;
		#endif
	}
	
	protected void check_connected() throws IOError
	{
		if (!connected)
			throw new IOError.NOT_CONNECTED("Not connected.");
	}
	
	public static size_t get_max_message_size()
	{
		return uint32.MAX - sizeof(uint32);
	}
}

} // namespace Diorote

#if LINUX
namespace Posix
{
	
private string get_last_error_msg()
{
	var last_error = Posix.errno;
	return "Error %d: %s".printf(last_error, Posix.strerror(last_error));
}

} // namespace Posix
#endif
