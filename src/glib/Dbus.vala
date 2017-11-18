/*
 * Copyright 2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt.Dbus {

/**
 * Get XDG DBus root object.
 * 
 * @param bus            The bus to get the root object from.
 * @param cancellable    Cancellable object.
 * @return XDG DBus root object.
 * @throws GLib.Error on failure.
 */
public async XdgDbus get_xdg_dbus(DBusConnection bus, Cancellable? cancellable = null) throws GLib.Error {
	return yield bus.get_proxy<XdgDbus>("org.freedesktop.DBus", "/", 0, cancellable);
}

/**
 * Ensure that given service is running and start it when necessary.
 * 
 * @param bus            The bus to find the service at.
 * @param name           A well-known service name to search for.
 * @param cancellable    Cancellable object.
 * @throws GLib.Error when the service is not running and cannot be started.
 */
public async void ensure_service(DBusConnection bus, string name, Cancellable? cancellable = null)
throws GLib.Error {
	var dbus = yield get_xdg_dbus(bus, cancellable);
	if (yield dbus.name_has_owner(name)) {
		yield dbus.start_service_by_name(name, 0);
	}
}

/**
 * Introspect DBus object.
 * 
 * @param bus            The bus to find the object at.
 * @param name           A well-known service name to search for.
 * @param path           An object path.
 * @param cancellable    Cancellable object.
 * @return Introspection data as XML.
 * @throws GLib.Error on failure.
 */
public async string introspect_xml(DBusConnection bus, string name, string path,
Cancellable? cancellable = null) throws GLib.Error {
	var introspectable = yield bus.get_proxy<XdgDbusIntrospectable>(name, path, 0, cancellable);
	return yield introspectable.introspect();
}

/**
 * Introspect DBus object.
 * 
 * @param bus            The bus to find the object at.
 * @param name           A well-known service name to search for.
 * @param path           An object path.
 * @param cancellable    Cancellable object.
 * @return Introspection data.
 * @throws GLib.Error on failure.
 */
public async Introspection introspect(DBusConnection bus, string name, string path,
Cancellable? cancellable = null) throws GLib.Error {
	var xml = yield introspect_xml(bus, name, path, cancellable);
	return new Introspection(name, path, new DBusNodeInfo.for_xml(xml));
}

/**
 * DBus introspection container.
 */
public class Introspection {
	public string name {get; private set;}
	public string path {get; private set;}
	public DBusNodeInfo node_info {get; private set;}
	
	/**
	 * Creates new DBus introspection container.
	 * 
	 * @param name         A well-known service name to search for.
	 * @param path         An object path.
	 * @param node_info    Introspection data.
	 */
	public Introspection(string name, string path, DBusNodeInfo node_info) {
		this.name = name;
		this.path = path;
		this.node_info = node_info;
	}
	
	/**
	 * Get interface info.
	 * 
	 * @param name    Interface name.
	 * @return Interface info if the interface exists, null otherwise.
	 */
	public unowned DBusInterfaceInfo? get_interface(string name) {
		foreach (unowned DBusInterfaceInfo ifce in node_info.interfaces) {
			if (ifce.name == name) {
				return ifce;
			}
		}
		return null;
	}
	
	/**
	 * Check the existence of an interface.
	 * 
	 * @param name    Interface name.
	 * @return True if the interface exists, false otherwise.
	 */
	public bool has_interface(string name) {
		return get_interface(name) != null;
	}
	
	/**
	 * Get method info.
	 * 
	 * @param ifce_name    Interface name.
	 * @param method       Method name.
	 * @return Method info if the interface and method exist, null otherwise.
	 */
	public unowned DBusMethodInfo get_method(string ifce_name, string method) {
		var ifce = get_interface(ifce_name);
		return ifce != null ? ifce.lookup_method(method): null;
	}
	
	/**
	 * Check the existence of interface method.
	 * 
	 * @param ifce_name    Interface name.
	 * @param method       Method name.
	 * @return True if the interface and method exist, false otherwise.
	 */
	public bool has_method(string ifce_name, string method) {
		return get_method(ifce_name, method) != null;
	}
	
	/**
	 * Assert the existence of interface method.
	 * 
	 * @param ifce_name    Interface name.
	 * @param method       Method name.
	 * @throws GLib.IOError if the interface and method don't exist.
	 */
	public void assert_method(string ifce_name, string method) throws GLib.IOError {
		if (!has_method(ifce_name, method)) {
			throw new GLib.IOError.NOT_SUPPORTED(
				"%s does not support %s method of %s interface.", name, method, ifce_name);
		}
	}
}

[DBus(name = "org.freedesktop.DBus")]
public interface XdgDbus: GLib.Object {
	/**
	 * Checks if the specified name exists (currently has an owner).
	 * 
	 * @param name    Name to check
	 * @return true if the name exists, false otherwise.
	 */
	public abstract async bool name_has_owner(string name) throws GLib.Error;
	
	/**
	 * Tries to launch the executable associated with a name (service activation), as an explicit request.
	 * 
	 * @param name     Name of the service to start
	 * @param flags    Flags (currently not used)
	 * @return 1 when the service was successfully started, 2 when a connection already owns the given name.
	 */
	public abstract async uint32 start_service_by_name(string name, uint32 flags) throws GLib.Error;
}

[DBus(name = "org.freedesktop.DBus.Introspectable")]
public interface XdgDbusIntrospectable: GLib.Object {
	/**
	 * Returns an XML description of the object, including its interfaces (with signals and methods), objects below
	 * it in the object path tree, and its properties.
	 * 
	 * @return XML description.
	 */
	public abstract async string introspect() throws GLib.Error;
}

} // namespace Drt.Dbus
