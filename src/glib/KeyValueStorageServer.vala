/*
 * Copyright 2014-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt {

public class KeyValueStorageServer: GLib.Object {
	internal const string METHOD_ADD_LISTENER = "/diorite/keyvaluestorageserver/add_listener";
	internal const string METHOD_REMOVE_LISTENER = "/diorite/keyvaluestorageserver/remove_listener";
	internal const string METHOD_HAS_KEY = "/diorite/keyvaluestorageserver/has_key";
	internal const string METHOD_GET_VALUE = "/diorite/keyvaluestorageserver/get_value";
	internal const string METHOD_SET_VALUE = "/diorite/keyvaluestorageserver/set_value";
	internal const string METHOD_UNSET = "/diorite/keyvaluestorageserver/unset";
	internal const string METHOD_SET_DEFAULT_VALUE = "/diorite/keyvaluestorageserver/set_default_value";
	internal const string METHOD_CHANGED = "/diorite/keyvaluestorageserver/changed";

	public Drt.RpcRouter router {get; construct;}
	private HashTable<string, Provider?> providers;

	public KeyValueStorageServer(Drt.RpcRouter router) {
		GLib.Object(router: router);
		providers = new HashTable<string, Provider?>(str_hash, str_equal);
		router.add_method(METHOD_ADD_LISTENER, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.WRITABLE,
			null, handle_add_listener, {
			new Drt.StringParam("provider", true, false),
		});
		router.add_method(METHOD_REMOVE_LISTENER, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.WRITABLE,
			null, handle_remove_listener, {
			new Drt.StringParam("provider", true, false),
		});
		router.add_method(METHOD_HAS_KEY, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.READABLE,
			null, handle_has_key, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
		});
		router.add_method(METHOD_GET_VALUE, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.READABLE,
			null, handle_get_value, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
		});
		router.add_method(METHOD_SET_VALUE, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.WRITABLE,
			null, handle_set_value, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
			new Drt.VariantParam("value", true, true),
		});
		router.add_method(METHOD_UNSET, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.WRITABLE,
			null, handle_unset, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
		});
		router.add_method(METHOD_SET_DEFAULT_VALUE, Drt.RpcFlags.PRIVATE|Drt.RpcFlags.WRITABLE,
			null, handle_set_default_value, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
			new Drt.VariantParam("value", true, true),
		});
	}

	public void add_provider(string name, KeyValueStorage storage) {
		providers[name] = new Provider(name, storage);
	}

	public void remove_provider(string name) {
		providers.remove(name);
	}

	public bool add_listener(string provider_name, Drt.RpcConnection listener) {
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;

		provider.listeners.prepend(listener);
		return true;
	}

	public bool remove_listener(string provider_name, Drt.RpcConnection listener) {
		unowned Provider? provider = providers[provider_name];
		if (provider == null)
			return false;

		provider.listeners.remove(listener);
		return true;
	}

	private unowned Provider get_provider(string name) throws RpcError {
		unowned Provider? provider = providers[name];
		if (provider == null)
			throw new RpcError.INVALID_REQUEST(
				"No key-value storage provider named '%s' has been found.", name);
		return provider;
	}

	private void handle_add_listener(Drt.RpcRequest request) throws RpcError {
		var provider_name = request.pop_string();
		request.respond(new Variant.boolean(add_listener(provider_name, request.connection)));
	}

	private void handle_remove_listener(Drt.RpcRequest request) throws RpcError {
		var provider_name = request.pop_string();
		request.respond(new Variant.boolean(remove_listener(provider_name, request.connection)));
	}

	private void handle_has_key(Drt.RpcRequest request) throws RpcError {
		var name = request.pop_string();
		var key = request.pop_string();
		request.respond(new Variant.boolean(get_provider(name).storage.has_key(key)));
	}

	private void handle_get_value(Drt.RpcRequest request) throws RpcError {
		var name = request.pop_string();
		var key = request.pop_string();
		request.respond(get_provider(name).storage.get_value(key));
	}

	private void handle_set_value(Drt.RpcRequest request) throws RpcError {
		var name = request.pop_string();
		var key = request.pop_string();
		var value = request.pop_variant();
		get_provider(name).storage.set_value(key, value);
		request.respond(null);
	}

	private void handle_unset(Drt.RpcRequest request) throws RpcError {
		var name = request.pop_string();
		var key = request.pop_string();
		get_provider(name).storage.unset(key);
		request.respond(null);
	}

	private void handle_set_default_value(Drt.RpcRequest request) throws RpcError {
		var name = request.pop_string();
		var key = request.pop_string();
		var value = request.pop_variant();
		get_provider(name).storage.set_default_value(key, value);
		request.respond(null);
	}

	[Compact]
	private class Provider {
		public unowned string name;
		public KeyValueStorage storage;
		public SList<Drt.RpcConnection> listeners;

		public Provider(string name, KeyValueStorage storage) {
			this.name = name;
			this.storage = storage;
			storage.changed.connect(on_changed);
			listeners = null;
		}

		private void on_changed(string key, Variant? old_value) {
			foreach (var listener in listeners) {
				try {
					var response = listener.call_sync(METHOD_CHANGED,
						new Variant("(ssmv)", name, key, old_value));
					if (response == null
					|| !response.is_of_type(VariantType.BOOLEAN)
					|| !response.get_boolean())
						warning("Invalid response to %s: %s", METHOD_CHANGED,
							response == null ? "null" : response.print(false));
				} catch (GLib.Error e) {
					critical("%s client error: %s", METHOD_CHANGED, e.message);
				}
			}
		}
	}
}

} // namespace Drt
