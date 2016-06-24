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

namespace Drt
{

public abstract class DuplexChannel
{
	private static const int MESSAGE_BUFSIZE = 512;
	public string name {get; private set;}
	public InputStream input {get; private set;}
	public OutputStream output {get; private set;}
	
	public DuplexChannel(string name, InputStream input, OutputStream output)
	{
		this.name = name;
		this.output = output;
		this.input = input;
	}
	
	public async void write_bytes_async(ByteArray bytes) throws Diorite.IOError
	{
		if (bytes.len > get_max_message_size())
			throw new Diorite.IOError.TOO_MANY_DATA("Only %s bytes can be sent.", get_max_message_size().to_string());
		
		uint8* data_ptr;
		unowned uint8[] data_buf;
		uint32 data_size;
		uint32 bytes_written;
		
		bytes_written = 0;
		uint8[] size_buffer = new uint8[sizeof(uint32)];
		Diorite.uint32_to_bytes(ref size_buffer, (uint32) bytes.len);
		data_ptr = size_buffer;
		data_size = size_buffer.length;
		do
		{
			try
			{
				data_buf = (uint8[]) (data_ptr + bytes_written);
				data_buf.length = (int)(data_size - bytes_written);
				bytes_written += (uint) yield output.write_async(data_buf);
			}
			catch (GLib.IOError e)
			{
				if (!(e is GLib.IOError.WOULD_BLOCK || e is GLib.IOError.BUSY || e is GLib.IOError.PENDING))
					throw new Diorite.IOError.READ("Failed to write header. %s", e.message);
				Idle.add(write_bytes_async.callback);
				yield;
			}
		}
		while (bytes_written < data_size);
		
		bytes_written = 0;
		data_ptr = bytes.data;
		data_size = bytes.len;
		do
		{
			try
			{
				data_buf = (uint8[]) (data_ptr + bytes_written);
				data_buf.length =  (int)(data_size - bytes_written);
				bytes_written += (uint) yield output.write_async(data_buf);
			}
			catch (GLib.IOError e)
			{
				if (!(e is GLib.IOError.WOULD_BLOCK || e is GLib.IOError.BUSY || e is GLib.IOError.PENDING))
					throw new Diorite.IOError.READ("Failed to write data. %s", e.message);
				Idle.add(write_bytes_async.callback);
				yield;
			}
		}
		while (bytes_written < data_size);
	}
	
	public async void read_bytes_async(out ByteArray bytes, uint timeout=0, owned Cancellable? cancellable=null) throws Diorite.IOError
	{
		bytes = new ByteArray();
		uint8[MESSAGE_BUFSIZE] real_buffer = new uint8[MESSAGE_BUFSIZE];
		unowned uint8[] buffer = real_buffer;
		var bytes_to_read = (int) sizeof(uint32);
		uint64 message_size = 0;
		try
		{
			buffer.length = bytes_to_read;
			var result = yield input.read_async(buffer, GLib.Priority.DEFAULT, cancellable);
			
			if (result != bytes_to_read)
				throw new Diorite.IOError.READ("Failed to read message size.");
			
			Diorite.uint32_from_bytes(buffer, out message_size);
		}
		catch (GLib.IOError e)
		{
			throw new Diorite.IOError.READ("Failed to read from socket. %s", e.message);
		}
		
		if (message_size == 0)
			throw new Diorite.IOError.READ("Empty message received.");
		
		size_t bytes_read_total = 0;
		size_t bytes_read;
		while (bytes_read_total < message_size)
		{
			try
			{
				buffer.length = int.min((int)(message_size - bytes_read_total), MESSAGE_BUFSIZE);
				bytes_read = yield input.read_async(buffer, GLib.Priority.DEFAULT, cancellable);
			}
			catch (GLib.IOError e)
			{
				throw new Diorite.IOError.READ("Failed to read from socket. %s", e.message);
			}
			
			buffer.length = (int) bytes_read;
			bytes.append(buffer);
			bytes_read_total += bytes_read;
		}
	}
	
	public static size_t get_max_message_size()
	{
		return uint32.MAX - sizeof(uint32);
	}
}

} // namespace Drt

#endif
