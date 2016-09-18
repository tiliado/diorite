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

public class ApiChannel: MessageChannel
{
	public ApiRouter api_router {get{ return router as ApiRouter; }}
	public string? api_token {private get; set; default = null;}
	
	public ApiChannel(uint id, Drt.DuplexChannel channel, ApiRouter? router, string? api_token=null)
	{
		GLib.Object(id: id, channel: channel, router: router ?? new ApiRouter(), api_token: api_token);
	}
	
	public ApiChannel.from_name(uint id, string name, string? api_token=null, uint timeout=500) throws Diorite.IOError
	{
		this(id, new Diorite.SocketChannel.from_name(id, name, timeout), null, api_token);
	}
	
	private string create_full_method_name(string name, string spec)
	{
		return "%s::prw,%s,%s".printf(name, spec, api_token);
	}
	
	public Variant? call_sync(string method, Variant? params) throws GLib.Error
	{
		return send_message(create_full_method_name(method, "tuple"), params);
	}
	
	public async Variant? call(string method, Variant? params) throws GLib.Error
	{
		return yield send_message_async(create_full_method_name(method, "tuple"), params);
	}
	
	public Variant? call_with_dict_sync(string method, Variant? params) throws GLib.Error
	{
		return send_message(create_full_method_name(method, "dict"), params);
	}
	
	public async Variant? call_with_dict(string method, Variant? params) throws GLib.Error
	{
		return yield send_message_async(create_full_method_name(method, "dict"), params);
	}
}

} // namespace Drt
