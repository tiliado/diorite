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

namespace Drt.Blobs
{

public bool blob_equal(uint8[]? value1, uint8[]? value2)
{
	if (value1 == null && value2 == null)
		return true;
	
	if (!(value1 != null && value2 != null) || value1.length != value2.length)
		return false;
	
	for (var i = 0; i < value1.length; i++)
		if (value1[i] != value2[i])
			return false;
	
	return true;
}

public bool bytes_equal(GLib.Bytes? value1, GLib.Bytes? value2)
{
	return blob_equal(value1 != null ? value1.get_data() : null, value2 != null ? value2.get_data() : null);
}

public bool byte_array_equal(GLib.ByteArray? value1, GLib.ByteArray? value2)
{
	return blob_equal(value1 != null ? value1.data : null, value2 != null ? value2.data : null);
}

public string? blob_to_string(uint8[]? value)
{
	if (value == null)
		return null;
	string hex;
	bin_to_hex(value, out hex, '\0');
	return hex;
}

public string? bytes_to_string(GLib.Bytes? value)
{
	return blob_to_string(value != null ? value.get_data() : null);
}

public string? byte_array_to_string(GLib.ByteArray? value)
{
	return blob_to_string(value != null ? value.data : null);
}

} // namespace Drt.Blobs
