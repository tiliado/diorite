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
 * Types of values the {@link JsonValue} object can hold.
 */
public enum JsonValueType
{
    /**
     * The value is `null`
     */
    NULL,
    /**
     * The value is of type boolean
     */
    BOOLEAN,
    /**
     * The value is a string
     */
    STRING,
    /**
     * The value is a number in integer format
     */
    INTEGER,
    /**
     * The value is a number in floating point format
     */
    DOUBLE;
}

/**
 * JSON Value holds boolean, integer, float, string and null values.
 */
public class JsonValue: JsonNode
{
    public static string escape_string(string? str)
    {
        if (str == null)
        return "";
        return_val_if_fail(str.validate(), "");
        var result = (str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
            .replace("\t", "\\t").replace("\r", "\\r").replace("\b", "\\b").replace("\f", "\\f"));
        uint8 c = 0;
        var len = result.length;
        for (var i = 0; i < len && (c = result.data[i]) != 0; i++)
        if (c < 32)  // the control characters U+0000 to U+001F
        result.data[i] = 32;
        return result;
    }

    [Description(nick = "Value type", blurb = "The value type this instance holds.")]
    public JsonValueType value_type {get; protected set; default = JsonValueType.NULL;}
    private int int_value = 0;
    private double double_value = 0.0;
    private string? string_value = null;

    /**
     * Creates a new null {@link JsonValue}.
     */
    public JsonValue.@null()
    {
        value_type = JsonValueType.NULL;
    }

    /**
     * Creates a new boolean {@link JsonValue}.
     *
     * @param bool_value    Boolean value.
     */
    public JsonValue.@bool(bool bool_value)
    {
        value_type = JsonValueType.BOOLEAN;
        this.int_value = bool_value ? 1 : 0;
    }

    /**
     * Creates a new integer number {@link JsonValue}.
     *
     * @param int_value    Integer value.
     */
    public JsonValue.@int(int int_value)
    {
        value_type = JsonValueType.INTEGER;
        this.int_value = int_value;
    }

    /**
     * Creates a new floating point number {@link JsonValue}.
     *
     * @param double_value    Double value.
     */
    public JsonValue.@double(double double_value)
    {
        value_type = JsonValueType.DOUBLE;
        this.double_value = double_value;
    }

    /**
     * Creates a new string {@link JsonValue}.
     *
     * @param string_value    String value.
     */
    public JsonValue.@string(string? string_value)
    {
        value_type = JsonValueType.STRING;
        this.string_value = string_value;
    }

    /**
     * Get a string value
     *
     * It is a programmer error to call this method if the {@link value_type} of this is not
     * {@link JsonValueType.STRING}. You might want to use {@link JsonNode.is_string} or
     * {@link JsonValue.try_string}.
     *
     * @return the actual string value if this is of type {@link JsonValueType.STRING},
     *     undefined result otherwise
     */
    public unowned string? get_string()
    {
        return_val_if_fail(value_type == JsonValueType.STRING, null);
        return string_value;
    }

    /**
     * Duplicate a string value
     *
     * It is a programmer error to call this method if the {@link value_type} of this is not
     * {@link JsonValueType.STRING}. You might want to use {@link JsonNode.is_string} or
     * {@link JsonValue.try_string}.
     *
     * @return the copy of the actual string value if this is of type {@link JsonValueType.STRING},
     *     undefined result otherwise
     */
    public string? dup_string()
    {
        return_val_if_fail(value_type == JsonValueType.STRING, null);
        return string_value;
    }

    /**
     * Try getting a string value
     *
     * @param result    String value.
     * @return `true` if this holds {@link JsonValueType.STRING} and so `result` is valid,
     *     `false` otherwise
     */
    public bool try_string(out string? result)
    {
        result = string_value;
        return value_type == JsonValueType.STRING;
    }

    /**
     * Get a boolean value
     *
     * It is a programmer error to call this method if the {@link value_type} of this is not
     * {@link JsonValueType.BOOLEAN}. You might want to use {@link JsonNode.is_bool} or
     * {@link JsonValue.try_bool}.
     *
     * @return the actual boolean value if this is of type {@link JsonValueType.BOOLEAN},
     *     undefined result otherwise
     */
    public bool get_bool()
    {
        return_val_if_fail(value_type == JsonValueType.BOOLEAN, false);
        return int_value != 0 ? true : false;
    }

    /**
     * Try getting a boolean value
     *
     * @param result    Boolean value.
     * @return `true` if this holds {@link JsonValueType.BOOLEAN} and so `result` is valid,
     *     `false` otherwise
     */
    public bool try_bool(out bool result)
    {
        result = int_value != 0 ? true : false;
        return value_type == JsonValueType.BOOLEAN;
    }

    /**
     * Get an integer value
     *
     * It is a programmer error to call this method if the {@link value_type} of this is not
     * {@link JsonValueType.INTEGER}. You might want to use {@link JsonNode.is_int} or
     * {@link JsonValue.try_int}.
     *
     * @return the actual integer value if this is of type {@link JsonValueType.INTEGER},
     *     undefined result otherwise
     */
    public int get_int()
    {
        return_val_if_fail(value_type == JsonValueType.INTEGER, 0);
        return int_value;
    }

    /**
     * Try getting an integer number value
     *
     * @param result    Integer value.
     * @return `true` if this holds {@link JsonValueType.INTEGER} and so `result` is valid,
     *     `false` otherwise
     */
    public bool try_int(out int result)
    {
        result = int_value;
        return value_type == JsonValueType.INTEGER;
    }

    /**
     * Get a floating point number value
     *
     * It is a programmer error to call this method if the {@link value_type} of this is not
     * {@link JsonValueType.DOUBLE}. You might want to use {@link JsonNode.is_double} or
     * {@link JsonValue.try_double}.
     *
     * @return the actual double value if this is of type {@link JsonValueType.DOUBLE},
     *     undefined result otherwise
     */
    public double get_double()
    {
        return_val_if_fail(value_type == JsonValueType.DOUBLE, 0.0);
        return double_value;
    }

    /**
     * Try getting a floating point number value
     *
     * @param result    Double value.
     * @return `true` if this holds {@link JsonValueType.DOUBLE} and so `result` is valid,
     *     `false` otherwise
     */
    public bool try_double(out double result)
    {
        result = double_value;
        return value_type == JsonValueType.DOUBLE;
    }

    /**
     * Return string representation of the node.
     *
     * @return a string representation of the node
     */
    public override string to_string()
    {
        switch (value_type)
        {
        case JsonValueType.NULL:
            return "null";
        case JsonValueType.BOOLEAN:
            return int_value != 0 ? "true" : "false";
        case JsonValueType.INTEGER:
            return int_value.to_string();
        case JsonValueType.DOUBLE:
            return double_value.to_string();
        case JsonValueType.STRING:
            return "\"%s\"".printf(escape_string(string_value));
        default:
            assert_not_reached();
        }
    }
}

} // namespace Drt
