/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
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
	public const uint SERIALIZE_ALIGN = 8;

	/**
	 * Serializes Variant to byte array at given offset.
	 *
	 * @param variant    variant value to store
	 * @param buffer     byte array to store variant at, must be large enough (see Varian.get_size())
	 * @param offset     starting offset to store value at, must be aligned to 8 bytes
	 * @return true on success, false if requirements haven't been met
	 */
	public bool serialize_variant(Variant variant, uint8[] buffer, uint offset=0)
	{
		return_val_if_fail(buffer.length - offset >= variant.get_size(), false);
		return_val_if_fail(offset % SERIALIZE_ALIGN == 0, false);
		uint8* p = (uint8*) buffer + offset;
		variant.store(p);
		return true;
	}

	/**
	 * Serializes message to byte array at given offset.
	 *
	 * @param name      message name
	 * @param parameters    message parameters
	 * @param offset    starting offset to store data at, use for your own data (e.g. format signature)
	 * @return byte array with serialized message
	 */
	public uint8[] serialize_message(string name, Variant? parameters, uint offset=0)
	{
		string type_str = parameters != null ? parameters.get_type_string() : "";
		uint variant_offset = (uint) (offset + name.length + 1 + type_str.length + 1);
		if (variant_offset % SERIALIZE_ALIGN != 0)
			variant_offset += SERIALIZE_ALIGN - (variant_offset % SERIALIZE_ALIGN);

		uint32 buffer_size = (uint32) (variant_offset + (parameters != null ? parameters.get_size() : 0));
		uint8[] buffer = new uint8[buffer_size];
		uint8* p = buffer;

		uint size = name.length + 1;
		Memory.copy(p + offset, (void*) name, size);
		offset += size;

		size = type_str.length + 1;
		Memory.copy(p + offset, (void*) type_str, size);
		offset += size;

		if (parameters != null)
			assert(serialize_variant(parameters, buffer, variant_offset));
		return buffer;
	}

	/**
	 * Deserializes Variant from byte array at given offset.
	 *
	 * @param type_sig    valid variant type signature
	 * @param buffer      byte array read data from. array will be freed asynchronously, see Variant.new_from_data
	 * @param offset      starting offset to read data from, must be aligned to 8 bytes
	 * @param trusted     whether data comes from trusted source
	 * @return Variant on success, null if requirements haven't been met
	 */
	public Variant? deserialize_variant(string type_sig, owned uint8[] buffer, uint offset=0, bool trusted=false)
	{
		return_val_if_fail(VariantType.string_is_valid(type_sig), null);
		return_val_if_fail(offset % SERIALIZE_ALIGN == 0, null);
		unowned uint8[] real_data = (uint8[])((uint8*)buffer + offset);
		real_data.length =  (int) (buffer.length - offset); // SIGSEGV without this!
		var type = new VariantType(type_sig);
		var variant = Variant.new_from_data(type, real_data, trusted, (owned) buffer);
		return variant;
	}

	/**
	 * Deserializes message from byte array at given offset.
	 *
	 * @param buffer    byte array to read data from, array will be freed asynchronously, see Variant.new_from_data
	 * @param name      message name
	 * @param parameters    message parameters
	 * @param offset    starting offset to store data at, use for your own data (e.g. format signature)
	 * @return true on success, false on failure (i. e. invalid data)
	 */
	public bool deserialize_message(owned uint8[] buffer, out string name, out Variant? parameters, uint offset=0)
	{
		name = null;
		parameters = null;
		uint32 limit = buffer.length - offset;
		uint8* p = (uint8*)buffer + offset;

		/* find name string */
		uint8* index = Posix.memchr(p, 0, limit);
		return_val_if_fail(index != null && index - p > 0, false);
		uint size = (uint) (index - p + 1);
		var tmp_name = (string) Memory.dup(p, size);

		offset += size;
		p += size;
		limit -= size;

		/* find type string */
		index = Posix.memchr(p, 0, limit);
		return_val_if_fail(index != null && index - p >= 0, false);
		size = (uint) (index - p + 1);
		string type_str = (string) Memory.dup(p, size);
		offset += size;

		if (offset % SERIALIZE_ALIGN != 0)
			offset += SERIALIZE_ALIGN - offset % SERIALIZE_ALIGN;

		if (type_str != "")
		{
			parameters = deserialize_variant(type_str, (owned) buffer, offset);
			return_val_if_fail(parameters != null, false);
		}

		name = (owned) tmp_name;
		return true;
	}

	public Variant serialize_error(GLib.Error e)
	{
		return new Variant("(sis)", e.domain.to_string(), e.code, e.message);
	}

	public GLib.Error deserialize_error(Variant e)
	{
		string domain = null;
		int code = 0;
		string message = null;
		e.get("(sis)", ref domain, ref code, ref message);
		return new GLib.Error(GLib.Quark.from_string(domain), code, "%s", message);
	}
} // namespace Drt
