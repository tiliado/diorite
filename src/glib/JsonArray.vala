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
 * JSON Array object.
 */
public class JsonArray: JsonNode
{
    [Description(nick = "The length of the array", blurb = "The length of the array.")]
    public uint length {get{return nodes.length;}}
    private GLib.Array<JsonNode?> nodes;

    /**
     * Creates a new empty JSON Array object.
     */
    public JsonArray()
    {
        nodes = new GLib.Array<JsonNode?>(false, false);
    }

    /**
     * Set a node at index
     *
     * @param index    The index of a node to set
     * @param node     {@link JsonNode} to set
     */
    public void set(uint index, JsonNode node)
    {
        return_if_fail(index <= nodes.length);
        return_if_fail(node.parent == null);
        if (index == nodes.length)
        {
            nodes.append_val(node);
        }
        else
        {
            var current = get(index);
            if (current != null)
            current.parent = null;
            nodes.data[index] = node;
        }
        node.parent = this;
    }

    /**
     * Adds the node on to the end of the array.
     *
     * @param node    the node to append
     */
    public void append(JsonNode node)
    {
        return_if_fail(node.parent == null);
        nodes.append_val(node);
        node.parent = this;
    }

    /**
     * Adds the node on to the start of the array.
     *
     * @param node    the node to prepend
     */
    public void prepend(JsonNode node)
    {
        return_if_fail(node.parent == null);
        nodes.prepend_val(node);
        node.parent = this;
    }

    /**
     * Inserts a node into the array at the given index.
     *
     * @param index    the index to place the node at
     * @param node     the node to insert into the array
     */
    public void insert(uint index, JsonNode node)
    {
        return_if_fail(node.parent == null);
        return_if_fail(index <= nodes.length);
        if (index == nodes.length)
        nodes.append_val(node);
        else
        nodes.insert_val(index, node);
        node.parent = this;
    }

    /**
     * Remove a node at given position
     *
     * @param index    index to remove node at
     */
    public void remove_at(uint index)
    {
        var node = get(index);
        return_if_fail(node != null);
        nodes.remove_index(index);
        node.parent = null;
    }

    /**
     * Remove a node
     *
     * @param node   The node to remove
     * @return `true` if the node has been found and removed
     */
    public bool remove(JsonNode node)
    {
        uint pos;
        if (index(node, out pos))
        {
            remove_at(pos);
            return true;
        }
        return false;
    }

    /**
     * Return the index of a node
     *
     * @param node     The node to find
     * @param index    The index of the node if it has been found
     * @return `true` if the node if it has been found and so the `index` is valid
     */
    public bool index(JsonNode node, out uint index)
    {
        var len = length;
        for (var i = 0U; i < len; i++)
        {
            if (get(i) == node)
            {
                index = i;
                return true;
            }
        }
        index = 0;
        return false;
    }

    /**
     * Sort the array
     *
     * @param compare_func    A comparison function
     */
    public void sort(CompareFunc<JsonNode> compare_func)
    {
        nodes.sort(compare_func);
    }

    /**
     * Sort the array
     *
     * @param compare_func    A comparison function with user data
     */
    public void sort_with_data(CompareDataFunc<JsonNode> compare_func)
    {
        nodes.sort_with_data(compare_func);
    }

    /**
     * Get a node at index
     *
     * @param index    The index of a node to get
     * @return {@link JsonNode} at given `index` or `null`
     */
    public unowned JsonNode? get(uint index)
    {
        return index < nodes.length ? nodes.data[index] : null;
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
        return_val_if_fail(path[0] != '\0', null);
        var dot = path.index_of_char('.');
        return_val_if_fail(dot != 0, null);
        var index_str = dot < 0 ? path : path.substring(0, dot);
        var len = index_str.length;
        for (var i = 0; i < len; i++)
        {
            var c = index_str.data[i];
            if (c < '0' || c > '9')
            return null;
        }
        unowned JsonNode? node = get((uint) int.parse(index_str));
        if (node == null)
        return null;
        if (dot < 0)
        return node;
        unowned string subpath = (string)(((char*) path) + dot + 1);
        if (node is JsonObject)
        return ((JsonObject) node).dotget(subpath);
        else if (node is JsonArray)
        return ((JsonArray) node).dotget(subpath);
        else
        return null;
    }

