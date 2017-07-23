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
 * JSON Object object
 */
public class JsonObject: JsonNode
{
	private HashTable<string, JsonNode?> nodes;
	
	/**
	 * Creates a new empty JSON object.
	 */
	public JsonObject()
	{
		nodes = new HashTable<string, JsonNode?>(str_hash, str_equal);
	}
	
	/**
	 * Add object member.
	 * 
	 * @param name    the member name
	 * @param node    the member
	 */
	public void set(string name, JsonNode node)
	{
		return_if_fail(node.parent == null);
		var old_node = get(name);
		nodes[name] = node;
		node.parent = this;
		if (old_node != null)
			old_node.parent = null;
	}
	
	/**
	 * Remove a member from object
	 * 
	 * @param name    the member name
	 * @return `true` if the member has been found and thus removed from the object, `false` otherwise
	 */
	public bool remove(string name)
	{
		return take(name) != null;
	}
	
	/**
	 * Take a member from object
	 * 
	 * @param name    the member name
	 * @return the member if it has been found and thus removed from the object, `null` otherwise
	 */
	public JsonNode? take(string name)
	{
		var node = nodes.take(name, null);
		if (node != null)
			node.parent = null;
		return node;
	}
	
	/**
	 * Get a member from the object
	 * 
	 * @param name    the member name
	 * @return the member if it has been found, `null` otherwise
	 */
	public unowned JsonNode? get(string name)
	{
		return nodes[name];
	}
	
	/**
	 * Gets a node at the given dot-path
	 * 
	 * The dot-path consists of dot-separated object member names and array element indexes, e.g.
	 * `cars.0.color` corresponds to the JavaScript notation `this.cars[0].color`.
	 * 
	 * @param path    the dot-path of the node to get
	 * @return the requested node if found else `null`
	 */
	public unowned JsonNode? dotget(string path)
	{
		var dot = path.index_of_char('.');
		return_val_if_fail(dot != 0, null);
		if (dot < 0)
			return path[0] != 0 ? get(path) : null;
		unowned JsonNode? node = get(path.substring(0, dot));
		if (node == null)
			return null;
		unowned string subpath = (string) (((char*) path) + dot + 1);
		if (node is JsonObject)
			return ((JsonObject) node).dotget(subpath);
		else if (node is JsonArray)
			return ((JsonArray) node).dotget(subpath);
		else
			return null;
	}
	
	/**
	 * Gets a boolean value of the given member name.
	 * 
	 * @param name     the member name of the node to get
	 * @param result   the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.BOOLEAN}
	 *     and so the `result` is valid, `false` otherwise
	 */
	public bool get_bool(string name, out bool result)
	{
		var node = get(name) as JsonValue;
		if (node == null)
		{
			result = false;
			return false;
		}
		return node.try_bool(out result);
	}
	
	/**
	 * Gets a boolean value of the given member name or a default value.
	 * 
	 * @param name     the member name of the node to get
	 * @return the actual boolean value if the node is found and is of type {@link JsonValueType.BOOLEAN},
	 *     the `default_value` otherwise.
	 */
	public bool get_bool_or(string name, bool default_value=false)
	{
		bool result;
		return get_bool(name, out result) ? result : default_value;
	}
	
	/**
	 * Gets a boolean value at the given dot-path
	 * 
	 * The dot-path consists of dot-separated object member names and array element indexes, e.g.
	 * `cars.0.color` corresponds to the JavaScript notation `this.cars[0].color`.
	 * 
	 * @param path    the dot-path of the node to get
	 * @param result   the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.BOOLEAN} and so the `result` is valid
	 */
	public bool dotget_bool(string path, out bool result)
	{
		var node = dotget(path) as JsonValue;
		if (node == null)
		{
			result = false;
			return false;
		}
		return node.try_bool(out result);
	}
	
	/**
	 * Gets an integer number value of the given member name.
	 * 
	 * @param name     the member name of the node to get
	 * @param result   the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.INTEGER}
	 *     and so the `result` is valid, `false` otherwise
	 */
	public bool get_int(string name, out int result)
	{
		var node = get(name) as JsonValue;
		if (node == null)
		{
			result = 0;
			return false;
		}
		return node.try_int(out result);
	}
	
	/**
	 * Gets an integer number value of the given member name or a default value.
	 * 
	 * @param name     the member name of the node to get
	 * @return the actual integer number value if the node is found and is of type
	 *     {@link JsonValueType.BOOLEAN}, the `default_value` otherwise.
	 */
	public int get_int_or(string name, int default_value=0)
	{
		int result;
		return get_int(name, out result) ? result : default_value;
	}
	
