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
 * RPC Notification handles incoming request to subscribe/unsubscribe and emits notifications..
 */
public class RpcNotification : RpcCallable {
	private SList<RpcConnection> subscribers = null;
	
	/**
	 * Creates new Rpcnotification handler
	 * 
	 * @param path           Notification path.
	 * @param flags          Notification flags.
	 * @param description    Notification description for API index.
	 */
	public RpcNotification(string path, RpcFlags flags, string? description) {
		this.path = path;
		this.flags = flags;
		this.description = description;
	}
	
	/**
	 * Parse raw data of (un)subscribe request.
	 * 
	 * @param path         Request path.
	 * @param data         Raw request data.
	 * @param subscribe    Whether to subscribe or unsubscribe.
	 * @param detail       Unused, reserved for future.
	 * @throws GLib.Error on failure.
	 */
	public static void parse_params(string? path, Variant? data, out bool subscribe, out string? detail)
	throws GLib.Error {
		subscribe = true;
		detail = null;
		if (data == null) {
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires 2 parameters but no parameters have been provided.", path);
		}
		var params_type = Rpc.get_params_type(data);
		if (params_type == "tuple") {
			if (!data.get_type().is_subtype_of(VariantType.TUPLE)) {
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' call expected a tuple of parameters, but type of '%s' received.",
					path, data.get_type_string());
			}
			var n_children = data.n_children();
			if (n_children < 1 || n_children > 2) {
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' requires %d parameters but %d parameters have been provided.",
					path, 2, (int) data.n_children());
			}
			var entry = unbox_variant(data.get_child_value(0));
			if (!variant_bool(entry, ref subscribe)) {
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' call expected the first parameter to be a boolean, but type of '%s' received.",
					path, entry.get_type_string());
			}
			if (n_children == 2) {
				entry = unbox_variant(data.get_child_value(1));
				if (entry != null && !variant_string(entry, out detail)) {
					throw new ApiError.INVALID_PARAMS(
						"Method '%s' call expected the second parameter to be a string, but type of '%s' received.",
						path, entry.get_type_string());
				}
			}
		} else {
			if (data.get_type_string() != "(a{smv})")
			Rpc.check_type_string(data, "a{smv}");
			
			var dict = data.get_type_string() == "(a{smv})" ? data.get_child_value(0) : data;
			var entry = unbox_variant(dict.lookup_value("subscribe", null));
			if (entry == null)
				throw new ApiError.INVALID_PARAMS(
						"Method '%s' requires the 'subscribe' parameter of type 'b', but it has been omitted.",
						path);
			
			if (!variant_bool(entry, ref subscribe))
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' call expected the subscribe parameter to be a boolean, but type of '%s' received.",
					path, entry.get_type_string());
			
			entry = unbox_variant(dict.lookup_value("detail", null));
			if (entry != null && !variant_string(entry, out detail))
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' call expected the detail parameter to be a string, but type of '%s' received.",
					path, entry.get_type_string());
		}
	}
	
	/**
	 * Parse raw data of notification.
	 * 
	 * @param data         Raw notification data.
	 * @param detail       Unused, reserved for future.
	 * @param params       Notification parameters
	 * @throws GLib.Error on failure.
	 */
	public static void get_detail_and_params(Variant data, out string? detail, out Variant? params)
	throws GLib.Error {
		detail = null;
		params = null;
		var params_type = Rpc.get_params_type(data);
		if (params_type == "tuple") {
			if (!data.get_type().is_subtype_of(VariantType.TUPLE)) {
				throw new ApiError.INVALID_PARAMS(
					"Notification call expected a tuple of parameters, but type of '%s' received.",
					data.get_type_string());
			}
			var n_children = data.n_children();
			if (n_children > 2) {
				throw new ApiError.INVALID_PARAMS(
					"Notification requires %d parameters but %d parameters have been provided.",
					2, (int) data.n_children());
			}
			if (n_children > 0) {
				var entry = unbox_variant(data.get_child_value(0));
				if (entry != null && !variant_string(entry, out detail)) {
					throw new ApiError.INVALID_PARAMS(
						"Notification call expected the first parameter to be a string, but type of '%s' received.",
						entry.get_type_string());
				}
				if (n_children == 2) {
					params = unbox_variant(data.get_child_value(1));
				}
			}
		} else {
			if (data.get_type_string() != "(a{smv})"){
				Rpc.check_type_string(data, "a{smv}");
			}
			var dict = data.get_type_string() == "(a{smv})" ? data.get_child_value(0) : data;
			var entry = unbox_variant(dict.lookup_value("detail", null));
			if (entry != null && !variant_string(entry, out detail)) {
				throw new ApiError.INVALID_PARAMS(
					"Notification call expected the detail parameter to be a string, but type of '%s' received.",
					entry.get_type_string());
			}
			params = unbox_variant(dict.lookup_value("params", null));
		}
	}
	
	/**
	 * Subscribe or unsubscribe from notification.
	 * 
	 * @param conn      RpcConnection to (un)subscribe.
	 * @param detail    Unused, reserved for future.
	 * @throws GLib.Error on failure.
	 */
	public void subscribe(RpcConnection conn, bool subscribe, string? detail) throws GLib.Error {
		if (subscribe) {
			subscribers.append(conn);
		} else {
			subscribers.remove(conn);
		}
	}
	
	/**
	 * Emit notification.
	 * 
	 * @param detail    Unused, reserved for future.
	 * @param data      Notification body.
	 * @return true if there have been no errors.
	 */
	public async bool emit(string? detail, Variant? data) {
		var result = true;
		foreach (unowned RpcConnection channel in subscribers) {
			try {
				yield channel.call("n:" + path, new Variant("(msmv)", detail, data));
			} catch (GLib.Error e) 	{
				result = false;
				warning("Failed to emit '%s': %s", path, e.message);
			}
		}
		return result;
	}
	
	/**
	 * Run callable object with data from RPC request.
	 * @param conn    Request connection.
	 * @param id      Request id.
	 * @param data    Request data.
	 * @throws GLib.Error on failure.
	 */
	public override void run(RpcConnection conn, uint id, Variant? data) throws GLib.Error {
		bool subscribe = true;
		string? detail = null;
		parse_params(path, data, out subscribe, out detail);
		this.subscribe(conn, subscribe, detail);
		conn.respond(id, null);
	}
}

} // namespace Drt
