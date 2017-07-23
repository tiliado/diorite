/*
 * Copyright 2015 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt.Value
{

/**
 * Supported types: GLib.Object, GLib.Bytes, GLib.ByteArray, int, uint, int64, uint64, float, double and bool.
 */
public string? to_string(GLib.Value? value)
{
	if (value == null)
		return null;
		
	var type = value.type();
	if (type.is_object())
		return "%p".printf((void*) value.get_object());
	if (type == typeof(int))
		return value.get_int().to_string();
	if (type == typeof(uint))
		return value.get_uint().to_string();
	if (type == typeof(int64))
		return value.get_int64().to_string();
	if (type == typeof(uint64))
		return value.get_uint64().to_string();
	if (type == typeof(string))
		return value.get_string();
	if (type == typeof(bool))
		return value.get_boolean().to_string();
	if (type == typeof(double))
		return value.get_double().to_string();
	if (type == typeof(float))
		return value.get_float().to_string();
	if (type == typeof(GLib.Bytes))
		return Blobs.bytes_to_string((GLib.Bytes) value.get_boxed());
	if (type == typeof(GLib.ByteArray))
		return Blobs.byte_array_to_string((GLib.ByteArray) value.get_boxed());
	if (type.is_a(Type.BOXED))
		return "%p".printf((void*) value.get_boxed());
	if (type.is_classed())
		return "%p".printf((void*) value.peek_pointer());
	
	return null;
}

/**
 * Supported types: GLib.Object, GLib.Bytes, GLib.ByteArray, int, uint, int64, uint64, float, double and bool.
 */
public bool equal(GLib.Value? value1, GLib.Value? value2)
{
	if (value1 == null && value2 == null)
		return true;
	if (!(value1 != null && value2 != null))
		return false;
	
	var type = value1.type();
	if (type != value2.type())
		return false;
	
	if (type == typeof(bool))
		return value1.get_boolean() == value2.get_boolean();
	if (type == typeof(int))
		return value1.get_int() == value2.get_int();
	if (type == typeof(uint))
		return value1.get_uint() == value2.get_uint();
	if (type == typeof(int64))
		return value1.get_int64() == value2.get_int64();
	if (type == typeof(uint64))
		return value1.get_uint64() == value2.get_uint64();
	if (type == typeof(string))
		return value1.get_string() == value2.get_string();
	if (type == typeof(double))
		return value1.get_double() == value2.get_double();
	if (type == typeof(float))
		return value1.get_float() == value2.get_float();
	if (type.is_object())
		return value1.get_object() == value2.get_object();
	if (type == typeof(GLib.Bytes))
		return Blobs.bytes_equal((GLib.Bytes) value1.get_boxed(), (GLib.Bytes) value2.get_boxed());
	if (type == typeof(GLib.ByteArray))
		return Blobs.byte_array_equal((GLib.ByteArray) value1.get_boxed(), (GLib.ByteArray) value2.get_boxed());
	if (type.is_a(Type.BOXED))
		return value1.get_boxed() == value2.get_boxed();
	
	return_val_if_reached(false);
}

/**
 * Supported types: GLib.Object, GLib.Bytes, GLib.ByteArray, int, uint, int64, uint64, float, double and bool.
 */
public string describe(GLib.Value? value)
{
	if (value == null)
		return "<null>";
	var type = value.type();
	var content = to_string(value);
	if (content != null)
		return "<%s:%s>".printf(type.name(), content);
	return "<%s>".printf(type.name());
}

/**
 * Supported types: GLib.Object, GLib.Bytes, GLib.ByteArray, int, uint, int64, uint64, float, double and bool.
 */
public bool equal_verbose(GLib.Value? value1, GLib.Value? value2, out string description)
{
	var result = equal(value1, value2);
	if (result)
		description = "equal %s".printf(describe(value1));
	else
		description = "%s != %s".printf(describe(value1), describe(value2));
	return result;
}

} // namespace Drt.Value
