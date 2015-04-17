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

namespace Diorite
{

public class VectorClock
{
	private HashTable<string, uint> units;
	/**
	 * {{{
	 * new VectorClock();
	 * new VectorClock("A", 10, "B", 11, ...);
	 * }}}
	 */
	public VectorClock(string? unit_name=null, ...)
	{
		units = new HashTable<string, uint>(str_hash, str_equal);
		var args = va_list();
		string? key = unit_name;
		while (key != null)
		{
			uint val = args.arg();
			units[key] = val;
			key = args.arg();	
		}
	}
	
	public void set(string unit, uint clock)
	{
		units[unit] = clock;
	}
	
	public uint get(string unit)
	{
		uint clock;
		if (units.lookup_extended(unit, null, out clock))
			return clock;
		return 0;
	}
	
	public bool contains(string unit)
	{
		return unit in units;
	}
	
	/**
	 * Modifies and returns current VectorClock.
	 */
	public VectorClock increment(string unit)
	{
		this[unit] = this[unit] + 1;
		return this;
	}
	
	/**
	 * Returns and modifies a duplicate of current VectorClock.
	 */
	public VectorClock dup_increment(string unit)
	{
		return dup().increment(unit);
	}
	
	public List<unowned string> get_units()
	{
		return units.get_keys();
	}
	
	public List<unowned string> get_sorted_units()
	{
		var units = get_units();
		units.sort(strcmp);
		return units;
	}
	
	/**
	 * Returns new duplicate of current VectorClock.
	 */
	public VectorClock dup()
	{
		var vector = new VectorClock();
		var keys = get_units();
		foreach (var key in keys)
			vector[key] = units[key];
		return vector;
	}
	
	public string to_string()
	{
		var buffer = new StringBuilder("<");
		var keys = get_sorted_units();
		var comma = false;
		foreach (var key in keys)
		{
			if (comma)
				buffer.append_c('|');
			else
				comma = true;
			
			buffer.append_printf("%s=%u", key, units[key]);
		}
		buffer.append_c('>');
		return buffer.str;
	}
	
	public bool equals(VectorClock other)
	{
		return compare(this, other) == VectorClockComparison.EQUAL;
	}
	
	public bool precedes(VectorClock other)
	{
		return compare(this, other) == VectorClockComparison.SMALLER;
	}
	
	public bool descends(VectorClock other)
	{
		return compare(this, other) == VectorClockComparison.GREATER;
	}
	
	public bool conflicts(VectorClock other)
	{
		return compare(this, other) == VectorClockComparison.SIMULTANEOUS;
	}
	
	public VectorClockComparison compare_with(VectorClock other)
	{
		return compare(this, other);
	}
	
	public Variant to_variant()
	{
		var builder = new VariantBuilder(new VariantType("a{su}"));
		var keys = get_units();
		foreach (var key in keys)
			builder.add("{su}", key, (uint32) units[key]);
		return builder.end();
	}
	
	public static VectorClock from_variant(Variant variant)
	{
		var vector = new VectorClock();
		var iter = variant.iterator();
		string key = null;
		uint32 val = 0;
		while (iter.next("{su}", &key, &val))
			vector[key] = (uint) val;
		return vector;
	}
	
	public GLib.Bytes to_bytes()
	{
		return to_variant().get_data_as_bytes();
	}
	
	public static VectorClock from_bytes(GLib.Bytes bytes)
	{
		return from_variant(new Variant.from_bytes(new VariantType("a{su}"), bytes, false));
	}
	
	public static VectorClockComparison compare(VectorClock vector1, VectorClock vector2)
	{
		var equal = true; // vector1 == vector2
		var smaller = true; // vector1 < vector2
		var greater = true; // vector1 > vector2
		
		foreach (var key in vector1.get_units())
		{
			var clock1 = vector1[key];
			var clock2 = vector2[key];
			if (clock1 < clock2)
			{
				equal = false;  // Cannot be equal
				greater = false;   // Cannot be greater
			}
			else if (clock1 > clock2)
			{
				equal = false;  // Cannot be equal
				smaller = false;  // Cannot be smaller
			}
		}
		
		foreach (var key in vector2.get_units())
		{
			if (!(key in vector1)) // other keys already processed
			{
				var clock1 = 0; // default value
				var clock2 = vector2[key];
				if (clock1 < clock2)
				{
					equal = false;  // Cannot be equal
					greater = false;   // Cannot be greater
				}
				// not possible: else if (clock1 > clock2) 
			}
		}
		
		if (equal)
			return VectorClockComparison.EQUAL;
		if (smaller == greater)
			return VectorClockComparison.SIMULTANEOUS;
		if (smaller)
			return VectorClockComparison.SMALLER;
		
		return VectorClockComparison.GREATER;
	}
	
	/**
	 * Modifies and returns current VectorClock.
	 */
	public VectorClock merge_with(VectorClock other)
	{
		foreach (var key in get_units())
		{
			var other_clock = other[key];
			if (other_clock > this[key])
				this[key] = other_clock;
		}
		foreach (var key in other.get_units())
		{
			if (!(key in this))
				this[key] = other[key];
		}
		return this;
	}
	
	/**
	 * Returns new VectorClock.
	 */
	public static VectorClock merge(VectorClock vclock1, ...)
	{
		var result = new VectorClock();
		var args = va_list();
		VectorClock? vclock = vclock1;
		while (vclock != null)
		{
			result.merge_with(vclock);
			vclock = args.arg();	
		}
		return result;
	}
}

public enum VectorClockComparison
{
	EQUAL,
	SMALLER,
	GREATER,
	SIMULTANEOUS;
	
}

} // namespace Diorite
