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

public errordomain JsonError
{
    EMPTY_DATA,
    INVALID_DATA,
    EXTRA_DATA,
    PARSE_ERROR;
}

/**
 * Parser of JSON data format.
 */
public class JsonParser
{
    private char* data = null;
    private char* data_end = null;
    private uint line = 0;
    private uint column = 0;
    private uint array_recursion = 0;

    /**
     * Parse JSON object from data.
     *
     * @param data    the data to parse
     * @throws JsonError if data is empty or invalid
     * @return a new JSON document
     */
    public static JsonObject load_object(string? data) throws JsonError
    {
        var parser = new JsonParser(data);
        if (parser.root == null || !(parser.root is JsonObject))
        throw new JsonError.INVALID_DATA("The data doesn't represent a JavaScript object.");
        return (JsonObject) parser.root;
    }

    /**
     * Parse JSON array from data.
     *
     * @param data    the data to parse
     * @throws JsonError if data is empty or invalid
     * @return a new JSON array
     */
    public static JsonArray load_array(string? data) throws JsonError
    {
        var parser = new JsonParser(data);
        if (parser.root == null || !(parser.root is JsonArray))
        throw new JsonError.INVALID_DATA("The data doesn't represent a JavaScript array.");
        return (JsonArray) parser.root;
    }

    /**
     * Parse JSON document from data.
     *
     * @param data    the data to parse
     * @throws JsonError if data is empty or invalid
     * @return a new JSON array
     */
    public static JsonNode load(string? data) throws JsonError
    {
        var parser = new JsonParser(data);
        if (parser.root == null || !(parser.root is JsonArray || parser.root is JsonObject))
        throw new JsonError.INVALID_DATA("The data doesn't represent a JavaScript object or array.");
        return parser.root;
    }

    /**
     * The root node of the parsed JSON document
     */
    public JsonNode? root {get; private set; default = null;}

    /**
     * Create new parser and parse data
     *
     * @param data    data to parse
     * @throws JsonError if data is empty or invalid
     */
    public JsonParser(string? data) throws JsonError
    {
        if (data == null || data[0] == 0)
        throw new JsonError.EMPTY_DATA("Data is empty.");
        this.data = data;
        this.data_end = this.data + data.length;
        this.line = 1;
        this.column = 0;
        JsonNode? root = null;
        parse_one(out root);
        skip_whitespace();
        var c = get_char();
        if (c != 0)
        throw new JsonError.EXTRA_DATA(
            "%u:%u Extra data has been found after a parsed JSON document. The first character is '%c'.",
            line, column, c);
        if (root is JsonValue)
        throw new JsonError.INVALID_DATA("The outermost value must be an object or array.");
        this.root = root;
    }

    private char get_char()
    {
        var c = data < data_end ? *(data++) : 0;
        if (c == '\n')
        {
            line++;
            column = 0;
        }
        else if (c > 0)
        {
            column++;
        }
        return c;
    }

    private char peek_char(uint offset=0)
    {
        var pos = data + offset;
        return pos >= data && pos < data_end ? *pos : 0;
    }

    private void skip(uint offset)
    {
        while (offset-- > 0)
        get_char();
    }

    private void skip_whitespace()
    {
        char c;
        while ((c = peek_char()) != 0)
        {
            switch (c)
            {
            case ' ':
            case '\t':
            case '\n':
            case '\r':
                get_char();
                break;
            default:
                return;
            }
        }
    }

