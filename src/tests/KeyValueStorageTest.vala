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

namespace Diorite
{

public abstract class KeyValueStorageTest: Diorite.TestCase
{
	protected KeyValueStorage storage = null;
	
	public void test_get_null_for_empty_keys() throws Diorite.TestError
	{
		assert(storage != null, "");
		expect(storage.get_value("key1") == null, "");
		expect(storage.get_value("key2") == null, "");
		expect(storage.get_value("key3") == null, "");
		expect(storage.get_value("key4.subkey1") == null, "");
		expect(storage.get_value("key4.subkey2") == null, "");
		expect(storage.get_value("key4.subkey3") == null, "");
	}
	
	public void test_set_get_default_value() throws Diorite.TestError
	{
		assert(storage != null, "");
		Variant v;
		string key;
		
		key = "key1";
		v = new Variant.int32(int32.MAX);
		storage.set_default_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key2";
		v = new Variant.string("hello");
		storage.set_default_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key3";
		v = new Variant.double(3.14);
		storage.set_default_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key4.subkey1";
		v = new Variant.int64(int64.MAX);
		storage.set_default_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key4.subkey2";
		v = new Variant.boolean(true);
		storage.set_default_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
	}
	
	public void test_set_get_value_no_default() throws Diorite.TestError
	{
		assert(storage != null, "");
		Variant v;
		string key;
		
		key = "key1";
		v = new Variant.int32(int32.MAX);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key2";
		v = new Variant.string("hello");
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key3";
		v = new Variant.double(3.14);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key4.subkey1";
		v = new Variant.int64(int64.MAX);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key4.subkey2";
		v = new Variant.boolean(true);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
	}
	
	public void test_set_get_value_with_default() throws Diorite.TestError
	{
		assert(storage != null, "");
		Variant d1 = new Variant.string("default1");
		Variant d2 = new Variant.string("default2");
		Variant v;
		string key;
		
		key = "key1";
		v = new Variant.int32(int32.MAX);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		storage.set_default_value(key, d2);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key2";
		v = new Variant.string("hello");
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		storage.set_default_value(key, d2);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key3";
		v = new Variant.double(3.14);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		storage.set_default_value(key, d2);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key4.subkey1";
		v = new Variant.int64(int64.MAX);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		storage.set_default_value(key, d2);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		
		key = "key4.subkey2";
		v = new Variant.boolean(true);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
		storage.set_default_value(key, d2);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(v), "");
	}
	
	public void test_unset_with_default() throws Diorite.TestError
	{
		assert(storage != null, "");
		Variant d1 = new Variant.string("default1");
		Variant v;
		string key;
		
		key = "key1";
		v = new Variant.int32(int32.MAX);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		storage.unset(key);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(d1), "");
		
		key = "key2";
		v = new Variant.string("hello");
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		storage.unset(key);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(d1), "");
		
		key = "key3";
		v = new Variant.double(3.14);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		storage.unset(key);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(d1), "");
		
		key = "key4.subkey1";
		v = new Variant.int64(int64.MAX);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		storage.unset(key);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(d1), "");
		
		key = "key4.subkey2";
		v = new Variant.boolean(true);
		storage.set_default_value(key, d1);
		storage.set_value(key, v);
		storage.unset(key);
		expect(storage.get_value(key) != null, "");
		expect(storage.get_value(key).equal(d1), "");
	}
}

} // namespace Nuvola
