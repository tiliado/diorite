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

namespace Diorite
{

public class KeyValueStorageServer: GLib.Object
{
	internal static const string METHOD_ADD_LISTENER = "KeyValueStorageServer.add_listener";
	internal static const string METHOD_REMOVE_LISTENER = "KeyValueStorageServer.remove_listener";
	internal static const string METHOD_HAS_KEY = "KeyValueStorageServer.has_key";
	internal static const string METHOD_GET_VALUE = "KeyValueStorageServer.get_value";
	internal static const string METHOD_SET_VALUE = "KeyValueStorageServer.set_value";
	internal static const string METHOD_UNSET = "KeyValueStorageServer.unset";
	internal static const string METHOD_SET_DEFAULT_VALUE = "KeyValueStorageServer.set_default_value";
	internal static const string METHOD_CHANGED = "KeyValueStorageServer.changed";
	
	public Ipc.MessageServer server {get; construct;}
	private HashTable<string, Provider?> providers;
	
	
	public KeyValueStorageServer(Ipc.MessageServer server)
	{
		GLib.Object(server: server);
		providers = new HashTable<string, Provider?>(str_hash, str_equal);
		server.add_handler(METHOD_ADD_LISTENER, "(ssu)", handle_add_listener);
		server.add_handler(METHOD_REMOVE_LISTENER, "(ss)", handle_remove_listener);
		server.add_handler(METHOD_HAS_KEY, "(ss)", handle_has_key);
		server.add_handler(METHOD_GET_VALUE, "(ss)", handle_get_value);
		server.add_handler(METHOD_SET_VALUE, "(ssmv)", handle_set_value);
		server.add_handler(METHOD_UNSET, "(ss)", handle_unset);
		server.add_handler(METHOD_SET_DEFAULT_VALUE, "(ssmv)", handle_set_default_value);
	}
	
	public void add_provider(string name, KeyValueStorage storage)
	{
		providers[name] = new Provider(name, storage);
	}
	
	public void remove_provider(string name)
	{
		providers.remove(name);
	}
	
	public bool add_listener(string provider_name, Ipc.MessageClient listener)
	{
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;
		
		provider.listeners.prepend(listener);
		return true;
	}
	
	public bool add_listener_by_name(string provider_name, string listener_name, uint timeout)
	{
		return add_listener(provider_name, new Ipc.MessageClient(listener_name, timeout));
	}
	
	public bool remove_listener(string provider_name, Ipc.MessageClient listener)
	{
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;
		
		provider.listeners.remove(listener);
		return true;
	}
	
	public bool remove_listener_by_name(string provider_name, string listener_name)
	{
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;
		
		foreach (unowned Ipc.MessageClient listener in provider.listeners)
		{
			if (listener.name == listener_name)
			{
				provider.listeners.remove(listener);
				break;
			}
		}
		return true;
	}
	
	private unowned Provider get_provider(string name) throws MessageError
	{
		unowned Provider? provider = providers[name];
		if (provider == null)
			throw new MessageError.INVALID_REQUEST(
				"No key-value storage provider named '%s' has been found.", name);
		return provider;
	}
	
	private Variant? handle_add_listener(GLib.Object source, Variant? data) throws MessageError
	{
		string provider_name = null;
		string listener_name = null;
		uint32 timeout = 15;
		data.get("(ssu)", &provider_name, &listener_name, &timeout);
		return new Variant.boolean(add_listener_by_name(provider_name, listener_name, (uint) timeout));
	}
	
	private Variant? handle_remove_listener(GLib.Object source, Variant? data) throws MessageError
	{
		string provider_name = null;
		string listener_name = null;
		data.get("(ss)", &provider_name, &listener_name);
		return new Variant.boolean(remove_listener_by_name(provider_name, listener_name));
	}
	
	private Variant? handle_has_key(GLib.Object source, Variant? data) throws MessageError
	{
		string name = null;
		string key = null;
		data.get("(ss)", &name, &key);
		return new Variant.boolean(get_provider(name).storage.has_key(key));
	}
	
	private Variant? handle_get_value(GLib.Object source, Variant? data) throws MessageError
	{
		string name = null;
		string key = null;
		data.get("(ss)", &name, &key);
		return get_provider(name).storage.get_value(key);
	}
	
	private Variant? handle_set_value(GLib.Object source, Variant? data) throws MessageError
	{
		string name = null;
		string key = null;
		Variant? value = null;
		data.get("(ssmv)", &name, &key, &value);
		get_provider(name).storage.set_value(key, value);
		return null;
	}
	
	private Variant? handle_unset(GLib.Object source, Variant? data) throws MessageError
	{
		string name = null;
		string key = null;
		data.get("(ss)", &name, &key);
		get_provider(name).storage.unset(key);
		return null;
	}
	
	private Variant? handle_set_default_value(GLib.Object source, Variant? data) throws MessageError
	{
		string name = null;
		string key = null;
		Variant? value = null;
		data.get("(ssmv)", &name, &key, &value);
		get_provider(name).storage.set_default_value(key, value);
		return null;
	}
	
	[Compact]
	private class Provider
	{
		public unowned string name;
		public KeyValueStorage storage;
		public SList<Ipc.MessageClient> listeners;
		
		public Provider(string name, KeyValueStorage storage)
		{
			this.name = name;
			this.storage = storage;
			storage.changed.connect(on_changed);
			listeners = null;
		}
		
		private void on_changed(string key, Variant? old_value)
		{
			foreach (var listener in listeners)
			{
				try
				{
					var response = listener.send_message(METHOD_CHANGED,
						new Variant("(ssmv)", name, key, old_value));
					if (response == null
					|| !response.is_of_type(VariantType.BOOLEAN)
					|| !response.get_boolean())
						warning("Invalid response to %s: %s", METHOD_CHANGED,
							response == null ? "null" : response.print(false));
				}
				catch (MessageError e)
				{
					critical("%s client error: %s", METHOD_CHANGED, e.message);
				}
			}
		}
	}
}

} // namespace Diorite
