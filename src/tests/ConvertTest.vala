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

public class ConvertTest: Drt.TestCase {
    public void test_int64_to_bin() throws Drt.TestError {
        var rand = new Rand();
        int64 val;
        uint8[] data;
        int64 result;

        int64[] values = {int64.MIN, int32.MIN, 0, int32.MAX, int64.MAX};
        foreach (int64 i in values) {
            val = i;
            int64_to_bin(val, out data);
            // FIXME: round-trip is ok, but are the negative values really stored correctly?
            assert(bin_to_int64(data, out result), "");
            assert(val == result, @"$val == $result");
        }

        for (int i = 0; i < 100; i++) {
            val = 2 * ((int64) rand.int_range(int32.MIN, int32.MAX));
            int64_to_bin(val, out data);
            assert(bin_to_int64(data, out result), "");
            assert(val == result, @"$val == $result");
        }
    }

    public void test_bin_to_hex() throws Drt.TestError {
        string[] values = {"01", "aa", "bb", "cc", "aabbcc", "deadbeef"};
        var rand = new Rand();
        uint8[] data;
        string result;

        foreach (unowned string i in values) {
            assert(hex_to_bin(i, out data), "hex_to_bin");
            bin_to_hex(data, out result);
            assert(i == result, @"$i == $result");
        }

        char[] separators = {'\0', ':', ' ', '.'};
        foreach (char sep in separators) {
            for (var i = 0; i < 10; i++) {
                var size = rand.int_range(1, 50);
                uint8[] orig = new uint8[size];
                for (var j = 0; j < size; j++) {
                    orig[j] = (uint8) rand.int_range(uint8.MIN, uint8.MAX);
                }
                string hex;
                bin_to_hex(orig, out hex, sep);
                uint8[] output;
                assert(hex_to_bin(hex, out output, sep), "hex_to_bin");
                assert(output.length == size, @"$(output.length) == $size");
                for (var k = 0; k < size; k++) {
                    assert(orig[k] == output[k], "");
                }
            }
        }

        string[] invalid_hex = {"a", "abc", "efgh"};
        foreach (unowned string invalid in invalid_hex) {
            assert(!hex_to_bin(invalid, out data), "");
        }

        invalid_hex = {"aa:", "ab:c", "a:bb:a", "ef:gh"};
        foreach (unowned string invalid in invalid_hex) {
            assert(!hex_to_bin(invalid, out data, ':'), "invalid '%s'", invalid);
        }
    }

    public void test_int64_to_hex() throws Drt.TestError {
        var rand = new Rand();
        int64 val;
        string data;
        int64 result;
        int64[] values = {int64.MIN, int32.MIN, 0, int32.MAX, int64.MAX};
        foreach (int64 i in values) {
            val = i;
            int64_to_hex(val, out data);
            assert(hex_to_int64(data, out result), "");
            assert(val == result, @"$val == $result");
        }
        for (var i = 0; i < 100; i++) {
            val = 2 * ((int64) rand.int_range(int32.MIN, int32.MAX));
            int64_to_hex(val, out data);
            assert(hex_to_int64(data, out result), "");
            assert(val == result, @"$val == $result");
        }
    }
}

} // namespace Nuvola
