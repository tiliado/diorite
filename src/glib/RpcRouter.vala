/*
 * Copyright 2016-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

/**
 * RpcRouter provides advanced IPC API framework.
 * 
 *   * Private API calls can be marked with `RpcFlags.PRIVATE` and require a proper `token`.
 *   * Writable API calls can be marked with `RpcFlags.WRITABLE` and require that the same flag is set
 *     during a method call.
 *   * Method as well as parameters can hold description which can be then shown to API consumers,
 *     e.g. command-line or HTTP/JSON interface.
 */
public class RpcRouter: GLib.Object {
	private static bool log_comunication;
	public string hex_token {
		owned get {
			string result;
			Blobs.hexadecimal_from_blob(token, out result);
			return result;
		}
	}
	protected uint8[] token;
	protected HashTable<string, RpcCallable?> methods;
	
	static construct {
		log_comunication = Environment.get_variable("DIORITE_LOG_API_ROUTER") == "yes";
	}
	
	/**
	 * Creates new RPC Router.
	 */
	public RpcRouter() {
		methods = new HashTable<string, RpcCallable?>(str_hash, str_equal);
		Drt.Random.blob(256, out token);
	}
	
	/**
	 * Emitted when a notification is received.
	 * 
	 * @param source    The source of the notification.
	 * @param name      The name of the notification.
	 * @param detail    Unused, reserved for future.
	 * @param data      Notification data.
	 */
	public signal void notification(RpcConnection source, string name, string? detail, Variant? data);
	
	/**
	 * Emit remote notification.
	 * 
	 * @param name      The name of the notification.
	 * @param detail    Unused, reserved for future.
	 * @param data      Notification data.
	 * @return true if notification exists and has been sent.
	 */
	public bool emit(string name, string? detail, Variant? data) {
		var notification = methods[name] as RpcNotification;
		if (notification == null) {
			warning("Notification '%s' not found.", name);
			return false;
		}
		Idle.add(() => {
			notification.emit.begin(detail, data , (o, res) => {notification.emit.end(res);});
			return false;
		});
		return true;
	}
	
	/**
	 * Add a new method
	 * 
	 * @param path           Path of the method.
	 * @param flags          Method call flags.
	 * @param description    Description of the method for API consumers.
	 * @param handler        Handler to be called upon successful execution.
	 * @param parameters         Specification of parameters.
	 */
	public virtual void add_method(string path, RpcFlags flags, string? description,
		owned RpcHandler handler, RpcParam[]? parameters) {
		methods[path] = new RpcMethod(path, flags, parameters, (owned) handler, description);
	}
	
	/**
	 * Add a new notification
	 * 
	 * @param path           Path of the notification.
	 * @param flags          Notification call flags.
	 * @param description    Description of the notification for API consumers.
	 */
	public virtual void add_notification(string path, RpcFlags flags, string? description) {
		methods[path] = new RpcNotification(path, flags, description);
	}
	
	/**
	 * Remove previously registered method.
	 * 
	 * @param path    The path of a method.
	 * @return true if method has been found and removed.
	 */
	public virtual bool remove_method(string path) {
		return methods.remove(path);
	}
	
	/**
	 * Remove previously registered notification.
	 * 
	 * @param path    The path of a notification.
	 * @return true if notification has been found and removed.
	 */
	public virtual bool remove_notification(string path) {
		return methods.remove(path);
	}
	
