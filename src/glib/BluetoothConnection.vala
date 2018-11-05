/*
 * Copyright 2016 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt
{

public class BluetoothConnection: GLib.Object, GLib.FileDescriptorBased
{
	public string device {get; private set;}
	public int fd {get; private set;}
	public OutputStream output {get; private set;}
	public InputStream input {get; private set;}
	private GLib.Socket socket;

	public BluetoothConnection(GLib.Socket socket, string device)
	{
		base();
		this.device = device;
		this.socket = socket;
		this.fd = socket.fd;
		output = new UnixOutputStream(fd, true);
		input = new UnixInputStream(fd, true);
	}

	public BluetoothConnection.from_fd(int fd, string device) throws GLib.Error
	{
		this(new Socket.from_fd(fd), device);
	}

	~BluetoothConnection()
	{
		try
		{
			close();
		}
		catch (GLib.Error e)
		{
		}
	}

	public int get_fd()
	{
		return fd;
	}

	public void close() throws GLib.IOError
	{
		try
		{
			if(!socket.is_closed())
				socket.close();
		}
		catch (GLib.Error e)
		{
			throw ((GLib.IOError) e);
		}
	}
}

} // namespace Drt