    /**
     * Gets a boolean value at given index
     *
     * @param index    the index of the node to get
     * @param result   the obtained value
     * @return `true` if the node is found and is of type {@link JsonValueType.BOOLEAN} and so the `result` is valid
     */
    public bool get_bool(uint index, out bool result)
    {
        var node = get(index) as JsonValue;
        if (node == null)
        {
            result = false;
            return false;
        }
        return node.try_bool(out result);
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
     * Gets an integer number value at given index
     *
     * @param index    the index of the node to get
     * @param result   the obtained value
     * @return `true` if the node is found and  is of type {@link JsonValueType.INTEGER}
     *     and so the `result` is valid, `false` otherwise
     */
    public bool get_int(uint index, out int result)
    {
        var node = get(index) as JsonValue;
        if (node == null)
        {
            result = 0;
            return false;
        }
        return node.try_int(out result);
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
     * Gets a floating point number value at given index
     *
     * @param index    the index of the node to get
     * @param result   the obtained value
     * @return `true` if the node is found and  is of type {@link JsonValueType.DOUBLE}
     *     and so the `result` is valid, `false` otherwise
     */
    public bool get_double(uint index, out double result)
    {
        var node = get(index) as JsonValue;
        if (node == null)
        {
            result = 0.0;
            return false;
        }
        return node.try_double(out result);
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
     * Gets a string value at given index
     *
     * @param index    the index of the node to get
     * @param result   the obtained value
     * @return `true` if the node is found and  is of type {@link JsonValueType.STRING}
     *     and so the `result` is valid, `false` otherwise
     */
    public bool get_string(uint index, out string? result)
    {
        var node = get(index) as JsonValue;
        if (node == null)
        {
            result = null;
            return false;
        }
        return node.try_string(out result);
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
     * Gets a null value at given index
     *
     * @param index    the index of the node to get
     * @return `true` if the node is found and is of type {@link JsonValueType.NULL}, `false` otherwise
     */
    public bool get_null(uint index)
    {
        var node = get(index) as JsonValue;
        return node == null ? false : node.is_null();
    }

    /**
     * Gets a JSON array at given index
     *
     * @param index    the index of the node to get
     * @return a {@link JsonArray} if the node is found and is an array, `null` otherwise
     */
    public JsonArray? get_array(uint index)
    {
        return get(index) as JsonArray;
    }

    /**
     * Gets a JSON object at given index
     *
     * @param index    the index of the node to get
     * @return a {@link JsonObject} if the node is found and is an object, `null` otherwise
     */
    public JsonObject? get_object(uint index)
    {
        return get(index) as JsonObject;
    }

    /**
     * Returns content as a boolean array
     *
     * @param result    the resulting boolean array
     * @return `true` if all array members are of type {@link JsonValueType.BOOLEAN} and thus `result` is valid,
     *     `false` otherwise
     */
    public bool as_bool_array(out bool[] result)
    {
        result = null;
        var size = this.length;
        var array = new bool[size];
        for (uint i = 0; i < size; i++)
        {
            bool val;
            if (get_bool(i, out val))
            array[i] = val;
            else
            return false;
        }
        result = (owned) array;
        return true;
    }

    /**
     * Returns content as an integer array
     *
     * @param result    the resulting integer array
     * @return `true` if all array members are of type {@link JsonValueType.INTEGER} and thus `result` is valid,
     *     `false` otherwise
     */
    public bool as_int_array(out int[] result)
    {
        result = null;
        var size = this.length;
        var array = new int[size];
        for (uint i = 0; i < size; i++)
        {
            int val;
            if (get_int(i, out val))
            array[i] = val;
            else
            return false;
        }
        result = (owned) array;
        return true;
    }

    /**
     * Returns content as a double array
     *
     * @param result    the resulting double array
     * @return `true` if all array members are of type {@link JsonValueType.DOUBLE} and thus `result` is valid,
     *     `false` otherwise
     */
    public bool as_double_array(out double[] result)
    {
        result = null;
        var size = this.length;
        var array = new double[size];
        for (uint i = 0; i < size; i++)
        {
            double val;
            if (get_double(i, out val))
            array[i] = val;
            else
            return false;
        }
        result = (owned) array;
        return true;
    }

    /**
     * Returns content as a string array
     *
     * @param result    the resulting string array
     * @return `true` if all array members are of type {@link JsonValueType.STRING} and thus `result` is valid,
     *     `false` otherwise
     */
    public bool as_string_array(out string[] result)
    {
        result = null;
        var size = this.length;
        var array = new string[size];
        for (uint i = 0; i < size; i++)
        {
            string? val;
            if (get_string(i, out val))
            array[i] = val;
            else
            return false;
        }
        result = (owned) array;
        return true;
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
    public string dump(string? indent, bool compact, uint level = 0)
    {
        var buffer = new StringBuilder();
        dump_to_buffer(buffer, indent, compact, level);
        return buffer.str;
    }

    /**
     * Create a string representation of the node.
     *
     * @param buffer     A bufer to dump the string representation to.
     * @param indent     A string to indent lines. If empty or null, no new lines and no indentation is used.
     * @param compact    If `true`, no space after a comma or a colon is added.
     * @param level      An initial indentation level.
     */
    public void dump_to_buffer(StringBuilder buffer, string? indent, bool compact, uint level=0)
    {
        var nl = !String.is_empty(indent);
        var item_sep = (nl || compact) ? "," : ", ";
        buffer.append_c('[');
        if (nl)
        buffer.append_c('\n');
        var size = this.length;
        for (uint i = 0; i < size; i++)
        {
            if (nl)
            for (var j = 0; j <= level; j++)
            buffer.append(indent);

            unowned JsonNode node = nodes.data[i];
            if (node is JsonArray)
            ((JsonArray) node).dump_to_buffer(buffer, indent, compact, level + 1);
            else if (node is JsonObject)
            ((JsonObject) node).dump_to_buffer(buffer, indent, compact, level + 1);
            else
            buffer.append(node.to_string());
            if (i + 1 != size)
            buffer.append(item_sep);
            if (nl)
            buffer.append_c('\n');
        }
        if (nl)
        for (var j = 0; j < level; j++)
        buffer.append(indent);
        buffer.append_c(']');
        if (nl && level == 0)
        buffer.append_c('\n');
    }
}

} // namespace Drt
