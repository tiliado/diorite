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

namespace Drt
{

public class BlobsTest: Drt.TestCase
{
	public void test_blob_equal()
	{
		uint8[] blob_0_items_1 = {};
		uint8[] blob_0_items_2 = {};
		uint8[] blob_7_items_1 = {1, 2, 3, 4, 5, 6, 7};
		uint8[] blob_7_items_2 = {1, 2, 3, 4, 5, 6, 7};
		uint8[] blob_7_items_3 = {1, 2, 3, 4, 5, 6, 6};
		uint8[] blob_8_items = {1, 2, 3, 4, 5, 6, 7, 6};
		
		expect_true(Blobs.blob_equal(null, null), "null == null");
		expect_true(Blobs.blob_equal(blob_0_items_1, blob_0_items_2), "0 items == 0 items");
		expect_true(Blobs.blob_equal(blob_7_items_1, blob_7_items_2), "7 items == 7 items");
		expect_false(Blobs.blob_equal(blob_7_items_1, blob_7_items_3), "7 items != 7 items");
		expect_false(Blobs.blob_equal(blob_7_items_1, blob_8_items), "7 items != 8 items");
		expect_false(Blobs.blob_equal(blob_8_items, null), "8 items != null");
		expect_false(Blobs.blob_equal(null, blob_8_items), "null != 8 items");
	}
	
	public void test_bytes_equal()
	{
		var blob_0_items_1 = new GLib.Bytes.take(new uint8[]{});
		var blob_0_items_2 = new GLib.Bytes.take(new uint8[]{});
		var blob_7_items_1 = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
		var blob_7_items_2 = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
		var blob_7_items_3 = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 6});
		var blob_8_items = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 6});
		
		expect_true(Blobs.bytes_equal(null, null), "null == null");
		expect_true(Blobs.bytes_equal(blob_0_items_1, blob_0_items_2), "0 items == 0 items");
		expect_true(Blobs.bytes_equal(blob_7_items_1, blob_7_items_2), "7 items == 7 items");
		expect_false(Blobs.bytes_equal(blob_7_items_1, blob_7_items_3), "7 items != 7 items");
		expect_false(Blobs.bytes_equal(blob_7_items_1, blob_8_items), "7 items != 8 items");
		expect_false(Blobs.bytes_equal(blob_8_items, null), "8 items != null");
		expect_false(Blobs.bytes_equal(null, blob_8_items), "null != 8 items");
	}
	
	public void test_byte_array_equal()
	{
		var blob_0_items_1 = new GLib.ByteArray.take(new uint8[]{});
		var blob_0_items_2 = new GLib.ByteArray.take(new uint8[]{});
		var blob_7_items_1 = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
		var blob_7_items_2 = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
		var blob_7_items_3 = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 6});
		var blob_8_items = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 6});
		
		expect_true(Blobs.byte_array_equal(null, null), "null == null");
		expect_true(Blobs.byte_array_equal(blob_0_items_1, blob_0_items_2), "0 items == 0 items");
		expect_true(Blobs.byte_array_equal(blob_7_items_1, blob_7_items_2), "7 items == 7 items");
		expect_false(Blobs.byte_array_equal(blob_7_items_1, blob_7_items_3), "7 items != 7 items");
		expect_false(Blobs.byte_array_equal(blob_7_items_1, blob_8_items), "7 items != 8 items");
		expect_false(Blobs.byte_array_equal(blob_8_items, null), "8 items != null");
		expect_false(Blobs.byte_array_equal(null, blob_8_items), "null != 8 items");
	}
	
	public void test_blob_to_string()
	{
		uint8[] blob_0_items = {};
		uint8[] blob_7_items_1 = {1, 2, 3, 4, 5, 6, 7};
		uint8[] blob_7_items_2 = {1, 2, 3, 4, 5, 6, 6};
		uint8[] blob_8_items = {1, 2, 3, 4, 5, 6, 7, 6};
		
		expect_str_equals(null, Blobs.blob_to_string(null), "null");
		expect_str_equals(null, Blobs.blob_to_string(blob_0_items), "0 items");
		expect_str_equals("01020304050607", Blobs.blob_to_string(blob_7_items_1), "7 items 1");
		expect_str_equals("01020304050606", Blobs.blob_to_string(blob_7_items_2), "7 items 2");
		expect_str_equals("0102030405060706", Blobs.blob_to_string(blob_8_items), "8 items");
	}
	
	public void test_bytes_to_string()
	{
		var bytes_0_items = new GLib.Bytes.take(new uint8[]{});
		var bytes_7_items_1 = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
		var bytes_7_items_2 = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 6});
		var bytes_8_items = new GLib.Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 6});
		
		expect_str_equals(null, Blobs.bytes_to_string(null), "null");
		expect_str_equals(null, Blobs.bytes_to_string(bytes_0_items), "0 items");
		expect_str_equals("01020304050607", Blobs.bytes_to_string(bytes_7_items_1), "7 items 1");
		expect_str_equals("01020304050606", Blobs.bytes_to_string(bytes_7_items_2), "7 items 2");
		expect_str_equals("0102030405060706", Blobs.bytes_to_string(bytes_8_items), "8 items");
	}
	
	public void test_byte_array_to_string()
	{
		var byte_array_0_items = new GLib.ByteArray.take(new uint8[]{});
		var byte_array_7_items_1 = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
		var byte_array_7_items_2 = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 6});
		var byte_array_8_items = new GLib.ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 6});
		
		expect_str_equals(null, Blobs.byte_array_to_string(null), "null");
		expect_str_equals(null, Blobs.byte_array_to_string(byte_array_0_items), "0 items");
		expect_str_equals("01020304050607", Blobs.byte_array_to_string(byte_array_7_items_1), "7 items 1");
		expect_str_equals("01020304050606", Blobs.byte_array_to_string(byte_array_7_items_2), "7 items 2");
		expect_str_equals("0102030405060706", Blobs.byte_array_to_string(byte_array_8_items), "8 items");
	}
}

} // namespace Drt