    private void parse_one(out JsonNode node) throws JsonError
    {
        node = null;
        skip_whitespace();
        var c = peek_char();
        switch (c)
        {
        case '{':
            get_char();
            parse_object(out node);
            return;
        case '[':
            get_char();
            parse_array(out node);
            return;
        case '"':
            get_char();
            string? str = null;
            parse_string(out str);
            node = new JsonValue.@string(str);
            return;
        case 't':
            parse_keyword("true", out node);
            return;
        case 'f':
            parse_keyword("false", out node);
            return;
        case 'n':
            parse_keyword("null", out node);
            return;
        case '-':
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            parse_number(out node);
            return;
        case '\0':
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected end of data. An object, an array, a string or a primitive value expected.",
                line, column);
        default:
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected character '%c'. An object, an array, a string or a primitive value expected.",
                line, column, c);
        }
    }

    private void parse_keyword(string keyword, out JsonValue node) throws JsonError
    {
        node = null;
        var len = keyword.data.length;
        unowned uint8[] buf = keyword.data;
        for (var i = 0; i < len; i++)
        {
            var c = get_char();
            if (c == '\0')
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected end of data. The '%c' character of '%s' expected.",
                line, column, buf[i], keyword);
            if (c != buf[i])
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected character '%c'. The '%c' character of '%s' expected.",
                line, column, c, buf[i], keyword);
        }
        switch (keyword)
        {
        case "true":
            node = new JsonValue.@bool(true);
            break;
        case "false":
            node = new JsonValue.@bool(false);
            break;
        case "null":
            node = new JsonValue.@null();
            break;
        default:
            throw new JsonError.PARSE_ERROR("Unknown keyword: '%s'", keyword);
        }
    }

    private void parse_number(out JsonValue node) throws JsonError
    {
        node = null;
        var sign_set = false;
        var integer = true;
        var decimal_point = false;
        var exponent = false;
        var buf = new StringBuilder();
        var valid_chars = true;
        var valid_number = false;
        bool leading_zero = false;
        int i;
        char c = 0;
        for (i = 0; valid_chars && (c = peek_char(i)) != 0; i++)
        {
            switch (c)
            {
            case '-':
            case '+':
                if (sign_set)
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Invalid number: A digit expected but '%c' found.", line, column + i, c);
                buf.append_c(c);
                sign_set = true;
                break;
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                if (!decimal_point)
                {
                    if (c == '0' && !valid_number)
                    leading_zero = true;
                    if (c != '0' && leading_zero)
                    throw new JsonError.PARSE_ERROR(
                        "%u:%u Invalid number: Numbers cannot have leading zeroes.", line, column + i);
                }
                buf.append_c(c);
                valid_number = true;
                sign_set = true;
                break;
            case '.':
                if (decimal_point)
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Invalid number: A decimal point can be set only once.", line, column + i);
                integer = false;
                decimal_point = true;
                buf.append_c(c);
                break;
            case 'e':
            case 'E':
                if (exponent)
                throw new JsonError.PARSE_ERROR("%u:%u Invalid number: Cannot set exponent again.", line, column + i);
                exponent = true;
                valid_number = false;
                leading_zero = false;
                integer = false;
                sign_set = false;
                decimal_point = false;
                buf.append_c(c);
                break;
            default:
                assert(buf.len != 0);
                valid_chars = false;
                i--;
                break;
            }
        }
        skip(i);
        if (!valid_number)
        {
            if (c == 0)
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected end of data. A number character expected.", line, column);
            else
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected character '%c'. A number character expected", line, column, c);
        }
        if (integer)
        node = new JsonValue.@int(int.parse(buf.str));
        else
        node = new JsonValue.@double(double.parse(buf.str));
    }

    private void parse_object(out JsonObject object) throws JsonError
    {
        object = new JsonObject();
        /* Look for the end of the object */
        skip_whitespace();
        var c = peek_char();
        switch (c)
        {
        case '\0':
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected end of data. A string or '}' expected.", line, column);
        case '}':
            get_char();
            return;
        }
        while (true)
        {
            /* Look for a key */
            string? key = null;
            skip_whitespace();
            c = get_char();
            switch (c)
            {
            case '\0':
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected end of data. A string expected.", line, column);
            case '"':
                parse_string(out key);
                break;
            default:
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected character '%c'. A string expected.", line, column, c);
            }

            /* Skip to ':' */
            skip_whitespace();
            c = get_char();
            switch (c)
            {
            case '\0':
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected end of data. A ':' character expected.", line, column);
            case ':':
                break;
            default:
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected character '%c'. A ':' character expected.", line, column, c);
            }

            /* Parse the value */
            JsonNode node = null;
            parse_one(out node);
            object[key] = node;

            /* Look for a comma or the end of the object */
            skip_whitespace();
            c = get_char();
            switch (c)
            {
            case '\0':
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected end of data. Characters ',' or '}' expected.", line, column);
            case ',':
                break;
            case '}':
                return;
            default:
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected character '%c'. Characters ',' or '}' expected.", line, column, c);
            }
        }
    }

    private void parse_array(out JsonArray array) throws JsonError
    {
        if (++array_recursion >= 20)
        throw new JsonError.PARSE_ERROR(
            "%u:%u Maximal array recursion depth reached.", line, column);

        array = new JsonArray();
        /* Look for the end of the array */
        skip_whitespace();
        switch (peek_char())
        {
        case '\0':
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected end of data. An array element or ']' expected.", line, column);
        case ']':
            get_char();
            array_recursion--;
            return;
        }
        while (true)
        {
            /* Look for an item */
            skip_whitespace();
            switch (peek_char())
            {
            case '\0':
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected end of data. An array element expected.", line, column);
            default:
                /* Parse the value */
                JsonNode node;
                parse_one(out node);
                array.append(node);
                break;
            }

            /* Look for a comma or the end of the array */
            skip_whitespace();
            var c = get_char();
            switch (c)
            {
            case '\0':
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected end of data. Characters ',' or ']' expected.", line, column);
            case ',':
                break;
            case ']':
                array_recursion--;
                return;
            default:
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Unexpected character '%c'. Characters ',' or ']' expected.", line, column, c);
            }
        }
    }

    private void parse_string(out string? value) throws JsonError
    {
        value = null;
        var buf = new StringBuilder();
        char c;
        while ((c = get_char()) != 0)
        {
            if (c < 32u) // the control characters U+0000 to U+001F
            throw new JsonError.PARSE_ERROR(
                "%u:%u Invalid control character (%02X) in a string.", line, column, c);
            switch (c)
            {
            case '\\':
                parse_escape_sequence(buf);
                break;
            case '"':
                value = buf.str;
                return;
            default:
                buf.append_c(c);
                break;
            }
        }
        throw new JsonError.PARSE_ERROR("%u:%u Unexpected end of data. Incomplete string.", line, column);
    }

    private void parse_escape_sequence(StringBuilder buf) throws JsonError
    {
        var c = get_char();
        switch (c)
        {
        case '\0':
            throw new JsonError.PARSE_ERROR(
                "%u:%u Unexpected end of data. Incomplete escape sequence.", line, column);
        case '"':
        case '/':
        case '\\':
            buf.append_c(c);
            break;
        case 'b':
            buf.append_c('\b');
            break;
        case 'f':
            buf.append_c('\f');
            break;
        case 'n':
            buf.append_c('\n');
            break;
        case 'r':
            buf.append_c('\r');
            break;
        case 't':
            buf.append_c('\t');
            break;
        case 'u':
            unichar utf16 = parse_unichar();
            if (utf16 == 0)
            throw new JsonError.PARSE_ERROR(
                "%u:%u Invalid unicode escape sequence.", line, column);

            if (utf16.type() == UnicodeType.SURROGATE)
            {
                if (get_char() != '\\' || get_char() != 'u')
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Incomplete unicode escape sequence pair.", line, column);
                unichar utf16_pair[2];
                utf16_pair[0] = utf16;
                utf16_pair[1] = parse_unichar();
                if (utf16_pair[1] == 0)
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Invalid unicode escape sequence.", line, column);

                if (0xd800 > utf16_pair[0] || utf16_pair[0] > 0xdbff
                || 0xdc00 > utf16_pair[1] || utf16_pair[1] > 0xdfff)
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Invalid unicode escape sequence.", line, column);

                utf16 = 0x10000;
                utf16 += (utf16_pair[0] & 0x3ff) << 10;
                utf16 += (utf16_pair[1] & 0x3ff);
                if (!utf16.validate())
                throw new JsonError.PARSE_ERROR(
                    "%u:%u Invalid unicode escape sequence.", line, column);
            }
            buf.append_unichar(utf16);
            break;
        default:
            throw new JsonError.PARSE_ERROR(
                "%u:%u Invalid escape sequence.", line, column);
        }
    }

    private unichar parse_unichar()
    {
        unichar u = 0;
        for (var i = 0; i < 4; i++)
        {
            var c = get_char();
            if ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))
            u += ((unichar) (c <= '9' ? c - '0' : (c & 7) + 9) << ((3 - i) * 4));
            else
            return 0;
        }
        return u.validate() || u.type() == UnicodeType.SURROGATE ? u : 0;
    }
}

} // namespace Drt
