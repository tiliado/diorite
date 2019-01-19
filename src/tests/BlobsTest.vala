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

namespace Drt {

public class BlobsTest: Drt.TestCase {
    public void test_blob_equal() {
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

    public void test_bytes_equal() {
        var blob_0_items_1 = new GLib.Bytes.take(new uint8[] {});
        var blob_0_items_2 = new GLib.Bytes.take(new uint8[] {});
        var blob_7_items_1 = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 7});
        var blob_7_items_2 = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 7});
        var blob_7_items_3 = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 6});
        var blob_8_items = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 7, 6});

        expect_true(Blobs.bytes_equal(null, null), "null == null");
        expect_true(Blobs.bytes_equal(blob_0_items_1, blob_0_items_2), "0 items == 0 items");
        expect_true(Blobs.bytes_equal(blob_7_items_1, blob_7_items_2), "7 items == 7 items");
        expect_false(Blobs.bytes_equal(blob_7_items_1, blob_7_items_3), "7 items != 7 items");
        expect_false(Blobs.bytes_equal(blob_7_items_1, blob_8_items), "7 items != 8 items");
        expect_false(Blobs.bytes_equal(blob_8_items, null), "8 items != null");
        expect_false(Blobs.bytes_equal(null, blob_8_items), "null != 8 items");
    }

    public void test_byte_array_equal() {
        var blob_0_items_1 = new GLib.ByteArray.take(new uint8[] {});
        var blob_0_items_2 = new GLib.ByteArray.take(new uint8[] {});
        var blob_7_items_1 = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 7});
        var blob_7_items_2 = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 7});
        var blob_7_items_3 = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 6});
        var blob_8_items = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 7, 6});

        expect_true(Blobs.byte_array_equal(null, null), "null == null");
        expect_true(Blobs.byte_array_equal(blob_0_items_1, blob_0_items_2), "0 items == 0 items");
        expect_true(Blobs.byte_array_equal(blob_7_items_1, blob_7_items_2), "7 items == 7 items");
        expect_false(Blobs.byte_array_equal(blob_7_items_1, blob_7_items_3), "7 items != 7 items");
        expect_false(Blobs.byte_array_equal(blob_7_items_1, blob_8_items), "7 items != 8 items");
        expect_false(Blobs.byte_array_equal(blob_8_items, null), "8 items != null");
        expect_false(Blobs.byte_array_equal(null, blob_8_items), "null != 8 items");
    }

    public void test_blob_to_string() {
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

    public void test_bytes_to_string() {
        var bytes_0_items = new GLib.Bytes.take(new uint8[] {});
        var bytes_7_items_1 = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 7});
        var bytes_7_items_2 = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 6});
        var bytes_8_items = new GLib.Bytes.take(new uint8[] {1, 2, 3, 4, 5, 6, 7, 6});

        expect_str_equals(null, Blobs.bytes_to_string(null), "null");
        expect_str_equals(null, Blobs.bytes_to_string(bytes_0_items), "0 items");
        expect_str_equals("01020304050607", Blobs.bytes_to_string(bytes_7_items_1), "7 items 1");
        expect_str_equals("01020304050606", Blobs.bytes_to_string(bytes_7_items_2), "7 items 2");
        expect_str_equals("0102030405060706", Blobs.bytes_to_string(bytes_8_items), "8 items");
    }

    public void test_byte_array_to_string() {
        var byte_array_0_items = new GLib.ByteArray.take(new uint8[] {});
        var byte_array_7_items_1 = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 7});
        var byte_array_7_items_2 = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 6});
        var byte_array_8_items = new GLib.ByteArray.take(new uint8[] {1, 2, 3, 4, 5, 6, 7, 6});

        expect_str_equals(null, Blobs.byte_array_to_string(null), "null");
        expect_str_equals(null, Blobs.byte_array_to_string(byte_array_0_items), "0 items");
        expect_str_equals("01020304050607", Blobs.byte_array_to_string(byte_array_7_items_1), "7 items 1");
        expect_str_equals("01020304050606", Blobs.byte_array_to_string(byte_array_7_items_2), "7 items 2");
        expect_str_equals("0102030405060706", Blobs.byte_array_to_string(byte_array_8_items), "8 items");
    }

    public void test_int64_to_and_from_blob_samples() throws Drt.TestError {
        int64 val;
        uint8[] data;
        uint8[] expected;
        int64 result;

        int64[] values = {int64.MIN, int32.MIN, -1, 0, 1, int32.MAX, int64.MAX};
        // int64 = 64 bits = 8 bytes
        // https://en.wikipedia.org/wiki/Signed_number_representations#Two's_complement
        // Invert all the bits through the number, then add one.
        uint8[,] blobs = {
            {128, 0, 0, 0, 0, 0, 0, 0}, // −9,223,372,036,854,775,808
            {255, 255, 255, 255, 128, 0, 0, 0}, // −2,147,483,648
            {255, 255, 255, 255, 255, 255, 255, 255}, // -1
            {0, 0, 0, 0, 0, 0, 0, 0}, // 0
            {0, 0, 0, 0, 0, 0, 0, 1}, // 1
            {0, 0, 0, 0, 127, 255, 255, 255}, // +2,147,483,647
            {127, 255, 255, 255, 255, 255, 255, 255}, // +9,223,372,036,854,775,807
        };
        for (int i = 0; i < values.length; i++) {
            val = values[i];
            expected = Drt.Arrays.from_2d_uint8(blobs, i);
            Blobs.int64_to_blob(val, out data);
            expect_blob_equal(expected, data, @"$i: int64 value");
            assert(Blobs.int64_from_blob(data, out result), @"$i: int64_from_blob");
            assert(val == result, @"$i: $val == $result");
        }
    }

    public void test_int64_to_and_from_blob_random() throws Drt.TestError {
        var rand = new Rand();
        int64 val;
        uint8[] data;
        int64 result;
        for (int i = 0; i < 100; i++) {
            val = 2 * ((int64) rand.int_range(int32.MIN, int32.MAX));
            Blobs.int64_to_blob(val, out data);
            assert(Blobs.int64_from_blob(data, out result), @"$i ($val): int64_from_blob");
            assert(val == result, @"$i: $val == $result");
        }
    }

    public void test_int64_from_blob_too_large() throws Drt.TestError {
        uint8[] data = {0, 255, 255, 255, 255, 255, 255, 255, 255};
        int64 result;
        expect_false(Blobs.int64_from_blob(data, out result), "9 bytes is too much for int64");
    }

    public void test_hexadecimal_from_blob() throws Drt.TestError {
        string[] values = {"01", "aa", "bb", "cc", "aabbcc", "deadbeef"};
        var rand = new Rand();
        uint8[] data;
        string result;

        foreach (unowned string i in values) {
            assert(Blobs.hexadecimal_to_blob(i, out data), "Blobs.hexadecimal_to_blob");
            Blobs.hexadecimal_from_blob(data, out result);
            assert(i == result, @"$i == $result");
        }

        char[] separators = {'\0', ':', ' ', '.'};
        foreach (char sep in separators) {
            for (var i = 0; i < 10; i++) {
                int size = rand.int_range(1, 50);
                uint8[] orig = new uint8[size];
                for (var j = 0; j < size; j++) {
                    orig[j] = (uint8) rand.int_range(uint8.MIN, uint8.MAX);
                }
                string hex;
                Blobs.hexadecimal_from_blob(orig, out hex, sep);
                uint8[] output;
                assert(Blobs.hexadecimal_to_blob(hex, out output, sep), "Blobs.hexadecimal_to_blob");
                assert(output.length == size, @"$(output.length) == $size");
                for (var k = 0; k < size; k++) {
                    assert(orig[k] == output[k], "");
                }
            }
        }

        string[] invalid_hex = {"a", "abc", "efgh"};
        foreach (unowned string invalid in invalid_hex) {
            assert(!Blobs.hexadecimal_to_blob(invalid, out data), "");
        }

        invalid_hex = {"aa:", "ab:c", "a:bb:a", "ef:gh"};
        foreach (unowned string invalid in invalid_hex) {
            assert(!Blobs.hexadecimal_to_blob(invalid, out data, ':'), "invalid '%s'", invalid);
        }
    }

    public void test_int64_to_hexadecimal() throws Drt.TestError {
        var rand = new Rand();
        int64 val;
        string data;
        int64 result;
        int64[] values = {int64.MIN, int32.MIN, 0, int32.MAX, int64.MAX};
        foreach (int64 i in values) {
            val = i;
            Blobs.int64_to_hexadecimal(val, out data);
            assert(Blobs.int64_from_hexadecimal(data, out result), "");
            assert(val == result, @"$val == $result");
        }
        for (var i = 0; i < 100; i++) {
            val = 2 * ((int64) rand.int_range(int32.MIN, int32.MAX));
            Blobs.int64_to_hexadecimal(val, out data);
            assert(Blobs.int64_from_hexadecimal(data, out result), "");
            assert(val == result, @"$val == $result");
        }
    }
}

} // namespace Drt