	/**
	 * List available RPc methods.
	 * 
	 * @param parent_path     Parent namespace.
	 * @param strip           Prefix to strip.
	 * @param list_private    Whether to list private methods.
	 * @param list            The resulting list.
	 * @return true if there is at least one method.
	 */
	public bool list_methods(string parent_path, string? strip, bool list_private, out Variant list) {
		var strip_len = strip != null ? strip.length : 0;
		var root = new VariantBuilder(new VariantType("a{sv}"));
		var builder = new VariantBuilder(new VariantType("aa{smv}"));
		var paths = methods.get_keys();
		paths.sort(string.collate);
		var prefix = parent_path.has_suffix("/") ? parent_path : parent_path + "/";
		foreach (string path in paths) {
			if (!path.has_prefix(prefix)) {
				continue;
			}
			
			var callable = methods[path];
			var flags = "";
			if ((callable.flags & RpcFlags.PRIVATE) != 0) {
				if (!list_private) {
					continue;
				}
				flags += "p";
			}

			if ((callable.flags & RpcFlags.READABLE) != 0) {
				flags += "r";
			}
			if ((callable.flags & RpcFlags.WRITABLE) != 0) {
				flags += "w";
			}
			if (strip != null && path.has_prefix(strip)) {
				path = path.substring(strip_len);
			}
				
			builder.open(new VariantType("a{smv}"));
			var params = new VariantBuilder(new VariantType("aa{smv}"));
			var method = callable as RpcMethod;
			if (method != null) {
				builder.add("{smv}", "type", new Variant.string("method"));
				foreach (var param in method.params) {
					params.open(new VariantType("a{smv}"));
					params.add("{smv}", "name", new Variant.string(param.name));
					params.add("{smv}", "type", new Variant.string(param.type_string));
					params.add("{smv}", "description", new_variant_string_or_null(param.description));
					params.add("{smv}", "required", new Variant.boolean(param.required));
					params.add("{smv}", "nullable", new Variant.boolean(param.nullable));
					params.add("{smv}", "default_value", param.default_value);
					params.close();
				}
			}
			var notification = callable as RpcNotification;
			if (notification != null) {
				builder.add("{smv}", "type", new Variant.string("notification"));
				params.open(new VariantType("a{smv}"));
				params.add("{smv}", "name", new Variant.string("subscribe"));
				params.add("{smv}", "type", new Variant.string("b"));
				params.add("{smv}", "description", new Variant.string("true to subscribe, false to unsubscribe"));
				params.add("{smv}", "required", new Variant.boolean(true));
				params.add("{smv}", "nullable", new Variant.boolean(false));
				params.add("{smv}", "default_value", null);
				params.close();
				params.open(new VariantType("a{smv}"));
				params.add("{smv}", "name", new Variant.string("detail"));
				params.add("{smv}", "type", new Variant.string("s"));
				params.add("{smv}", "description", new Variant.string("Subscription detail"));
				params.add("{smv}", "required", new Variant.boolean(false));
				params.add("{smv}", "nullable", new Variant.boolean(true));
				params.add("{smv}", "default_value", null);
				params.close();
			}
			builder.add("{smv}", "path", new Variant.string(path));
			builder.add("{smv}", "flags", new Variant.string(flags));
			builder.add("{smv}", "description", new_variant_string_or_null(callable.description));
			builder.add("{smv}", "params", params.end());
			builder.close();
		}
		var array = builder.end();
		root.add("{sv}", "methods", array);
		var count = array.n_children();
		root.add("{sv}", "count", new Variant.int32((int32) count));
		list = root.end();
		return count > 0;
	}
	
	/**
	 * Handle RPC request.
	 * 
	 * @param conn          Request connection.
	 * @param id            Request id.
	 * @param name          Request name.
	 * @param parameters    Request parameters.
	 * @throws GLib.Error on failure.
	 */
	public void handle_request(RpcConnection conn, uint id, string name, Variant? parameters) throws GLib.Error {
		var always_secure = conn is RpcLocalConnection;
		if (log_comunication) {
			debug("Handle message %s: %s", name, parameters == null ? "null" : parameters.print(false));
		}
		if (name == "echo") {
			conn.respond(id, parameters);
			return;
		}
		var pos = name.last_index_of("::");
		if (pos < 0) {
			throw new ApiError.INVALID_REQUEST("Method name is incomplete: '%s'", name);
		}
		
		int offset = 0;
		var notification = false;
		if (name.has_prefix("n:")) {
			notification = true;
			offset = 2;
		}
		
		var path = name.substring(offset, pos - offset);
		var spec = name.substring(pos + 2).split(",");
		if (spec.length < 3) {
			throw new ApiError.INVALID_REQUEST("Message format specification is incomplete: '%s'", name);
		}
		var flags = spec[0];
		var hex_token = String.null_if_empty(spec[2]);
		uint8[] token;
		if (hex_token != null) {
			Blobs.hexadecimal_to_blob(hex_token, out token);
		} else {
			token = {};
		}
		if (notification) {
			string? detail = null;
			Variant data = null;
			RpcNotification.get_detail_and_params(parameters, out detail, out data);
			this.notification(conn, path, detail, data);
			conn.respond(id, null);
			return;
		}
		var method = methods[path];
		if (method == null) {
			Variant? listing = null;
			list_methods(path, "/nuvola/", false, out listing);
			conn.respond(id, listing);
		} else {
			if ((method.flags & RpcFlags.PRIVATE) != 0 && !("p" in flags)) {
				throw new ApiError.PRIVATE_FLAG("Message doesn't have private flag set: '%s'", name);
			}
			if ((method.flags & RpcFlags.READABLE) != 0 && !("r" in flags)) {
				throw new ApiError.READABLE_FLAG("Message doesn't have readable flag set: '%s'", name);
			}
			if ((method.flags & RpcFlags.WRITABLE) != 0 && !("w" in flags)) {
				throw new ApiError.WRITABLE_FLAG("Message doesn't have writable flag set: '%s'", name);
			}
			if ((method.flags & RpcFlags.SUBSCRIBE) != 0 && !("s" in flags)) {
				throw new ApiError.SUBSCRIBE_FLAG("Message doesn't have subscribe flag set: '%s'", name);
			}
			if (!always_secure && (method.flags & RpcFlags.PRIVATE) != 0 && !Blobs.blob_equal(this.token, token)) {
				throw new ApiError.API_TOKEN_REQUIRED("Message doesn't have a valid token: '%s'", name);
			}
			method.run(conn, id, parameters);
		}
	}
}

} // namespace Drt
