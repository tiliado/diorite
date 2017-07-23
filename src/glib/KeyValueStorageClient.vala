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
namespace Drt
{

public class KeyValueStorageClient: GLib.Object
{
	public Drt.ApiChannel channel {get; construct;}
	
	public KeyValueStorageClient(Drt.ApiChannel channel)
	{
		GLib.Object(channel: channel);
		channel.api_router.add_method("/diorite/keyvaluestorageserver/changed", Drt.ApiFlags.PRIVATE|Drt.ApiFlags.WRITABLE,
			null, handle_changed, {
			new Drt.StringParam("provider", true, false),
			new Drt.StringParam("key", true, false),
			new Drt.VariantParam("old_value", true, true),
		});
	}
	
	public signal void changed(string provider_name, string key, Variant? old_value);
	
	public KeyValueStorage get_proxy(string provider_name)
	{
		return new KeyValueStorageProxy(this, provider_name);
	}
	
	private Variant? handle_changed(GLib.Object source, Drt.ApiParams? params) throws MessageError
	{
		var provider_name = params.pop_string();
		var key = params.pop_string();
		var old_value = params.pop_variant();
		changed(provider_name, key, old_value);
		return new Variant.boolean(true);
	}
}

} // namespace Drt
