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

namespace Drt.Utils {

public bool const_time_byte_equal(uint8[] a, uint8[] b) {
    if (a.length != b.length) {
        return false;
    }
    uint8 diff = 0;
    for (var i = 0; i < a.length; i++) {
        diff |= a[i] ^ b[i];
    }
    return diff == 0;
}

public Array<int?> wrap_intv(int[] array) {
    var result = new Array<int?>();
    foreach (var value in array) {
        result.append_val(value);
    }
    return result;
}

public Array<double?> wrap_doublev(double[] array) {
    var result = new Array<double?>();
    foreach (var value in array) {
        result.append_val(value);
    }
    return result;
}

public Array<bool?> wrap_boolv(bool[] array) {
    var result = new Array<bool?>();
    foreach (var value in array) {
        result.append_val(value);
    }
    return result;
}

public Array<string?> wrap_strv(string?[] array) {
    var result = new Array<string?>();
    foreach (var value in array) {
        result.append_val(value);
    }
    return result;
}

/**
 * Create string array from a single-linked list
 *
 * @param list    List of strings
 * @return    array of strings
 */
public string[] slist_to_strv(SList<string> list) {
    var array = new string[list.length()];
    var i = 0;
    foreach (unowned string item in list) {
        array[i++] = item;
    }
    return array;
}

/**
 * Create string array from a double-linked list
 *
 * @param list    List of strings
 * @return    array of strings
 */
public string[] list_to_strv(List<string> list) {
    var array = new string[list.length()];
    var i = 0;
    foreach (unowned string item in list) {
        array[i++] = item;
    }
    return array;
}

/**
 * Export date and time as an ISO 8601 string.
 *
 * @param datetime    Date time object to export
 * @return Date and time as an ISO 8601 string,
 */
public static string datetime_to_iso_8601(DateTime datetime) {
    string format = "%FT%T";
    if (datetime.get_microsecond() > 0) {
        format += ".%06d".printf(datetime.get_microsecond());
    }
    format += datetime.get_utc_offset() == 0 ? "Z" : "%z";
    return datetime.format(format);
}

public static string human_datetime(DateTime? datetime) {
    return (datetime == null ? new DateTime.now_local() : datetime.to_local()).format("%x %X");
}

} // namespace Drt.Utils
