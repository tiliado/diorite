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

/**
 * Class containing parameters of a method call.
 * 
 * Parameters are returned in same order as in parameters specification in method declaration.
 */
public class ApiParams
{
	private ApiMethod method;
	private Variant?[] data;
	private int counter = 0;
	
	public ApiParams(ApiMethod method, Variant?[] data)
	{
		this.method = method;
		this.data = data;
	}
	
	/**
	 * Returns index of the current parameter under cursor.
	 * 
	 * @return Index of a parameter.
	 */
	public int get_current_index()
	{
		return counter;
	}
	
	/**
	 * Returns number of parameters available
	 * 
	 * @return Number of a parameter.
	 */
	public int get_length()
	{
		return data.length;
	}
	
	/**
	 * Reset parameter index back to 1.
	 */
	public void reset()
	{
		counter = 0;
	}
	
	/**
	 * Return string value and advance cursor.
	 * 
	 * Aborts on invalid time or out of bounds access.
	 * 
	 * @return string value or null.
	 */
	public string? pop_string()
	{
		var variant = next(typeof(StringParam));
		return variant == null ? null : variant.get_string();;
	}
	
	/**
	 * Return boolean value and advance cursor.
	 * 
	 * Aborts on invalid time or out of bounds access.
	 * 
	 * @return boolean value.
	 */
	public bool pop_bool()
	{
		return next(typeof(BoolParam)).get_boolean();
	}
	
	/**
	 * Return double value and advance cursor.
	 * 
	 * Aborts on invalid time or out of bounds access.
	 * 
	 * @return double value.
	 */
	public double pop_double()
	{
		return next(typeof(DoubleParam)).get_double();
	}
	
	/**
	 * Return string[] value and advance cursor.
	 * 
	 * Aborts on invalid time or out of bounds access.
	 * 
	 * @return string[] value. May be empty, but not null.
	 */
	public string[] pop_strv()
	{
		var variant = next(typeof(StringArrayParam));
		return variant == null ? new string[]{} : variant.dup_strv();
	}
	
	/**
	 * Return dictionary and advance cursor.
	 * 
	 * Aborts on invalid time or out of bounds access.
	 * 
	 * @return a dictionary. May be empty but not null.
	 */
	public HashTable<string, Variant?> pop_dict()
	{
		return Diorite.variant_to_hashtable(next(typeof(DictParam)));
	}
	
	private Variant? next(Type param_type)
	{
		var index = counter++;
		if (index >= data.length)
			error(
				"Method '%s' receives only %d arguments. Access to index %d denied.",
				method.path, data.length, index);
		var param =  method.params[index];
		if (Type.from_instance(param) != param_type)
			error(
				"The parameter %d of method '%s' is of type '%s' but %s value requested.",
				index, method.path, Type.from_instance(param).name(), param_type.name());
		return Diorite.unbox_variant(data[index]);
	}
}

public abstract class ApiParam
{
	public string name {get; protected set; default = null;}
	public bool nullable {get; protected set; default = false;}
	public bool required {get; protected set; default = true;}
	public Variant? default_value {get; protected set; default = null;}
	public string type_string {get; protected set; default = null;}
	public string? description {get; protected set; default = null;}
	
	public ApiParam(string name, bool required, bool nullable, Variant? default_value, string type_string,
		string? description)
	{
		this.name = name;
		this.nullable = nullable;
		this.required = required;
		this.default_value = default_value;
		this.type_string = type_string;
		this.description = description;
	}
	
	public virtual Variant? get_value(string path, Variant? value) throws ApiError
	{
		if (value == null)
		{
			if (nullable)
				return null;
			if (default_value == null)
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' requires the '%s' parameter of type '%s', but null value has been provided.",
					path, name, type_string);
			return default_value;
		}
		if (!value.is_of_type(new VariantType(type_string)))
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires the '%s' parameter of type '%s', but value of type '%s' has been provided.",
				path, name, type_string, value.get_type_string());
		return value;
	}
}

public class StringParam: ApiParam
{
	/** 
	 * Creates new parameter of type string.
	 * 
	 * The parameter name `name` is used in a key-value representation of parameters and in documentation.
	 * 
	 * The default value `default_value` is used at several circumstances: 
	 * 
	 *   * If `required` is set to `false` and the parameter hasn't been provided at all (e.g. in a key-value
	 *     representation of parameters), the `default_value` is used instead.
	 *   * If `nullable` is set to `false` and a null value is provided, it is replaced with the
	 *     `default_value`.
	 *   * However, if `nullable` is `false` and the `default_value` to be used is null, error is reported to
	 *     the API caller.
	 * 
	 * @param name             Parameter name. 
	 * @param required         If `true`, parameter must be always specified and error is reported to the API
	 *                         caller otherwise.
	 * @param nullable         If `true`, the parameter can have `null` value. Otherwise, error is reported to
	 *                         the API caller if both the provided value and `default_value` are null.
	 * @param default_value    The default value is used at several circumstances as described above.
	 * @param description      Description of this parameter for API consumers.
	 */ 
	public StringParam(string name, bool required, bool nullable,
		string? default_value=null, string? description=null)
	{
		base(name, required, nullable, default_value == null ? null : new Variant.string(default_value),
			"s", description);
	}
}

