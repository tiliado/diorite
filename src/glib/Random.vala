/*
 * Copyright 2016 Jiří Janoušek <janousek.jiri@gmail.com>
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
 * Generate random binary data as a hexadecimal string.
 * 
 * @param n_bits    Number of random bits. Will be rounded up to the nearest byte.
 * @return Random binary data.
 */
public string random_hex(int n_bits)
{
	var n_bytes = n_bits / 8;
	if (n_bytes * 8 < n_bits)
		n_bytes++;    // Round up to the nearest byte
	var n_32bits = n_bytes / 4;
	if (n_32bits * 4 < n_bytes)
		n_32bits++;    // Round up to the whole uint32
	var size = n_32bits * 4;
	uint8[] buffer = new uint8[size];
	for (uint offset = 0; offset + 4 <= size; offset += 4)
		uint32_to_bytes(ref buffer, GLib.Random.next_int(), offset);
	
	string result;
	bin_to_hex(buffer, out result);
	return size == n_bytes ? result : result.substring(0, n_bytes * 2);
}

/**
 * Generate random binary data as a hexadecimal string.
 * 
 * @param n_bits    Number of random bits. Will be rounded up to the nearest byte.
 * @param result    Random binary data.
 */
public void random_bin(int n_bits, out uint8[] result)
{
	var n_bytes = n_bits / 8;
	if (n_bytes * 8 < n_bits)
		n_bytes++;    // Round up to the nearest byte
	var n_32bits = n_bytes / 4;
	if (n_32bits * 4 < n_bytes)
		n_32bits++;    // Round up to the whole uint32
	var size = n_32bits * 4;
	result = new uint8[size];
	for (uint offset = 0; offset + 4 <= size; offset += 4)
		uint32_to_bytes(ref result, GLib.Random.next_int(), offset);
}

} // namespace Drt
