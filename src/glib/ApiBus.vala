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

public class ApiBus: BaseBus<ApiChannel, ApiRouter>, Diorite.MessageListener
{
	protected static bool log_comunication;
	
	static construct
	{
		log_comunication = Environment.get_variable("DIORITE_LOG_API_BUS_BUS") == "yes";
	}
	
	public ApiBus(string name, ApiRouter? router, uint timeout)
	{
		base(name, router, timeout);
	}
	
	[Deprecated (replacement = "this.router.add_method")]
	public virtual void add_handler(string message_name, string? type_string, owned Diorite.MessageHandler handler)
	{
		router.add_handler(message_name, type_string, (owned) handler);
	}
	
	[Deprecated (replacement = "this.router.remove_method")]
	public virtual bool remove_handler(string message_name)
	{
		return router.remove_handler(message_name);
	}
	
	/**
	 * Convenience method to invoke message handler from server's process.
	 */
	public Variant? send_local_message(string name, Variant? data) throws GLib.Error
	{
		if (log_comunication)
			debug("Local request '%s': %s", name, data != null ? data.print(false) : "NULL");
		var response = router.handle_message(this, name, data);
		if (log_comunication)
			debug("Local response: %s", response != null ? response.print(false) : "NULL");
		return response;
	}
	
	public Variant? call_local(string name, Variant? data) throws GLib.Error
	{
		return call_local_sync_full(name, true, "rw", "tuple",  data);
	}
	
	public Variant? call_local_with_dict(string name, Variant? data) throws GLib.Error
	{
		return call_local_sync_full(name, true, "rw", "dict",  data);
	}
	
	public Variant? call_local_sync_full(string name, bool allow_private, string flags, string data_format, Variant? data) throws GLib.Error
	{
		if (log_comunication)
			debug("Local request '%s': %s", name, data != null ? data.print(false) : "NULL");
		var response = router.handle_local_call(this, name, allow_private, flags, data_format, data);
		if (log_comunication)
			debug("Local response: %s", response != null ? response.print(false) : "NULL");
		return response;
	}
}

} // namespace Drt
