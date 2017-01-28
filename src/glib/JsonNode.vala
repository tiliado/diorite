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
 * JSON Node object is a base object for JSON objects, arrays, strings, numbers, boolean and null values.
 */
public abstract class JsonNode
{
	/**
	 * The parent node.
	 */
	public weak JsonNode? parent = null;
	
	/**
	 * Creates new JSON Node object.
	 */
	protected JsonNode()
	{
	}
	
	/**
	 * Check whether this node represents any of JSON value types
	 * a string, a number, a boolean or the null value).
	 * 
	 * {{{
	 * Drt.JsonNode node = get_node();
	 * if (node.is_value())
	 *     stdout.printf("Value node: %s\n", ((Drt.JsonValue) node).value_type.to_string());
	 * }}}
	 * 
	 * @return `true` if this node represents a JSON value type
	 */
	public bool is_value()
	{
		return this is JsonValue;
	}
	
	/**
	 * Check whether this node represents the JSON null value.
	 * 
	 * {{{
	 * Drt.JsonNode node = get_node();
	 * if (node.is_null())
	 *     stdout.puts("OMG! A null node!\n");
	 * }}}
	 *  
	 * @return `true` if this node represents the JSON null value
	 */
	public bool is_null()
	{
		return this is JsonValue && ((JsonValue) this).value_type == JsonValueType.NULL;
	}
	
	/**
	 * Check whether this node represents a JSON boolean value.
	 * 
	 * {{{
	 * Drt.JsonNode node = get_node();
	 * if (node.is_bool())
	 *     stdout.printf("Boolean node: %s\n", ((Drt.JsonValue) node).get_bool().to_string());
	 * }}}
	 * 
	 * @return `true` if this node represents a JSON boolean value
	 */
	public bool is_bool()
	{
		return this is JsonValue && ((JsonValue) this).value_type == JsonValueType.BOOLEAN;
	}
	
	/**
	 * Check whether this node represents a JSON number value of an integer type.
	 * 
	 * {{{
	 * Drt.JsonNode node = get_node();
	 * if (node.is_int())
	 *     stdout.printf("Integer node: %d\n", ((Drt.JsonValue) node).get_int());
	 * }}}
	 * 
	 * @return `true` if this node represents a JSON number value of an integer type.
	 */
	public bool is_int()
	{
		return this is JsonValue && ((JsonValue) this).value_type == JsonValueType.INTEGER;
	}
	
	/**
	 * Check whether this node represents a JSON number value of a double type.
	 * 
	 * {{{
	 * Drt.JsonNode node = get_node();
	 * if (node.is_double())
	 *     stdout.printf("Double node: %f\n", ((Drt.JsonValue) node).get_double());
	 * }}}
	 * 
	 * @return `true` if this node represents a JSON number value of a double type.
	 */
	public bool is_double()
	{
		return this is JsonValue && ((JsonValue) this).value_type == JsonValueType.DOUBLE;
	}
	
	/**
	 * Check whether this node represents a JSON string value.
	 * 
	 * {{{
	 * Drt.JsonNode node = get_node();
	 * if (node.is_string())
	 *     stdout.printf("String node: %s\n", ((Drt.JsonValue) node).get_string());
	 * }}}
	 *  
	 * @return `true` if this node represents a JSON string value.
	 */
	public bool is_string()
	{
		return this is JsonValue && ((JsonValue) this).value_type == JsonValueType.STRING;
	}
	
	/**
	 * Check whether this node represents a JSON object.
	 * 
	 * @return `true` if this node represents a JSON object.
	 */
	public bool is_object()
	{
		return this is JsonObject;
	}
	
	/**
	 * Check whether this node represents a JSON array.
	 * 
	 * @return `true` if this node represents a JSON array.
	 */
	public bool is_array()
	{
		return this is JsonArray;
	}
	
	/**
	 * Return a string representation of the node.
	 * 
	 * @return a string representation of the node
	 */
	public abstract string to_string();
}

} // namespace Drt
