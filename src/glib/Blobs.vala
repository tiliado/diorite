/*
 * Copyright 2015-2019 Jiří Janoušek <janousek.jiri@gmail.com>
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

/**
 * The {@link Drt.Blobs} namespace contains utility fuctions to work with binary blobs in various formats:
 * a raw array of bytes (`uint8[]`), {@link GLib.Bytes}, and {@link GLib.ByteArray}.
 */
namespace Drt.Blobs {

/**
 * Check whether two binary blobs are equal byte by byte.
 *
 * @param value1    The first blob to compare. It may be null.
 * @param value2    The second blob to compare. It may be null.
 * @return `true` if the blobs are both null or equal byte by byte, `false` otherwise.
 */
public bool blob_equal(uint8[]? value1, uint8[]? value2) {
    if (value1 == null && value2 == null) {
        return true;
    }
    if (!(value1 != null && value2 != null) || value1.length != value2.length) {
        return false;
    }
    for (var i = 0; i < value1.length; i++) {
        if (value1[i] != value2[i]) {
            return false;
        }
    }
    return true;
}


/**
 * Check whether two {@link GLib.Bytes} instances are equal byte by byte.
 *
 * @param value1    The first blob to compare. It may be null.
 * @param value2    The second blob to compare. It may be null.
 * @return `true` if the blobs are both null or equal byte by byte, `false` otherwise.
 */
public bool bytes_equal(GLib.Bytes? value1, GLib.Bytes? value2) {
    return blob_equal(value1 != null ? value1.get_data() : null, value2 != null ? value2.get_data() : null);
}


/**
 * Check whether two {@link GLib.ByteArray} instances are equal byte by byte.
 *
 * @param value1    The first blob to compare. It may be null.
 * @param value2    The second blob to compare. It may be null.
 * @return `true` if the blobs are both null or equal byte by byte, `false` otherwise.
 */
public bool byte_array_equal(GLib.ByteArray? value1, GLib.ByteArray? value2) {
    return blob_equal(value1 != null ? value1.data : null, value2 != null ? value2.data : null);
}


/**
 * Convert a binary blob to printable string.
 *
 * @param value    The binary blob to convert. It may be null.
 * @return Printable representation of the value if it is not null nor empty, `null` otherwise.
 */
public string? blob_to_string(uint8[]? value) {
    if (value == null) {
        return null;
    }
    string hex;
    hexadecimal_from_blob(value, out hex, '\0');
    return (owned) hex;
}


/**
 * Convert a {@link GLib.Bytes} instance to printable string.
 *
 * @param value    The binary blob to convert. It may be null.
 * @return Printable representation of the value if it is not null nor empty, `null` otherwise.
 */
public string? bytes_to_string(GLib.Bytes? value) {
    return blob_to_string(value != null ? value.get_data() : null);
}


/**
 * Convert a {@link GLib.ByteArray} instance to printable string.
 *
 * @param value    The binary blob to convert. It may be null.
 * @return Printable representation of the value if it is not null nor empty, `null` otherwise.
 */
public string? byte_array_to_string(GLib.ByteArray? value) {
    return blob_to_string(value != null ? value.data : null);
}


/**
 * Convert an int64 value to an array of bytes.
 *
 * @param val       The value to convert.
 * @param result    The resulting binary representation (an array of 8 bytes).
 */
public void int64_to_blob(int64 val, out uint8[] result) {
    var size = (int) sizeof(int64);
    result = new uint8[size];
    for (int i = size - 1; i >= 0; i--) {
        result[i] = (uint8) (val & 0xFF);
        val >>= 8;
    }
}


/**
 * Convert an array of bytes to an int64 value.
 *
 * @param array     The array of bytes to convert.
 * @param result    The resulting int64 value.
 * @return          `true` on success, `false` when the array is too large to fit in int64 type.
 */
public bool int64_from_blob(uint8[] array, out int64 result) {
    result = 0;
    if (array.length > sizeof(int64)) {
        return false;
    }
    for (int i = 0; i < array.length; i++) {
        result <<= 8;
        result |= (int64) (array[i] & 0xFF);
    }
    return true;
}


/**
 * Convert an array of bytes to a hexadecimal string.
 *
 * @param array        The array of bytes to convert.
 * @param result       The resulting hexadecimal representation. The resultin size is 2 * `array.length`
 *                     if no separator is used, 2 * `array.length` otherwise.
 * @param separator    The separator of hexadecimal pairs ('\0' for none).
 */
public void hexadecimal_from_blob(uint8[] array, out string result, char separator='\0') {
    int size = separator == '\0' ? 2 * array.length : 3 * array.length - 1;
    var buffer = new StringBuilder.sized(size);
    hexadecimal_append_from_blob(array, buffer, separator);
    result = (owned) buffer.str;
}


/**
 * Convert an array of bytes to a hexadecimal string and store it in the provided buffer.
 *
 * @param array        The array of bytes to convert.
 * @param buffer       The {@link GLib.StringBuilder} buffer to store the converted value in. The resultin size is
 *                     2 * `array.length` if no separator is used, 2 * `array.length` otherwise.
 * @param separator    The separator of hexadecimal pairs ('\0' for none).
 */
public void hexadecimal_append_from_blob(uint8[] array, StringBuilder buffer, char separator='\0') {
    unowned string hex_chars = "0123456789abcdef";
    for (var i = 0; i < array.length; i++) {
        if (i > 0 && separator != '\0') {
            buffer.append_c(separator);
        }
        buffer.append_c(hex_chars[(array[i] >> 4) & 0x0F]).append_c(hex_chars[array[i] & 0x0F]);
    }
}


/**
 * Convert a hexadecimal string to an array of bytes.
 *
 * @param hex          The hexadecimal string to convert.
 * @param result       The resulting array of bytes.
 * @param separator    The separator of hexadecimal pairs ('\0' for none).
 * @return             `true` on success, `false` on failure (invalid input).
 */
public bool hexadecimal_to_blob(string hex, out uint8[] result, char separator='\0') {
    result = null;
    unowned uint8[] hex_data = (uint8[]) hex;
    hex_data.length = hex.length;
    return_val_if_fail(hex != null && hex_data.length > 0, false);

    int size = hex_data.length;
    if (separator != '\0') {
        // "aa:bb:cc" -> 8 chars, 3 bytes
        size++;
        if (size % 3 != 0) {
            return false;
        }
        size /= 3;
    } else {
        // "aabbcc" -> 6 chars, 3 bytes
        if (size % 2 != 0) {
            return false;
        }
        size /= 2;
    }

    result = new uint8[size];
    uint8 c;
    uint8 j;
    for (int i = 0, pos = 0; (c = hex_data[pos++]) != 0 && i < 2 * size; i++) {
        if (c == separator) {
            i--;
            continue;
        }
        switch (c) {
        case '0': j = 0; break;
        case '1': j = 1; break;
        case '2': j = 2; break;
        case '3': j = 3; break;
        case '4': j = 4; break;
        case '5': j = 5; break;
        case '6': j = 6; break;
        case '7': j = 7; break;
        case '8': j = 8; break;
        case '9': j = 9; break;
        case 'A': j = 10; break;
        case 'B': j = 11; break;
        case 'C': j = 12; break;
        case 'D': j = 13; break;
        case 'E': j = 14; break;
        case 'F': j = 15; break;
        case 'a': j = 10; break;
        case 'b': j = 11; break;
        case 'c': j = 12; break;
        case 'd': j = 13; break;
        case 'e': j = 14; break;
        case 'f': j = 15; break;
        default: return false;
        }
        result[i/2] += i % 2 == 0 ? (j << 4) : j;
    }
    return true;
}


/**
 * Convert a hexadecimal string to an int64 value.
 *
 * @param hex          The hexadecimal string to convert.
 * @param result       The resulting int64 value.
 * @param separator    The separator of hexadecimal pairs ('\0' for none).
 * @return             `true` on success, `false` on failure (invalid input, overflow).
 */
public bool int64_from_hexadecimal(string hex, out int64 result, char separator='\0') {
    uint8[] data;
    result = 0;
    return hexadecimal_to_blob(hex, out data, separator) && int64_from_blob(data, out result);
}


/**
 * Convert an int64 value to a hexadecimal string.
 *
 * @param val          The int64 value to convert.
 * @param result       The resulting hexadecimal string.
 * @param separator    The separator of hexadecimal pairs ('\0' for none).
 */
public void int64_to_hexadecimal(int64 val, out string result, char separator='\0') {
    uint8[] data;
    int64_to_blob(val, out data);
    hexadecimal_from_blob(data, out result, separator);
}


/**
 * Convert an uint32 value to an array of bytes.
 *
 * @param buffer    The array of bytes at least `sizeof(uint32)` where the result will be stored.
 * @param data      The uint32 value to convert.
 */
public void uint32_to_blob(uint32 data, uint8[] buffer) {
    size_t size = sizeof(uint32);
    assert(buffer.length >= size);
    for (var i = 0; i < size; i ++) {
        buffer[i] = (uint8)((data >> ((size - 1 - i) * 8)) & 0xFF);
    }
}


/**
 * Convert an int32 value to an array of bytes.
 *
 * @param buffer    The array of bytes size at least `sizeof(int32)` where the result will be stored.
 * @param data      The int32 value to convert.
 */
public void int32_to_blob(int32 data, uint8[] buffer) {
    size_t size = sizeof(int32);
    assert(buffer.length >= size);
    for (var i = 0; i < size; i ++) {
        buffer[i] = (uint8)((data >> ((size - 1 - i) * 8)) & 0xFF);
    }
}


/**
 * Convert an array of bytes to an uint32 value.
 *
 * @param buffer    The array of bytes that contains the uint32 value.
 * @param data      The resulting uint32 value.
 */
public void uint32_from_blob(uint8[] buffer, out uint32 data) {
    size_t size = sizeof(uint32);
    assert(buffer.length >= size);
    data = 0;
    for (var i = 0; i < size; i ++) {
        data += buffer[i] * (1 << ((uint32)size - 1 - i) * 8);
    }
}


/**
 * Converts an array of bytes to an int32 value.
 *
 * @param buffer    The array of bytes that contains the int32 value.
 * @param data      The resulting int32 value.
 */
public void int32_from_blob(uint8[] buffer, out int32 data) {
    size_t size = sizeof(int32);
    assert(buffer.length >= size);
    data = 0;
    for (var i = 0; i < size; i ++) {
        data += buffer[i] * (1 << ((int32)size - 1 - i) * 8);
    }
}

} // namespace Drt.Blobs
