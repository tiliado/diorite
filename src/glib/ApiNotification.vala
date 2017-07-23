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

public class ApiNotification : ApiCallable
{
	private SList<GLib.Object> subscribers = null;
	
	public ApiNotification(string path, ApiFlags flags, string? description)
	{
		this.path = path;
		this.flags = flags;
		this.description = description;
	}
	
	public static void parse_tuple_params(string? path, Variant? data, out bool subscribe, out string? detail) throws GLib.Error
	{
		subscribe = true;
		detail = null;
		
		if (data == null)
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires 2 parameters but no parameters have been provided.", path);
		if (!data.get_type().is_subtype_of(VariantType.TUPLE))
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' call expected a tuple of parameters, but type of '%s' received.",
				path, data.get_type_string());
		
		var n_children = data.n_children();
		if (n_children < 1 || n_children > 2)
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires %d parameters but %d parameters have been provided.",
				path, 2, (int) data.n_children());
				
		var entry = unbox_variant(data.get_child_value(0));
		if (!variant_bool(entry, ref subscribe))
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' call expected the first parameter to be a boolean, but type of '%s' received.",
				path, entry.get_type_string());
		
		if (n_children == 2)
		{
			entry = unbox_variant(data.get_child_value(1));
			if (!variant_string(entry, out detail))
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' call expected the second parameter to be a string, but type of '%s' received.",
					path, entry.get_type_string());
		}
	}
	
	public static void parse_dict_params(string? path, Variant? data, out bool subscribe, out string? detail) throws GLib.Error
	{
		subscribe = true;
		detail = null;
		if (data == null)
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires 2 parameters but no parameters have been provided.",
				path);
		if (data.get_type_string() != "(a{smv})")
			MessageListener.check_type_string(data, "a{smv}");
			
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
	
	public Variant? subscribe(GLib.Object conn, bool subscribe, string? detail) throws GLib.Error
	{
		if (subscribe)
			subscribers.append(conn);
		else
			subscribers.remove(conn);
		return null;
	}
	
	public async bool emit(string? detail, Variant? data)
	{
		var result = true;
		foreach (unowned GLib.Object conn in subscribers)
		{
			var channel = conn as ApiChannel;
			if (channel != null)
			{
				try
				{
					yield channel.call("n:" + path, data);
				}
				catch (GLib.Error e)
				{
					result = false;
					warning("Failed to emit '%s': %s", path, e.message);
				}
				continue;
			}
			var bus = conn as ApiBus;
			if (bus != null)
			{
				(bus.router as ApiRouter).notification(bus, path, detail, data);
			}
			else
			{
				warning("Not an ApiChannel nor ApiBus: %s", conn.get_type().name());
			}
		}
		return result;
	}
	
	public override void run_with_args_tuple(GLib.Object conn, Variant? data, out Variant? response) throws GLib.Error
	{
		bool subscribe = true;
		string? detail = null;
		parse_tuple_params(path, data, out subscribe, out detail);
		response = this.subscribe(conn, subscribe, detail);
	}
	
	public override void run_with_args_dict(GLib.Object conn, Variant? data, out Variant? response) throws GLib.Error
	{
		bool subscribe = true;
		string? detail = null;
		parse_dict_params(path, data, out subscribe, out detail);
		response = this.subscribe(conn, subscribe, detail);
	}
}

} // namespace Drt
