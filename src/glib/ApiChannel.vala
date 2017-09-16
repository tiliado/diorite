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

public class ApiChannel: MessageChannel {
	public static string get_params_type(GLib.Variant? params) throws MessageError {
		if (params == null ) {
			return "tuple";
		} 
		var type = params.get_type();
		if (type.is_tuple()) {
			return "tuple";
		}
		if (type.is_array()){
			
			return type.is_subtype_of(VariantType.DICTIONARY) ? "dict" : "tuple";
		}
		throw new MessageError.UNSUPPORTED("Param type %s is not supported.", params.get_type_string());
	}
	
	public ApiRouter api_router {get{ return router as ApiRouter; }}
	public string? api_token {private get; set; default = null;}
	
	public ApiChannel(uint id, Drt.DuplexChannel channel, ApiRouter? router, string? api_token=null) {
		GLib.Object(id: id, channel: channel, router: router ?? new ApiRouter(), api_token: api_token);
	}
	
	public ApiChannel.from_name(uint id, string name, string? api_token=null, uint timeout)
	throws IOError {
		this(id, new SocketChannel.from_name(id, name, timeout), null, api_token);
	}
	
	private string create_full_method_name(string name, bool allow_private, string flags,
	string params_format) {
		return "%s::%s%s,%s,%s".printf(
			name, allow_private ? "p" : "",
			flags, params_format,
			allow_private && api_token != null ? api_token : "");
	}
	
	/**
	 * Subscribe to notification.
	 * 
	 * @param notification    Notification path.
	 * @param detail          Reserved for future use, pass `null`.
	 * @throws GLib.Error on failure
	 */
	public async void subscribe(string notification, string? detail=null) throws GLib.Error	{
		yield call_full(notification, true, "ws", new Variant("(bms)", true, detail));
	}
	
	/**
	 * Unsubscribe from notification.
	 * 
	 * @param notification    Notification path.
	 * @param detail          Reserved for future use, pass `null`.
	 * @throws GLib.Error on failure
	 */
	public async void unsubscribe(string notification, string? detail=null) throws GLib.Error {
		yield call_full(notification, true, "ws", new Variant("(bms)", false, detail));
	}
	
	public Variant? call_sync(string method, Variant? params) throws GLib.Error {
		return send_message(create_full_method_name(method, true, "rw", get_params_type(params)), params);
	}
	
	public async Variant? call(string method, Variant? params) throws GLib.Error	{
		return yield send_message_async(
			create_full_method_name(method, true, "rw", get_params_type(params)), params);
	}
	
	public async Variant? call_full(string method, bool allow_private, string flags, Variant? params)
	throws GLib.Error {
		return yield send_message_async(
			create_full_method_name(method, allow_private, flags, get_params_type(params)), params);
	}
	
	public Variant? call_full_sync(string method, bool allow_private, string flags, Variant? params)
	throws GLib.Error {
		return send_message(
			create_full_method_name(method, allow_private, flags, get_params_type(params)), params);
	}
}

} // namespace Drt
