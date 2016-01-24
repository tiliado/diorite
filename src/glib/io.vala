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

namespace Diorite
{

public GLib.InputStream? input_stream_from_pipe(int fd)
{
	if (fd < 0)
		return null;
	
	#if LINUX
	return new UnixInputStream(fd, true);
	#elif WIN
	return new Win32InputStream((void*) fd, true);
	#else
	UNSUPPORTED PLATFORM!
	#endif
}

public GLib.OutputStream? output_stream_from_pipe(int fd)
{
	if (fd < 0)
		return null;
	
	#if LINUX
	return new UnixOutputStream(fd, true);
	#elif WIN
	return new Win32OutputStream((void*) fd, true);
	#else
	UNSUPPORTED PLATFORM!
	#endif
}

public static SocketService create_socket_service(string path) throws IOError
{
	Posix.unlink(path);
	var address = new UnixSocketAddress(path);
	var service = new SocketService();
	SocketAddress effective_address;
	try
	{
		service.add_address(address, SocketType.STREAM, SocketProtocol.DEFAULT, null, out effective_address);
	}
	catch (GLib.Error e)
	{
		throw new IOError.CONN_FAILED("Failed to add socket '%s'. %s", path, e.message);
	}
	return service;
}

public static SocketConnection create_socket_connection(string path, Cancellable? cancellable=null) throws IOError
{
	try
	{
		var address = new UnixSocketAddress(path);
		var socket =  new Socket(SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
		var connection = SocketConnection.factory_create_connection(socket);
		connection.connect(address, cancellable);
		return connection;
	}
	catch (GLib.Error e)
	{
		throw new IOError.CONN_FAILED("Failed to connect to socket '%s'. %s", path, e.message);
	}
}

} // namespace Diorite