	/**
	 * Gets an integer number value at the given dot-path
	 * 
	 * The dot-path consists of dot-separated object member names and array element indexes, e.g.
	 * `cars.0.color` corresponds to the JavaScript notation `this.cars[0].color`.
	 * 
	 * @param path      the dot-path of the node to get
	 * @param result    the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.INTEGER} and so the `result` is valid
	 */
	public bool dotget_int(string path, out int result)
	{
		var node = dotget(path) as JsonValue;
		if (node == null)
		{
			result = 0;
			return false;
		}
		return node.try_int(out result);
	}
	
	/**
	 * Gets a floating point number value of the given member name.
	 * 
	 * @param name     the member name of the node to get
	 * @param result   the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.DOUBLE}
	 *     and so the `result` is valid, `false` otherwise
	 */
	public bool get_double(string name, out double result)
	{
		var node = get(name) as JsonValue;
		if (node == null)
		{
			result = 0.0;
			return false;
		}
		return node.try_double(out result);
	}
	
	/**
	 * Gets a floating point number value of the given member name or a default value.
	 * 
	 * @param name     the member name of the node to get
	 * @return the actual floating point number value if the node is found and is of type
	 *     {@link JsonValueType.DOUBLE}, the `default_value` otherwise.
	 */
	public double get_double_or(string name, double default_value=0.0)
	{
		double result;
		return get_double(name, out result) ? result : default_value;
	}
	
	/**
	 * Gets a floating point number value at the given dot-path
	 * 
	 * The dot-path consists of dot-separated object member names and array element indexes, e.g.
	 * `cars.0.color` corresponds to the JavaScript notation `this.cars[0].color`.
	 * 
	 * @param path      the dot-path of the node to get
	 * @param result    the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.DOUBLE} and so the `result` is valid
	 */
	public bool dotget_double(string path, out double result)
	{
		var node = dotget(path) as JsonValue;
		if (node == null)
		{
			result = 0.0;
			return false;
		}
		return node.try_double(out result);
	}
	
	/**
	 * Gets a string value of the given member name.
	 * 
	 * @param name     the member name of the node to get
	 * @param result   the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.STRING}
	 *     and so the `result` is valid, `false` otherwise
	 */
	public bool get_string(string name, out string? result)
	{
		var node = get(name) as JsonValue;
		if (node == null)
		{
			result = null;
			return false;
		}
		return node.try_string(out result);
	}
	
	/**
	 * Gets a string value of the given member name or a default value.
	 * 
	 * @param name     the member name of the node to get
	 * @return the actual string value if the node is found and is of type
	 *     {@link JsonValueType.STRING}, the `default_value` otherwise.
	 */
	public string? get_string_or(string name, string? default_value=null)
	{
		string? result;
		return get_string(name, out result) ? result : default_value;
	}
	
	/**
	 * Gets a string value at the given dot-path
	 * 
	 * The dot-path consists of dot-separated object member names and array element indexes, e.g.
	 * `cars.0.color` corresponds to the JavaScript notation `this.cars[0].color`.
	 * 
	 * @param path      the dot-path of the node to get
	 * @param result    the obtained value
	 * @return `true` if the node is found and is of type {@link JsonValueType.STRING} and so the `result` is valid
	 */
	public bool dotget_string(string path, out string result)
	{
		var node = dotget(path) as JsonValue;
		if (node == null)
		{
			result = null;
			return false;
		}
		return node.try_string(out result);
	}
	
	/**
	 * Gets a null value of the given member name.
	 * 
	 * @param name     the member name of the node to get
	 * @return `true` if the node is found and is of type {@link JsonValueType.NULL}, `false` otherwise
	 */
	public bool get_null(string name)
	{
		var node = get(name) as JsonValue;
		return node == null ? false : node.is_null();
	}
	
	/**
	 * Gets a JSON array of the given member name.
	 * 
	 * @param name    the member name of the node to get
	 * @return a {@link JsonArray} if the node is found and is an array, `null` otherwise
	 */
	public JsonArray? get_array(string name)
	{
		return get(name) as JsonArray;
	}
	
	/**
	 * Returns the content of a member as a boolean array
	 * 
	 * @param name          the member name of the node to get
	 * @param bool_array    the resulting boolean array
	 * @return `true` if the node is {@link JsonArray} and all array members are of type
	 *     {@link JsonValueType.BOOLEAN} and thus `result` is valid, `false` otherwise
	 */
	public bool get_bool_array(string name, out bool[] bool_array)
	{
		var array = get(name) as JsonArray;
		if (array == null)
		{
			bool_array = null;
			return false;
		}
		return array.as_bool_array(out bool_array);
	}
	
