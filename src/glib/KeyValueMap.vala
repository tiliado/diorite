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

public class KeyValueMap: GLib.Object, KeyValueStorage
{
	public Drt.Lst<PropertyBinding> property_bindings {get; protected set;}
	protected HashTable<string, Variant> values;
	protected HashTable<string, Variant> default_values;
	
	public KeyValueMap(HashTable<string, Variant>? default_values=null,
		HashTable<string, Variant>? values=null)
	{
		property_bindings = new Drt.Lst<PropertyBinding>();
		this.values = values ?? new HashTable<string, Variant>(str_hash, str_equal);
		this.default_values = default_values ?? new HashTable<string, Variant>(str_hash, str_equal);
	}
	
	public bool has_key(string key)
	{
		return key in values;
	}
	
	public async bool has_key_async(string key) {
		yield EventLoop.resume_later();
		return has_key(key);
	}
	
	public Variant? get_value(string key)
	{
		Variant? value = null;
		if (values.lookup_extended(key, null, out value))
			return value;
		return default_values[key];
	}
	
	public async Variant? get_value_async(string key) {
		yield EventLoop.resume_later();
		return get_value(key);
	}
	
	public void unset(string key)
	{
		var old_value = get_value(key);
		if (values.remove(key))
			changed(key, old_value);
	}
	
	public async void unset_async(string key) {
		unset(key);
		yield EventLoop.resume_later();
	}
	
	protected void set_value_unboxed(string key, Variant? value)
	{
		var old_value = get_value(key);
		values[key] = value;
		if (old_value != value && (old_value == null || value == null || !old_value.equal(value)))
			changed(key, old_value);
	}
	
	protected async void set_value_unboxed_async(string key, Variant? value) {
		set_value_unboxed(key, value);
		yield EventLoop.resume_later();
	}
	
	protected void set_default_value_unboxed(string key, Variant? value)
	{
		default_values[key] = value;
	}
	
	protected async void set_default_value_unboxed_async(string key, Variant? value) {
		set_default_value_unboxed(key, value);
		yield EventLoop.resume_later();
	}
}

} // namespace Drt

