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

public class BluetoothService
{
	private static BluezProfileManager1? profile_manager = null;
	public string name {get; private set;}
	public string uuid {get; private set;}
	public uint8 channel {get; private set;}
	private BluezProfile1? profile = null;
	private string? profile_path = null;
	private uint profile_id = 0;

	public BluetoothService(string uuid, string name, uint8 channel=0)
	{
		this.name = name;
		this.uuid = uuid;
		this.channel = channel;
    }

	public signal void incoming(BluetoothConnection connection);

	public void listen() throws GLib.Error
	{
		if (profile_manager == null)
			profile_manager = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", "/org/bluez");

		if (profile != null)
			return;

		profile = new BluetoothProfile1(this);
		profile_path = "/eu/tiliado/diorite/bluetooth/" + uuid.replace("-", "_");
		Bus.get_sync(BusType.SYSTEM, null).register_object(new ObjectPath(profile_path), profile);
		var options = new HashTable<string, Variant>(str_hash, str_equal);
        options["Name"] = name;
        options["Role"] = "server";
        options["RequireAuthentication"] = true;
        options["RequireAuthorization"] = false;
        options["AutoConnect"]= true;
        options["Channel"]= ((uint16) channel);
		profile_manager.register_profile(new ObjectPath(profile_path), uuid, options);
	}

	public void close() throws GLib.Error
	{
		if (profile != null)
		{
			profile_manager.unregister_profile(new ObjectPath(profile_path));
			Bus.get_sync(BusType.SYSTEM, null).unregister_object(profile_id);
			profile.unref(); // FIXME: hack, report upstream
			profile = null;
			profile_path = null;
			profile_id = 0;
		}
	}

	~BluetoothService()
	{
		try
		{
			close();
		}
		catch (GLib.Error e)
		{
		}
	}
}


[DBus(name = "org.bluez.Profile1")]
private class BluetoothProfile1 : GLib.Object, BluezProfile1
{
	private weak BluetoothService service;
	private HashTable<ObjectPath, GenericArray<GLib.Socket>?> sockets;

	public BluetoothProfile1(BluetoothService service)
	{
		this.service = service;
		sockets = new HashTable<ObjectPath, GenericArray<GLib.Socket>?>(str_hash, str_equal);
	}

	~BluetoothProfile1()
	{
		var devices = sockets.get_keys();
		foreach (unowned ObjectPath device in devices)
		{
			try
			{
				request_disconnection(device);
			}
			catch (GLib.Error e)
			{
			}
		}
	}

	public void release() throws GLib.Error
	{
		debug("Bluetooth service has been released.");
	}

	public void new_connection(ObjectPath device, GLib.Socket fd, HashTable<string, Variant> fd_properties) throws GLib.Error
	{
		var parts = device.split("/");
		var address = parts.length == 5
			? "%s/%s".printf(parts[3], parts[4].substring(4).replace("_", ":")) : device;
		debug("New bluetooth connection from %s (%d).", address, fd.fd);
		GenericArray<GLib.Socket>? device_sockets = sockets[device];
		if (device_sockets == null)
			sockets[device] = device_sockets = new GenericArray<GLib.Socket>(1);
		device_sockets.add(fd);
		var connection = new BluetoothConnection(fd, address);
		uint8[] byte = {1};
		connection.output.write(byte);
		service.incoming(connection);
	}

	public void request_disconnection(ObjectPath device) throws GLib.Error
	{
		debug("Bluetooth device disconnected: %s", device);
		GenericArray<GLib.Socket>? device_sockets = sockets[device];
		if (device_sockets != null)
		{
			for (int i = 0, size = device_sockets.length; i < size; i++) {
				unowned GLib.Socket socket = device_sockets[i];
				try {
					if(!socket.is_closed())
						socket.close();
				} catch (GLib.Error e) {
					warning("Failed to close bluetooth socket %d of device %s. %s", socket.fd, device, e.message);
				}
			}
			sockets.remove(device);
		}
	}
}

} // namespace Drt
