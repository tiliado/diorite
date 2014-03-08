/* 
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * Tests are under public domain because they might contain useful sample code.
 */

using Diorite.Test;

class SerializeTest: Diorite.TestCase
{
	private string? type_sig = null;
	private Variant? variant = null;
	
	public override void set_up()
	{
		type_sig = "(ssbynqiuxthdas)";
		var builder = new VariantBuilder(new VariantType ("as"));
		builder.add("s", "Chemotherapy");
		builder.add("s", "is");
		builder.add("s", "exhausting");
		builder.add("s", "treatment.");
		variant = new Variant(type_sig, "hello", "world", true,
		(uchar) 1, (int16) 2, (uint16) 3, (int32) 4, (uint32) 5, (int64) 6,
		(uint64) 7, (int32) 8, (double) 8.0, builder);
	}
	
	public override void tear_down()
	{
		variant = null;
		type_sig = null;
	}
	
	private void check_variant(Variant vari, bool success)
	{
		string s1 = "";
		string s2 = "";
		bool b = false;
		uchar y = 0;
		int16 n = 0;
		uint16 q = 0;
		int32 i = 0;
		uint32 u = 0;
		int64 x = 0;
		uint64 t = 0;
		int32 h = 0;
		double d = 0.5;
		vari.get(type_sig, &s1, &s2, &b, &y, &n, &q, &i, &u, &x, &t, &h, &d);
		if (success)
		{
			expect(s1 == "hello");
			expect(s2 == "world");
			expect(b == true);
			expect(y == (uchar) 1);
			expect(n == (int16) 2);
			expect(q == (uint16) 3);
			expect(i == (int32) 4);
			expect(u == (uint32) 5);
			expect(x == (int64) 6);
			expect(t == (uint64) 7);
			expect(h == (int32) 8);
			expect(d == (double) 8.0);
		}
		else
		{
			expect(s1 != "hello");
			expect(s2 != "world");
			expect(b == true);
			expect(y != (uchar) 1);
			expect(n != (int16) 2);
			expect(q != (uint16) 3);
			expect(i != (int32) 4);
			expect(u != (uint32) 5);
			expect(x != (int64) 6);
			expect(t != (uint64) 7);
			expect(h != (int32) 8);
			expect(d != (double) 8.0);
		}
	}
	
	[DTest(start=0, end=17)]
	public void test_serialize_variant(int offset)
	{
		assert(variant != null);
		var size = variant.get_size();
		uint8[] buffer;
		bool success;
		
		buffer = new uint8[size/2];
		success = Diorite.serialize_variant(variant, buffer, offset);
		expect(!success);
		
		buffer = new uint8[size];
		success = Diorite.serialize_variant(variant, buffer, offset);
		if (offset == 0)
		{
			expect(success);
		}
		else
		{
			expect(!success);
		}
		
		buffer = new uint8[size + 16];
		success = Diorite.serialize_variant(variant, buffer, offset);
		if (offset % 8 == 0)
		{
			expect(success);
		}
		else
		{
			expect(!success);
		}
	}
	
	[DTest(start=0, end=9)]
	public void test_deserialize_variant(int offset)
	{
		assert(variant != null);
		var size = variant.get_size();
		uint8[] buffer;
		bool success;
		
		buffer = new uint8[size];
		success = Diorite.serialize_variant(variant, buffer, 0);
		assert(success);
		
		var result = Diorite.deserialize_variant(type_sig, (owned) buffer, offset);
		if (offset % 8 == 0)
		{
			assert(result != null);
			check_variant(result, offset == 0);
		}
		else
		{
			expect(result == null);
		}
	}
	
	[DTest(start=8, end=50, step=8)]
	public void test_deserialize_variant_offset(int offset)
	{
		assert(variant != null);
		var size = variant.get_size();
		uint8[] buffer;
		bool success;
		
		buffer = new uint8[size + offset];
		success = Diorite.serialize_variant(variant, buffer, offset);
		assert(success);
		
		var result = Diorite.deserialize_variant(type_sig, (owned) buffer, offset);
		assert(result != null);
		check_variant(result, true);
	}
	
	[DTest(start=0, end=50, step=3)]
	public void test_serialize_message(int offset)
	{
		var name = "offset%d".printf(offset);
		uint8[] buffer = Diorite.serialize_message(name, variant, offset);
		string? name2 = null;
		Variant? params = null;
		assert(Diorite.deserialize_message((owned) buffer, out name2, out params, offset));
		expect(name == name2);
		check_variant(params, true);
	}
	
	[DTest(start=0, end=50, step=3)]
	public void test_serialize_message_null_variant(int offset)
	{
		var name = "offset%d".printf(offset);
		uint8[] buffer = Diorite.serialize_message(name, null, offset);
		string? name2 = null;
		Variant? params = null;
		assert(Diorite.deserialize_message((owned) buffer, out name2, out params, offset));
		expect(name == name2);
		expect(params == null);
	}
}
