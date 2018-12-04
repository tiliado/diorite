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

namespace Drt {

public abstract class KeyValueStorage: GLib.Object {
    protected SList<PropertyBinding> property_bindings = null;

    public signal void changed(string key, Variant? old_value);

    public abstract async bool has_key_async(string key);

    public abstract bool has_key(string key);

    public abstract async Variant? get_value_async(string key);

    public abstract Variant? get_value(string key);

    public abstract async void unset_async(string key);

    public abstract void unset(string key);

    protected abstract async void set_default_value_unboxed_async(string key, Variant? value);

    protected abstract void set_default_value_unboxed(string key, Variant? value);

    protected abstract async void set_value_unboxed_async(string key, Variant? value);

    protected abstract void set_value_unboxed(string key, Variant? value);

    public async void set_value_async(string key, Variant? value) {
        yield set_value_unboxed_async(key, VariantUtils.unbox(value));
    }

    public void set_value(string key, Variant? value) {
        set_value_unboxed(key, VariantUtils.unbox(value));
    }

    public async void set_default_value_async(string key, Variant? value) {
        yield set_default_value_unboxed_async(key, VariantUtils.unbox(value));
    }

    public void set_default_value(string key, Variant? value) {
        set_default_value_unboxed(key, VariantUtils.unbox(value));
    }

    public bool get_bool(string key) {
        bool result;
        return VariantUtils.get_bool(get_value(key), out result) ? result : false;
    }

    public int64 get_int64(string key) {
        int64 result;
        return VariantUtils.get_int64(get_value(key), out result) ? result : 0;
    }

    public double get_double(string key) {
        double result;
        return VariantUtils.get_number(get_value(key), out result) ? result : 0.0;
    }

    public string? get_string(string key) {
        string? result;
        return VariantUtils.get_string(get_value(key), out result) ? (owned) result : null;
    }

    public void set_string(string key, string? value) {
        set_value(key, value != null ? new Variant.string(value) : null);
    }

    public void set_int64(string key, int64 value) {
        set_value(key, new Variant.int64(value));
    }

    public void set_bool(string key, bool value) {
        set_value(key, new Variant.boolean(value));
    }

    public void set_double(string key, double value) {
        set_value(key, new Variant.double(value));
    }

    public PropertyBinding? bind_object_property(string key, GLib.Object object, string property_name,
        PropertyBindingFlags flags=PropertyBindingFlags.BIDIRECTIONAL) {
        unowned ParamSpec? property = object.get_class().find_property(property_name);
        return_val_if_fail(property != null, null);
        var binding = new PropertyBinding(this, make_full_key(key, property_name), object, property, flags);
        property_bindings.prepend(binding);
        return binding;
    }

    public void unbind_object_property(string key, GLib.Object object, string property_name) {
        PropertyBinding? binding = get_property_binding(key, object, property_name);
        if (binding != null) {
            remove_property_binding(binding);
        }
    }

    public PropertyBinding? get_property_binding(string key, GLib.Object object,
        string property_name) {
        string full_key = make_full_key(key, property_name);
        foreach (unowned PropertyBinding binding in property_bindings) {
            if (binding.object == object && binding.key == full_key
            && binding.property.name == property_name) {
                return binding;
            }
        }
        return null;
    }

    public void remove_property_binding(PropertyBinding binding) {
        property_bindings.remove(binding);
    }

    private string make_full_key(string key, string property_name) {
        return key[key.length -1 ] != '.' ? key : key + property_name.replace("-", "_");
    }
}

} // namespace Drt