	/**
	 * Returns the content of a member as an integer array
	 * 
	 * @param name         the member name of the node to get
	 * @param int_array    the resulting integer array
	 * @return `true` if the node is {@link JsonArray} and all array members are of type
	 *     {@link JsonValueType.INTEGER} and thus `result` is valid, `false` otherwise
	 */
	public bool get_int_array(string name, out int[] int_array)
	{
		var array = get(name) as JsonArray;
		if (array == null)
		{
			int_array = null;
			return false;
		}
		return array.as_int_array(out int_array);
	}
	
	/**
	 * Returns the content of a member as a double array
	 * 
	 * @param name            the member name of the node to get
	 * @param double_array    the resulting double array
	 * @return `true` if the node is {@link JsonArray} and all array members are of type
	 *     {@link JsonValueType.DOUBLE} and thus `result` is valid, `false` otherwise
	 */
	public bool get_double_array(string name, out double[] double_array)
	{
		var array = get(name) as JsonArray;
		if (array == null)
		{
			double_array = null;
			return false;
		}
		return array.as_double_array(out double_array);
	}
	
	/**
	 * Returns content of a member as a string array
	 * 
	 * @param name            the member name of the node to get
	 * @param string_array    the resulting string array
	 * @return `true` if the node is {@link JsonArray} and all array members are of type
	 *     {@link JsonValueType.STRING} and thus `result` is valid, `false` otherwise
	 */
	public bool get_string_array(string name, out string[] string_array)
	{
		var array = get(name) as JsonArray;
		if (array == null)
		{
			string_array = null;
			return false;
		}
		return array.as_string_array(out string_array);
	}
	
	/**
	 * Gets a JSON object of the given member name.
	 * 
	 * @param name    the member name of the node to get
	 * @return a {@link JsonObject} if the node is found and is an object, `null` otherwise
	 */
	public JsonObject? get_object(string name)
	{
		return get(name) as JsonObject;
	}
	
	/**
	 * Return string representation of the node.
	 * 
	 * A convenience alias for `dump(null, false, 0). See {@link dump},
	 * 
	 * @return a string representation of the node
	 */
	public override string to_string()
	{
		return dump(null, false, 0);
	}
	
	/**
	 * Return a pretty string representation of the node.
	 * 
	 * A convenience alias for `dump("    ", false, 0). See {@link dump},
	 * 
	 * @return a string representation of the node
	 */
	public string to_pretty_string()
	{
		return dump("    ", false, 0);
	}
	
	/**
	 * Return a compact string representation of the node.
	 * 
	 * A convenience alias for `dump(null, true, 0). See {@link dump},
	 * 
	 * @return a string representation of the node
	 */
	public string to_compact_string()
	{
		return dump(null, true, 0);
	}
	
	/**
	 * Return a string representation of the node.
	 * 
	 * @param indent     A string to indent lines. If empty or null, no new lines and no indentation is used.
	 * @param compact    If `true`, no space after a comma or a colon is added.
	 * @param level      An initial indentation level.
	 * @return a string representation of the node
	 */
	public string dump(string? indent, bool compact, uint level=0)
	{
		var buffer = new StringBuilder();
		dump_to_buffer(buffer, indent, compact, level);
		return buffer.str;
	}
	
	/**
	 * Create a string representation of the node.
	 * 
	 * @param buffer     A bufer to dupm the string representation to.
	 * @param indent     A string to indent lines. If empty or null, no new lines and no indentation is used.
	 * @param compact    If `true`, no space after a comma or a colon is added.
	 * @param level      An initial indentation level.
	 */
	public void dump_to_buffer(StringBuilder buffer, string? indent, bool compact, uint level=0)
	{
		var nl = !String.is_empty(indent);
		var item_sep = (nl || compact) ? "," : ", ";
		var key_sep = compact ? ":" : ": ";
		buffer.append_c('{');
		if (nl)
			buffer.append_c('\n');
		var iter =  HashTableIter<string, JsonNode?>(nodes);
		unowned string? key = null;
		unowned JsonNode? node = null;
		var next = (iter.next(out key, out node) && key != null && node != null);
		while (next)
		{
			if (nl)
				for (var i = 0; i <= level; i++)
					buffer.append(indent);
			buffer.append_printf("\"%s\"%s", JsonValue.escape_string(key), key_sep);
			if (node is JsonArray)
				((JsonArray) node).dump_to_buffer(buffer, indent, compact, level + 1);
			else if (node is JsonObject)
				((JsonObject) node).dump_to_buffer(buffer, indent, compact, level + 1);
			else
				buffer.append(node.to_string());
			next = iter.next(out key, out node) && key != null && node != null;
			if (next)
				buffer.append(item_sep);
			if (nl)
				buffer.append_c('\n');
		}
		if (nl)
			for (var i = 0; i < level; i++)
				buffer.append(indent);
		buffer.append_c('}');
		if (nl && level == 0)
			buffer.append_c('\n');
	}
}

} // namespace Drt
