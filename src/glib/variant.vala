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

public string[] variant_to_strv(Variant variant)
{
	string[] result;
	if (variant.is_container() && variant.n_children() > 0)
	{
		var size = variant.n_children();
		result = new string[size];
		for (size_t i = 0; i < size; i++)
		{
			var child = variant.get_child_value(i);
			string? str;
			if (!variant_string(child, out str) || str == null)
			{
				warning("Wrong child type %s: %s", child.get_type_string(), child.print(true));
				str = child.print(false);
			}
			result[i] = str;
		}
	}
	else
	{
		if (!variant.is_container())
			warning("Variant is not a container: %s: %s", variant.get_type_string(), variant.print(true));
		
		result = {};
	}
	return result;
}

public Variant[] variant_to_array(Variant variant)
{
	Variant[] result;
	if (variant.is_container() && variant.n_children() > 0)
	{
		
		var size = variant.n_children();
		result = new Variant[size];
		for (size_t i = 0; i < size; i++)
		{
			var val = variant.get_child_value(i);
			if (val.is_of_type(VariantType.VARIANT))
				val = val.get_variant();
			result[i] = val;
		}
	}
	else
	{
		result = {};
	}
	return result;
}

public HashTable<string, Variant> variant_to_hashtable(Variant variant)
{
	var result = new HashTable<string, Variant>(str_hash, str_equal);
	if (variant.is_of_type(VariantType.DICTIONARY))
	{
		var iter = variant.iterator();
		Variant? val = null;
		string? key = null;
		while (iter.next("{s*}", &key, &val))
			if (key != null)
			{
				
				if (val.is_of_type(VariantType.MAYBE))
					val = val.get_maybe();
				if (val.is_of_type(VariantType.VARIANT))
					val = val.get_variant();
				result.insert(key, val);
			}
	}
	else
	{
		critical("Wrong type: %s %s", variant.get_type_string(), variant.print(true));
	}
	return result;
}

public Variant variant_from_hashtable(HashTable<string, Variant> hashtable)
{
	var builder = new VariantBuilder(new VariantType("a{sv}"));
	foreach (var key in hashtable.get_keys())
		builder.add("{sv}", key, hashtable.get(key));
	return builder.end ();
}

/**
 * Extract string from variant with unboxing and data type checking.
 */
public bool variant_string(Variant variant, out string? data)
{
	if (variant.is_of_type(VariantType.STRING))
	{
		data = variant.get_string();
		return true;
	}
	
	if (variant.get_type().is_subtype_of(VariantType.MAYBE))
	{
		Variant? maybe_variant = null;
		variant.get("m*", &maybe_variant);
		if (maybe_variant == null)
		{
			data = null;
			return true;
		}
		return variant_string(maybe_variant, out data);
	}
	
	if (variant.is_of_type(VariantType.VARIANT))
		return variant_string(variant.get_variant(), out data);
	
	data = null;
	return false;
}

public bool variant_bool(Variant? variant, ref bool result)
{
	if (variant == null)
		return false;
	
	if (variant.is_of_type(VariantType.BOOLEAN))
	{
		result = variant.get_boolean();
		return true;
	}
	
	if (variant.get_type().is_subtype_of(VariantType.MAYBE))
	{
		Variant? maybe_variant = null;
		variant.get("m*", &maybe_variant);
		return variant_bool(maybe_variant, ref result);
	}
	
	if (variant.is_of_type(VariantType.VARIANT))
		return variant_bool(variant.get_variant(), ref result);
	
	return false;
}

public static string? variant_dict_str(Variant dict, string key)
{
	var val = dict.lookup_value(key, null);
	if (val == null)
		return null;
	
	if (val.is_of_type(VariantType.MAYBE))
	{
		val = val.get_maybe();
		if (val == null)
			return null;
	}
		
	if (val.is_of_type(VariantType.VARIANT))
		val = val.get_variant();
	if (val.is_of_type(VariantType.STRING))
		return val.get_string();
	return null;
}

} // namespace Diorite
