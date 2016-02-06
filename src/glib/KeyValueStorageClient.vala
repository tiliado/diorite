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

public class KeyValueStorageClient: GLib.Object
{
	public Diorite.Ipc.MessageClient provider {get; construct;}
	public Diorite.Ipc.MessageServer listener {get; construct;}
	
	public KeyValueStorageClient(Diorite.Ipc.MessageClient provider,
		Diorite.Ipc.MessageServer listener)
	{
		GLib.Object(provider: provider, listener: listener);
		listener.add_handler("KeyValueStorageServer.changed", "(ssmv)", handle_changed);
	}
	
	public signal void changed(string provider_name, string key, Variant? old_value);
	
	public KeyValueStorage get_proxy(string provider_name, uint32 timeout)
	{
		return new KeyValueStorageProxy(this, provider_name, timeout);
	}
	
	private Variant? handle_changed(GLib.Object source, Variant? data) throws MessageError
	{
		string provider_name = null;
		string key = null;
		Variant? old_value = null;
		data.get("(ssmv)", &provider_name, &key, &old_value);
		changed(provider_name, key, old_value);
		return new Variant.boolean(true);
	}
}

} // namespace Diorite
