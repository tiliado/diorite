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
	public abstract SingleList<PropertyBinding> property_bindings {get; protected set;}
	
	public signal void changed(string key, Variant? old_value);
	
	public abstract bool has_key(string key);
	
	public abstract Variant? get_value(string key);
	
	public abstract void unset(string key);
	
	protected abstract void set_default_value_unboxed(string key, Variant? value);
	
	protected abstract void set_value_unboxed(string key, Variant? value);
	
	public void set_value(string key, Variant? value)
	{
		set_value_unboxed(key, unbox_variant(value));
	}
	
	public void set_default_value(string key, Variant? value)
	{
		set_default_value_unboxed(key, unbox_variant(value));
	}
	
	public bool get_bool(string key)
	{
		return variant_to_bool(get_value(key));
	}
	
	public int64 get_int64(string key)
	{
		return variant_to_int64(get_value(key));
	}
	
	public double get_double(string key)
	{
		return variant_to_double(get_value(key));
	}
	
	public string? get_string(string key)
	{
		return variant_to_string(get_value(key), null);
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
	
	public void bind_object_property(string key, GLib.Object object, string property_name,
		PropertyBindingFlags flags=PropertyBindingFlags.BIDIRECTIONAL)
	{
		var property = object.get_class().find_property(property_name);
		return_if_fail(property != null);
		property_bindings.prepend(new PropertyBinding(this, key, object, property, flags));
	}
	
	public void unbind_object_property(string key, GLib.Object object, string property_name)
	{
		var binding = get_property_binding(key, object, property_name);
		if (binding != null)
			remove_property_binding(binding);
	}
	
	public PropertyBinding? get_property_binding(string key, GLib.Object object,
		string property_name)
	{
		foreach (var binding in property_bindings)
			if (binding.object == object && binding.key == key
			&& binding.property.name == property_name)
				return binding;
		return null;
	}
	
	public void remove_property_binding(PropertyBinding binding)
	{
		property_bindings.remove(binding);
	}
}

} // namespace Diorite
