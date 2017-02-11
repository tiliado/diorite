/*
 * Copyright 2017 Jiří Janoušek <janousek.jiri@gmail.com>
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
 * JsonBuilder is used to build and possibly to serialize a new Json document.
 */
public class JsonBuilder
{
	/** Root node*/
	public JsonNode? root {get; private set; default = null;}
	private JsonNode? cursor = null;
	private JsonObject? object = null;
	private JsonArray? array = null;
	private string? member = null;
	
	/**
	 * Creates a new empty JsonBuilder object
	 */
	public JsonBuilder()
	{
	}
	
	/**
	 * Start a new object at the current context
	 * 
	 * Calls of {@link begin_object} and {@link end_object} must match.
	 * 
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder begin_object()
	{
		var new_object = new JsonObject();
		if (try_add(new_object))
			set_cursor(new_object);
		return this;
	}
	
	/**
	 * Close an object at current cursor.
	 * 
	 * Cannot be called anfter {@link set_member}.
	 * Calls of {@link begin_object} and {@link end_object} must match.
	 * 
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder end_object()
	{
		if (object == null)
			critical("Cursor is not at an object.");
		else if (member != null)
			critical("There is a member without any value.");
		else
			set_cursor(object.parent);
		return this;
	}
	
	/**
	 * Start a new array at the current context
	 * 
	 * Calls of {@link begin_array} and {@link end_array} must match.
	 * 
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder begin_array()
	{
		var new_array = new JsonArray();
		if (try_add(new_array))
			set_cursor(new_array);
		return this;
	}
	
	/**
	 * Close an array at current cursor.
	 * 
	 * Calls of {@link begin_array} and {@link end_array} must match.
	 * 
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder end_array()
	{
		if (array == null)
			critical("Cursor is not at an array.");
		else
			set_cursor(array.parent);
		return this;
	}
	
	/**
	 * Set member name of an object.
	 * 
	 * If called inside an object, sets the name of the member to be added next.
	 * 
	 * @param name    the member name
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder set_member(string name)
	{
		if (object == null)
			critical("Cannot set member name for non-object node.");
		else
			member = name;
		return this;
	}
	
	/**
	 * Add a new node to an array or object.
	 * 
	 * If it is called inside an array, appends a new node to the end of it.
	 * If it is called inside and object after the member name has been set,
	 * sets a new node as the member.
	 *
	 * @param node    the node to add
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder add(JsonNode node)
	{
		try_add(node);
		return this;
	}
	
	/**
	 * Add a new boolean value to an array or object.
	 * 
	 * If it is called inside an array, appends a new boolean value to the end of it.
	 * If it is called inside and object after the member name has been set,
	 * sets a new boolean value as the member.
	 *
	 * @param bool_value    the boolean value to add
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder add_bool(bool bool_value)
	{
		return add(new JsonValue.@bool(bool_value));
	}
	
	/**
	 * Add a new integer value to an array or object.
	 * 
	 * If it is called inside an array, appends a new integer value to the end of it.
	 * If it is called inside and object after the member name has been set,
	 * sets a new integer value as the member.
	 *
	 * @param int_value    the integer value to add
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder add_int(int int_value)
	{
		return add(new JsonValue.@int(int_value));
	}	
	
	/**
	 * Add a new double value to an array or object.
	 * 
	 * If it is called inside an array, appends a new double value to the end of it.
	 * If it is called inside and object after the member name has been set,
	 * sets a new double value as the member.
	 *
	 * @param double_value    the double value to add
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder add_double(double double_value)
	{
		return add(new JsonValue.@double(double_value));
	}	
	
	/**
	 * Add a new string value to an array or object.
	 * 
	 * If it is called inside an array, appends a new string value to the end of it.
	 * If it is called inside and object after the member name has been set,
	 * sets a new string value as the member.
	 *
	 * @param string_value    the string value to add
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder add_string(string string_value)
	{
		return add(new JsonValue.@string(string_value));
	}
	
	/**
	 * Add a new formatted string value to an array or object.
	 * 
	 * If it is called inside an array, appends a new string value to the end of it.
	 * If it is called inside and object after the member name has been set,
	 * sets a new string value as the member.
	 *
	 * @param format    the format string of the value to add
	 * @param ...       Printf parameters
	 * @return this JsonBuilder object for easier chaining
	 */
	[PrintFormat]
	public unowned JsonBuilder add_printf(string format, ...)
	{
		return add(new JsonValue.@string(format.vprintf(va_list())));
	}
	
	/**
	 * Add `null` value to an array or object.
	 * 
	 * If it is called inside an array, appends a new `null` value to the end of it.
	 * If it is called inside and object after the member name has been set, sets `null` as the member.
	 *
	 * @return this JsonBuilder object for easier chaining
	 */
	public unowned JsonBuilder add_null()
	{
		return add(new JsonValue.@null());
	}
	
	/**
	 * Reset the builder to the initial state
	 */
	public void reset()
	{
		root = null;
		cursor = null;
		object = null;
		array = null;
		member = null;
	}
	
	/**
	 * Return string representation of the root node.
	 * 
	 * @return a string representation of the root node
	 */
	public string to_string()
	{
		if (root == null)
			return "";
		return root.to_string();
	}
	
	/**
	 * Return a pretty string representation of the root node.
	 * 
	 * @return a string representation of the root node
	 */
	public string to_pretty_string()
	{
		if (root == null)
			return "";
		var array = root as JsonArray;
		if (array != null)
			return array.to_pretty_string();
		var object = root as JsonObject;
		if (object != null)
			return object.to_pretty_string();
		return root.to_string();
	}
	
	/**
	 * Return a compact string representation of the root node.
	 * 
	 * @return a string representation of the root node
	 */
	public string to_compact_string()
	{
		if (root == null)
			return "";
		var array = root as JsonArray;
		if (array != null)
			return array.to_compact_string();
		var object = root as JsonObject;
		if (object != null)
			return object.to_compact_string();
		return root.to_string();
	}	
	
	private bool try_add(JsonNode node)
	{
		if (root == null)
		{
			if (node is JsonValue)
			{
				critical("The root node can be only an object or an array.");
				return false;
			}
			root = node;
		}
		else if (array != null)
		{
			array.append(node);
		}
		else if (object != null)
		{
			if (member == null)
			{
				critical("Member name not set.");
				return false;
			}
			object[member] = node;
			member = null;
		}
		else
		{
			critical("Cannot add a new node in this context");
			return false;
		}
		return true;
	}
	
	private void set_cursor(JsonNode? node)
	{
		cursor = node;
		if (node != null)
		{
			array = node as JsonArray;
			object = node as JsonObject;
		}
		else
		{
			object = null;
			array = null;
		}
		member = null;
	}
}

} // namespace Drt
