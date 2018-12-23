/*
 * Copyright 2014-2018 Jiří Janoušek <janousek.jiri@gmail.com>
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
 * The Drt.VariantUtils namespace contains various utility functions for {@link GLib.Variant} such as:
 *
 *  * Null-aware {@link Drt.VariantUtils.equal}, {@link Drt.VariantUtils.to_string} and {@link Drt.VariantUtils.print}
 *    functions.
 *  * Functions to extract a value with type checking: {@link Drt.VariantUtils.get_string},
 *    {@link Drt.VariantUtils.get_bool}, {@link Drt.VariantUtils.get_double}, {@link Drt.VariantUtils.get_int64},
 *    {@link Drt.VariantUtils.get_int}, {@link Drt.VariantUtils.get_uint}, {@link Drt.VariantUtils.get_number}.
 *  * Functions to extract a value from a variant dictionary with type checking:
 *    {@link Drt.VariantUtils.get_string_item}, {@link Drt.VariantUtils.get_double_item}.
 *  * Conversion of arrays and hash tables: {@link Drt.VariantUtils.to_strv}, {@link Drt.VariantUtils.to_array},
 *    {@link Drt.VariantUtils.to_hash_table}, {@link Drt.VariantUtils.from_hash_table}.
 *  * Unboxing of variant-variant and maybe-variant: {@link Drt.VariantUtils.unbox}.
 *  * Converting simple typed strings to variants: {@link Drt.VariantUtils.parse_typed_value}.
 *
 */