public class BoolParam: ApiParam
{
	/** 
	 * Creates new parameter of type boolean.
	 * 
	 * The parameter name `name` is used in a key-value representation of parameters and in documentation.
	 * 
	 * If `required` is set to `false` and the parameter hasn't been provided at all (e.g. in a key-value
	 * representation of parameters), the `default_value` is used instead. However, if the `default_value`
	 * to be used is null, error is reported to the API caller.
	 * 
	 * @param name             Parameter name. 
	 * @param required         If `true`, parameter must be always specified and error is reported to the API
	 *                         caller otherwise.
	 * @param default_value    The default value is used at several circumstances as described above.
	 * @param description      Description of this parameter for API consumers.
	 */
	public BoolParam(string name, bool required,
		Variant? default_value=null, string? description=null)
	{
		base(name, required, false, default_value, "b", description);
	}
}

public class DoubleParam: ApiParam
{
	/** 
	 * Creates new parameter of type double.
	 * 
	 * The parameter name `name` is used in a key-value representation of parameters and in documentation.
	 * 
	 * If `required` is set to `false` and the parameter hasn't been provided at all (e.g. in a key-value
	 * representation of parameters), the `default_value` is used instead. However, if the `default_value`
	 * to be used is null, error is reported to the API caller.
	 * 
	 * @param name             Parameter name. 
	 * @param required         If `true`, parameter must be always specified and error is reported to the API
	 *                         caller otherwise.
	 * @param default_value    The default value is used at several circumstances as described above.
	 * @param description      Description of this parameter for API consumers.
	 */
	public DoubleParam(string name, bool required,
		Variant? default_value=null, string? description=null)
	{
		base(name, required, false, default_value, "d", description);
	}
}

public class StringArrayParam: ApiParam
{
	/** 
	 * Creates new parameter of type string[].
	 * 
	 * The parameter name `name` is used in a key-value representation of parameters and in documentation.
	 * 
	 * If `required` is set to `false` and the parameter hasn't been provided at all (e.g. in a key-value
	 * representation of parameters), the `default_value` is used instead. However, if the `default_value`
	 * to be used is null, error is reported to the API caller.
	 * 
	 * If null value is provided, it is considered as empty array.
	 * 
	 * @param name             Parameter name. 
	 * @param required         If `true`, parameter must be always specified and error is reported to the API
	 *                         caller otherwise.
	 * @param default_value    The default value is used at several circumstances as described above.
	 * @param description      Description of this parameter for API consumers.
	 */
	public StringArrayParam(string name, bool required,
		Variant? default_value=null, string? description=null)
	{
		base(name, required, true, default_value, "as", description);
	}
	
	public override Variant? get_value(string path, Variant? value) throws ApiError
	{
		if (value == null)
		{
			if (nullable)
				return null;
			if (default_value == null)
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' requires the '%s' parameter of type '%s', but null value has been provided.",
					path, name, type_string);
			return default_value;
		}
		
		if (value.is_of_type(new VariantType(type_string)))
			return value;
			
		if (!value.is_of_type(new VariantType("av")))
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires the '%s' parameter of type '%s', but value of type '%s' have been provided.",
				path, name, type_string, value.get_type_string());
		
		var builder = new VariantBuilder(VariantType.STRING_ARRAY);
		var size = value.n_children();
		for (var i = 0; i < size; i++)
		{
			var child = Diorite.unbox_variant(value.get_child_value(i));
			if (child == null)
				child = new Variant.string("");
			if (!child.is_of_type(VariantType.STRING))
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' requires the '%s' parameter of type '%s', but the child value of type '%s' have been provided.",
					path, name, type_string, child.get_type_string());
			builder.add_value(child);
		}
		return builder.end();
	}
}

public class DictParam: ApiParam
{
	/** 
	 * Creates new parameter of type HashTable<string, Variant>.
	 * 
	 * The parameter name `name` is used in a key-value representation of parameters and in documentation.
	 * 
	 * If `required` is set to `false` and the parameter hasn't been provided at all (e.g. in a key-value
	 * representation of parameters), the `default_value` is used instead. However, if the `default_value`
	 * to be used is null, error is reported to the API caller.
	 * 
	 * If null value is provided, it is considered as an empty hash table.
	 * 
	 * @param name             Parameter name. 
	 * @param required         If `true`, parameter must be always specified and error is reported to the API
	 *                         caller otherwise.
	 * @param default_value    The default value is used at several circumstances as described above.
	 * @param description      Description of this parameter for API consumers.
	 */
	public DictParam(string name, bool required,
		Variant? default_value=null, string? description=null)
	{
		base(name, required, true, default_value, "a{smv}", description);
	}
	
	public override Variant? get_value(string path, Variant? value) throws ApiError
	{
		if (value == null)
		{
			if (nullable)
				return null;
			if (default_value == null)
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' requires the '%s' parameter of type '%s', but null value has been provided.",
					path, name, type_string);
			return default_value;
		}
		
		if (!value.is_of_type(new VariantType(type_string)))
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires the '%s' parameter of type '%s', but value of type '%s' have been provided.",
				path, name, type_string, value.get_type_string());
		return value;
	}
}

} // namespace Drt
