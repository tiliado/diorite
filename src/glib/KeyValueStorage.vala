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

public interface KeyValueStorage: GLib.Object
{
	public signal void changed(string key, Variant? old_value);
	
	public abstract bool has_key(string key);
	
	public abstract Variant? get_value(string key);
	
	public abstract void set_value(string key, Variant? value);
	
	public abstract void unset(string key);
	
	public abstract void set_default_value(string key, Variant? value);
	
	public bool get_bool(string key)
	{
		var value = get_value(key);
		if (value != null && value.is_of_type(VariantType.BOOLEAN))
			return value.get_boolean();
		return false;
	}
	
	public int64 get_int64(string key)
	{
		var value = get_value(key);
		if (value != null && value.is_of_type(VariantType.INT64))
			return value.get_int64();
		return (int64) 0;
	}
	
	public double get_double(string key)
	{
		var value = get_value(key);
		if (value != null && value.is_of_type(VariantType.DOUBLE))
			return value.get_double();
		return 0.0;
	}
	
	public string? get_string(string key)
	{
		var value = get_value(key);
		if (value != null && value.is_of_type(VariantType.STRING))
			return value.get_string();
		return null;
	}
	
	public void set_string(string key, string? value)
	{
		set_value(key, value != null ? new Variant.string(value) : null);
	}
	
	public void set_int64(string key, int64 value)
	{
		set_value(key, new Variant.int64(value));
	}
	
	public void set_bool(string key, bool value)
	{
		set_value(key, new Variant.boolean(value));
	}
	
	public void set_double(string key, double value)
	{
		set_value(key, new Variant.double(value));
	}
}

} // namespace Diorite