namespace Drt.VariantUtils {

/**
 * Compare two Variant values for equality.
 *
 * They can be null as well.
 *
 * @param a    The first value to compare.
 * @param b    The second value to compare.
 * @return `true` if the Variant values equal or both are null.
 */
public bool equal(Variant? a, Variant? b) {
    if (a == null && b == null) {
        return true;
    }
    if (a == null || b == null) {
        return false;
    }
    return a.equal(b);
}


/**
 * Convert Variant value to a string vector.
 *
 * If the Variant value is not a container, the behavior is undefined.
 *
 * All child values are unboxed and converted to a string representation regardless of the actual type.
 * An empty string is used from empty variants. Resulting string vector doesn't contain any null values.
 *
 * @param variant    A Variant container value.
 * @return The array of string representations of child nodes.
 */
public string[] to_strv(Variant variant) {
    return_val_if_fail(variant.is_container(), null);
    string[] result;
    size_t size = variant.n_children();
    if (size > 0) {
        result = new string[size];
        for (size_t i = 0; i < size; i++) {
            Variant child = variant.get_child_value(i);
            string? str;
            if (!get_string(child, out str)) {
                str = to_string(unbox(child));
            }
            result[i] = (owned) str;
        }
    } else {
        result = {};
    }
    return (owned) result;
}


/**
 * Convert Variant value to an array of child Variant values.
 *
 * If the Variant value is not a container, the behavior is undefined.
 *
 * All child values are unboxed. If the variant value is empty, null is added to the array.
 *
 * @param variant    A Variant container value.
 * @return The array of child variant values.
 */
public Variant?[] to_array(Variant variant) {
    return_val_if_fail(variant.is_container(), null);
    Variant[] result;
    size_t size = variant.n_children();
    if (size > 0) {
        result = new Variant[size];
        for (size_t i = 0; i < size; i++) {
            result[i] = unbox(variant.get_child_value(i));
        }
    } else {
        result = {};
    }
    return result;
}


/**
 * Convert Variant value to a hash table of child Variant values.
 *
 * If the Variant value is not a dictionary, the behavior is undefined.
 * All child values are unboxed. A null value is used for empty variants.
 *
 * @param variant    A Variant dictionary value of type "a{s*}".
 * @return A hash table of child variant values.
 */
public HashTable<string, Variant?> to_hash_table(Variant variant) {
    return_val_if_fail(variant.is_of_type(new VariantType("a{s*}")), null);
    var result = new HashTable<string, Variant?>(str_hash, str_equal);
    VariantIter iter = variant.iterator();
    unowned string? key = null; // "&s" (unowned)
    Variant? val = null; // "*" (new reference)
    while (iter.next("{&s*}", out key, out val)) {
        if (key != null) {
            result.insert(key, unbox(val));
        } else {
            critical("A null key present in a Variant dictionary.");
        }
        val = null; // https://gitlab.gnome.org/GNOME/vala/issues/722
    }
    return result;
}


/**
 * Construct a Variant dictionary from a hash table.
 *
 * The keys in the variant dictionary are sorted.
 *
 * @param hash_table    The hash table to construct the dictionary from.
 * @return Variant dictionary.
 */
public Variant from_hash_table(HashTable<string, Variant?> hash_table) {
    var builder = new VariantBuilder(new VariantType("a{smv}"));
    List<unowned string?> keys = hash_table.get_keys();
    keys.sort(strcmp);
    foreach (unowned string? key in keys) {
        if (key != null) {
            builder.add("{smv}", key, hash_table[key]);
        } else {
            critical("A null key present in a hash table.");
        }
    }
    return builder.end();
}


/**
 * Extract a non-null string from variant with unboxing and data type checking.
 *
 * @param variant    The variant value to extract a string from.
 * @param data       The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_string(Variant? variant, out string data) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null && unboxed.is_of_type(VariantType.STRING)) {
        data = unboxed.get_string();
        return true;
    }
    data = null;
    return false;
}


/**
 * Extract a string or a null value from variant with unboxing and data type checking.
 *
 * @param variant    The variant value to extract a string from.
 * @param data       The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_maybe_string(Variant? variant, out string? data) {
    Variant? unboxed = unbox(variant);
    if (unboxed == null) {
        data = null;
        return true;
    }
    if (unboxed.is_of_type(VariantType.STRING)) {
        data = unboxed.get_string();
        return true;
    }
    data = null;
    return false;
}


/**
 * Extract a boolean value from variant with unboxing and data type checking.
 *
 * @param variant    The variant value to extract a boolean value from.
 * @param result     The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_bool(Variant? variant, out bool result) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null && unboxed.is_of_type(VariantType.BOOLEAN)) {
        result = unboxed.get_boolean();
        return true;
    }
    result = false;
    return false;
}


/**
 * Extract a double value from variant with unboxing and data type checking.
 *
 * @param variant    The variant value to extract a double value from.
 * @param result     The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_double(Variant? variant, out double result) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null && unboxed.is_of_type(VariantType.DOUBLE)) {
        result = unboxed.get_double();
        return true;
    }
    result = 0.0;
    return false;
}


/**
 * Extract an int64 value from variant with unboxing and data type checking.
 *
 * @param variant    The variant value to extract an int64 value from.
 * @param result     The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_int64(Variant? variant, out int64 result) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null && unboxed.is_of_type(VariantType.INT64)) {
        result = unboxed.get_int64();
        return true;
    }
    result = 0;
    return false;
}


/**
 * Extract an int value from variant with unboxing and data type checking.
 *
 * Both VariantType.INT32 and VariantType.INT64 are accepted.
 *
 * @param variant    The variant value to extract an int value from.
 * @param result     The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_int(Variant? variant, out int result) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null) {
        if (unboxed.is_of_type(VariantType.INT64)) {
            result = (int) unboxed.get_int64();
            return true;
        }
        if (unboxed.is_of_type(VariantType.INT32)) {
            result = (int) unboxed.get_int32();
            return true;
        }
    }
    result = 0;
    return false;
}


/**
 * Extract an uint value from variant with unboxing and data type checking.
 *
 * Both VariantType.UINT32 and VariantType.UINT64 are accepted.
 *
 * @param variant    The variant value to extract an uint value from.
 * @param result     The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_uint(Variant? variant, out uint result) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null) {
        if (unboxed.is_of_type(VariantType.UINT64)) {
            result = (uint) unboxed.get_uint64();
            return true;
        }
        if (unboxed.is_of_type(VariantType.UINT32)) {
            result = (uint) unboxed.get_uint32();
            return true;
        }
    }
    result = 0;
    return false;
}


/**
 * Extract a number value from variant with unboxing and data type checking.
 *
 * VariantType.DOUBLE, VariantType.INT32 and VariantType.INT64 are accepted.
 * Integer types are casted to double.
 *
 * @param variant    The variant value to extract a double/int value from.
 * @param result     The return location for the result.
 * @return true on success, false on failure.
 */
public bool get_number(Variant? variant, out double result) {
    Variant? unboxed = unbox(variant);
    if (unboxed != null) {
        if (unboxed.is_of_type(VariantType.DOUBLE)) {
            result = unboxed.get_double();
            return true;
        }
        if (unboxed.is_of_type(VariantType.INT64)) {
            result = (double) unboxed.get_int64();
            return true;
        }
        if (unboxed.is_of_type(VariantType.INT32)) {
            result = (double) unboxed.get_int32();
            return true;
        }
    }
    result = 0;
    return false;
}


/**
 * Extract a string item from a variant dictionary.
 *
 * @param dict      The variant dictionary.
 * @param key       The key of the dictionary.
 * @param result    The return location for the extracted string.
 * @return true on success, false if dict is not a dictionary, the key doesn't exist or doesn't contain a string value.
 */
public bool get_string_item(Variant dict, string key, out string result) {
    return_val_if_fail(dict.is_of_type(new VariantType("a{s*}")), false);
    return get_string(dict.lookup_value(key, null), out result);
}

/**
 * Extract a string or null item from a variant dictionary.
 *
 * @param dict      The variant dictionary.
 * @param key       The key of the dictionary.
 * @param result    The return location for the extracted string.
 * @return true on success, false if dict is not a dictionary, the key does exist but doesn't contain a string value.
 */
public bool get_maybe_string_item(Variant dict, string key, out string? result) {
    return_val_if_fail(dict.is_of_type(new VariantType("a{s*}")), false);
    return get_maybe_string(dict.lookup_value(key, null), out result);
}


/**
 * Extract a boolean value item from a variant dictionary.
 *
 * @param dict      The variant dictionary.
 * @param key       The key of the dictionary.
 * @param result    The return location for the extracted boolean value.
 * @return true on success, false if dict is not a dictionary, the key doesn't exist or doesn't contain a boolean value.
 */
public bool get_bool_item(Variant dict, string key, out bool result) {
    return_val_if_fail(dict.is_of_type(new VariantType("a{s*}")), false);
    return get_bool(dict.lookup_value(key, null), out result);
}


/**
 * Extract a double value item from a variant dictionary.
 *
 * @param dict      The variant dictionary.
 * @param key       The key of the dictionary.
 * @param result    The return location for the extracted double value.
 * @return true on success, false if dict is not a dictionary, the key doesn't exist or doesn't contain a double value.
 */
public bool get_double_item(Variant dict, string key, out double result) {
    return_val_if_fail(dict.is_of_type(new VariantType("a{s*}")), false);
    return get_double(dict.lookup_value(key, null), out result);
}


/**
 * Unbox variant value.
 *
 *  * Null maybe variant is converted to null.
 *  * Child value is returned for values of type variant.
 *
 * @param value    value to unbox
 * @return unboxed value or null
 */
public Variant? unbox(Variant? value) {
    if (value == null) {
        return null;
    }
    if (value.get_type().is_subtype_of(VariantType.MAYBE)) {
        Variant? maybe_variant = null; // "m*" (new reference)
        value.get("m*", &maybe_variant);
        return unbox(maybe_variant);
    }
    if (value.is_of_type(VariantType.VARIANT)) {
        return unbox(value.get_variant());
    }
    return value;
}


/**
 * Converts a typed value to variant.
 *
 * The value format is: "[x:]value", where `value` is the actual value to parse and `x` is the type specifier.
 *
 * The type specifiers are:
 *
 *   *  `d` - double
 *   *  `i` - int
 *   *  `b` - boolean (true or false)
 *   *  `s` - string
 *
 * If the specifier is omitted, the default type is string.
 *
 * @param value    The string value to parse in "[x:]value" format.
 * @return The parsed value as Variant on success, null on failure (wrong format specifier, cannot parse value).
 */
public Variant? parse_typed_value(string value) {
    string?[] parts = value.split(":", 2);
    char type = 's';
    unowned string value_to_parse = value;
    if (parts.length == 2) {
        if (parts[0].length != 1) {
            return null;
        }
        type = parts[0][0];
        value_to_parse = parts[1];
    }
    switch (type) {
    case 'b':
        bool b = false;
        if (!String.is_empty(value_to_parse) && bool.try_parse(value_to_parse, out b)) {
            return new Variant.boolean(b);
        }
        break;
    case 'i':
        int64 i = 0;
        if (!String.is_empty(value_to_parse) && int64.try_parse(value_to_parse, out i)) {
            return new Variant.int64(i);
        }
        break;
    case 'd':
        double d = 0.0;
        if (!String.is_empty(value_to_parse) && double.try_parse(value_to_parse, out d)) {
            return new Variant.double(d);
        }
        break;
    case 's':
        return new Variant.string(value_to_parse);
    }
    return null;
}


/**
 * Print variant as a string.
 *
 * If the variant is null, an empty non-null string is returned.
 *
 * @param variant    Variant to print.
 * @return Printed value.
 */
public string to_string(Variant? variant) {
    return variant != null ? variant.print(false) : "";
}


/**
 * Print a non-null variant as a string.
 *
 * If the variant is null, null is returned.
 *
 * @param variant           Variant to print.
 * @param type_annotate     true if type information should be included in the output.
 * @return Printed value.
 */
public string? print(Variant? variant, bool type_annotate=true) {
    return variant != null ? variant.print(type_annotate) : null;
}

/**
 * Create a string Variant if the passed string is not null,
 *
 * @param str    The string to create a variant from.
 * @return A string Variant if str is not null, null otherwise.
 */
public Variant? from_string_if_not_null(string? str) {
    return str != null ? new Variant.string(str) : null;
}

} // namespace Drt.VariantUtils
