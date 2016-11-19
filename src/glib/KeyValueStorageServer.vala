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
	internal static const string METHOD_ADD_LISTENER = "/diorite/keyvaluestorageserver/add_listener";
	internal static const string METHOD_REMOVE_LISTENER = "/diorite/keyvaluestorageserver/remove_listener";
	internal static const string METHOD_HAS_KEY = "/diorite/keyvaluestorageserver/has_key";
	internal static const string METHOD_GET_VALUE = "/diorite/keyvaluestorageserver/get_value";
	internal static const string METHOD_SET_VALUE = "/diorite/keyvaluestorageserver/set_value";
	internal static const string METHOD_UNSET = "/diorite/keyvaluestorageserver/unset";
	internal static const string METHOD_SET_DEFAULT_VALUE = "/diorite/keyvaluestorageserver/set_default_value";
	internal static const string METHOD_CHANGED = "/diorite/keyvaluestorageserver/changed";
	
	public Drt.ApiRouter router {get; construct;}
	private HashTable<string, Provider?> providers;
	
	
	public KeyValueStorageServer(Drt.ApiRouter router)
	{
		GLib.Object(router: router);
		providers = new HashTable<string, Provider?>(str_hash, str_equal);
		router.add_method(METHOD_ADD_LISTENER, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_add_listener, {
			new Drt.StringParam("provider", true, false),
		});
		router.add_method(METHOD_REMOVE_LISTENER, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_remove_listener, {
			new Drt.StringParam("provider", true, false),
		});
		router.add_method(METHOD_HAS_KEY, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.READABLE,
			null, handle_has_key, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
		});
		router.add_method(METHOD_GET_VALUE, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.READABLE,
			null, handle_get_value, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
		});
		router.add_method(METHOD_SET_VALUE, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_set_value, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
			new Drt.VariantParam("value", true, true),
		});
		router.add_method(METHOD_UNSET, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_unset, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
		});
		router.add_method(METHOD_SET_DEFAULT_VALUE, Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_set_default_value, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
			new Drt.VariantParam("value", true, true),
		});
	}
	
	public void add_provider(string name, KeyValueStorage storage)
	{
		providers[name] = new Provider(name, storage);
	}
	
	public void remove_provider(string name)
	{
		providers.remove(name);
	}
	
	public bool add_listener(string provider_name, Drt.ApiChannel listener)
	{
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;
		
		provider.listeners.prepend(listener);
		return true;
	}
	
	public bool remove_listener(string provider_name, Drt.ApiChannel listener)
	{
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;
		
		provider.listeners.remove(listener);
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
	
	private Variant? handle_add_listener(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var channel = source as Drt.ApiChannel;
		return_val_if_fail(channel != null, new Variant.boolean(false));
		var provider_name = params.pop_string();
		return new Variant.boolean(add_listener(provider_name, channel));
	}
	
	private Variant? handle_remove_listener(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var channel = source as Drt.ApiChannel;
		return_val_if_fail(channel != null, new Variant.boolean(false));
		var provider_name = params.pop_string();
		return new Variant.boolean(remove_listener(provider_name, channel));
	}
	
	private Variant? handle_has_key(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var name = params.pop_string();
		var key = params.pop_string();
		return new Variant.boolean(get_provider(name).storage.has_key(key));
	}
	
	private Variant? handle_get_value(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var name = params.pop_string();
		var key = params.pop_string();
		return get_provider(name).storage.get_value(key);
	}
	
	private Variant? handle_set_value(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var name = params.pop_string();
		var key = params.pop_string();
		var value = params.pop_variant();
		get_provider(name).storage.set_value(key, value);
		return null;
	}
	
	private Variant? handle_unset(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var name = params.pop_string();
		var key = params.pop_string();
		get_provider(name).storage.unset(key);
		return null;
	}
	
	private Variant? handle_set_default_value(GLib.Object source, Drt.ApiParams? params) throws Diorite.MessageError
	{
		var name = params.pop_string();
		var key = params.pop_string();
		var value = params.pop_variant();
		get_provider(name).storage.set_default_value(key, value);
		return null;
	}
	
	[Compact]
	private class Provider
	{
		public unowned string name;
		public KeyValueStorage storage;
		public SList<Drt.ApiChannel> listeners;
		
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
					var response = listener.call_sync(METHOD_CHANGED,
						new Variant("(ssmv)", name, key, old_value));
					if (response == null
					|| !response.is_of_type(VariantType.BOOLEAN)
					|| !response.get_boolean())
						warning("Invalid response to %s: %s", METHOD_CHANGED,
							response == null ? "null" : response.print(false));
				}
				catch (GLib.Error e)
				{
					critical("%s client error: %s", METHOD_CHANGED, e.message);
				}
			}
		}
	}
}

} // namespace Diorite
