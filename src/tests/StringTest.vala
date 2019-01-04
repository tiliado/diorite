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

using Drt.Utils;

namespace Drt {

public class StringTest: Drt.TestCase {
    public void test_semicolon_separated_set() {
        GenericSet<string> result = Drt.String.semicolon_separated_set(null, true);
        expect_uint_equals(0, result.length, "null string");
        result = Drt.String.semicolon_separated_set("", true);
        expect_uint_equals(0, result.length, "empty string");
        result = Drt.String.semicolon_separated_set(";", true);
        expect_uint_equals(0, result.length, "empty set");
        var dataset = " hello ; Bye;;1234;byE;;;";
        result = Drt.String.semicolon_separated_set(dataset, false);
        expect_uint_equals(4, result.length, "original set");
        foreach (unowned string s in new string[] {"hello", "Bye", "1234", "byE"}) {
            expect_true(result.contains(s), "item: %s", s);
        }
        expect_false(result.contains("bye"), "item: %s", "bye");
        result = Drt.String.semicolon_separated_set(dataset, true);
        expect_uint_equals(3, result.length, "lowercase set");
        foreach (unowned string s in new string[] {"hello", "bye", "1234"}) {
            expect_true(result.contains(s), "item: %s", s);
        }
        expect_false(result.contains("Bye"), "item: %s", "Bye");
    }

    public void test_concat() {
        expect_str_equals("bar", Drt.String.concat(null, "foo", "bar"), "");
        expect_str_equals("bar", Drt.String.concat("", "foo", "bar"), "");
        expect_str_equals("xfoobar", Drt.String.concat("x", "foo", "bar"), "");

        expect_str_equals("bar", Drt.String.concat(null, null, "bar"), "");
        expect_str_equals("bar", Drt.String.concat("", null, "bar"), "");
        expect_str_equals("xbar", Drt.String.concat("x", null, "bar"), "");

        expect_str_equals("bar", Drt.String.concat(null, "", "bar"), "");
        expect_str_equals("bar", Drt.String.concat("", "", "bar"), "");
        expect_str_equals("xbar", Drt.String.concat("x", "", "bar"), "");
    }

    public void test_append() {
        string? buffer = null;

        buffer = null;
        Drt.String.append(ref buffer, "foo", "bar");
        expect_str_equals("bar", buffer, "");
        buffer = null;
        Drt.String.append(ref buffer, null, "bar");
        expect_str_equals("bar", buffer, "");
        buffer = null;
        Drt.String.append(ref buffer, "", "bar");
        expect_str_equals("bar", buffer, "");

        buffer = "";
        Drt.String.append(ref buffer, "foo", "bar");
        expect_str_equals("bar", buffer, "");
        buffer = "";
        Drt.String.append(ref buffer, null, "bar");
        expect_str_equals("bar", buffer, "");
        buffer = "";
        Drt.String.append(ref buffer, "", "bar");
        expect_str_equals("bar", buffer, "");

        buffer = "x";
        Drt.String.append(ref buffer, "foo", "bar");
        expect_str_equals("xfoobar", buffer, "");
        buffer = "x";
        Drt.String.append(ref buffer, null, "bar");
        expect_str_equals("xbar", buffer, "");
        buffer = "x";
        Drt.String.append(ref buffer, "", "bar");
        expect_str_equals("xbar", buffer, "");
    }

    public void test_unmask() {
        uint8[] data = {46, 143, 144, 145, 146, 147, 148};
        string? actual = Drt.String.unmask(data);
        expect_str_equals("abcdef", actual, "valid");

        data = {};
        actual = Drt.String.unmask(data);
        expect_null<string>(actual, "zero items  not enough");

        data = {46};
        actual = Drt.String.unmask(data);
        expect_null<string>(actual, "1 item not enough");

        data = {46, 143};
        actual = Drt.String.unmask(data);
        expect_str_equals("a", actual, "2 items enough");

        data = {146, 143};
        actual = Drt.String.unmask(data);
        expect_null<string>(actual, "invalid offset");
    }

    public void test_as_array_of_bytes() {
        string? str = null;
        uint8[] array = Drt.String.as_array_of_bytes((owned) str);
        expect_null<void*>(array, "null string leads to null array");
        expect_log_message(
            "DioriteGlib", LogLevelFlags.LEVEL_CRITICAL, "drt_string_as_array_of_bytes: assertion 'str != NULL' failed",
            "null string produces critical warning");

        str = "";
        unowned string str0 = str;
        array = Drt.String.as_array_of_bytes((owned) str);
        expect_null<void*>(str, "string ownership transferred");
        expect_true((void*) array == (void*) str0, "The address of the data has not changed");
        expect_not_null<void*>(array, "empty string produces non-null result");
        expect_int_equals(0, array.length, "empty string produces 0-length array");
        expect_uint_equals(0, array[0], "empty string produces 0-length array with [0] == '\\0'");

        str = "abc";
        str0 = str;
        array = Drt.String.as_array_of_bytes((owned) str);
        expect_null<void*>(str, "string ownership transferred");
        expect_true((void*) array == (void*) str0, "The address of the data has not changed");
        expect_not_null<void*>(array, "empty string produces non-null result");
        expect_int_equals(3, array.length, "abc string produces 3-length array");
        expect_uint_equals(0, array[3], "abc string produces 3-length array with [3] == '\\0'");
        expect_bytes_equal(new Bytes.take({'a', 'b', 'c'}), new Bytes.static(array), "strings equal");
    }

    public void test_as_bytes() {
        string? str = null;
        Bytes? bytes = Drt.String.as_bytes((owned) str);
        expect_null<void*>(bytes, "null string leads to null Bytes");
        expect_log_message(
            "DioriteGlib", LogLevelFlags.LEVEL_CRITICAL, "drt_string_as_bytes: assertion 'str != NULL' failed",
            "null string produces critical warning");

        str = "";
        unowned string str0 = str;
        bytes = Drt.String.as_bytes((owned) str);
        expect_null<void*>(str, "string ownership transferred");
        expect_not_null<void*>(bytes, "empty string produces non-null result");
        unowned uint8[] array = bytes.get_data();
        expect_true((void*) array == (void*) str0, "The address of the data has not changed");
        expect_int_equals(0, array.length, "empty string produces 0-length array");
        expect_uint_equals(0, array[0], "empty string produces 0-length array with [0] == '\\0'");

        str = "abc";
        str0 = str;
        bytes = Drt.String.as_bytes((owned) str);
        expect_null<void*>(str, "string ownership transferred");
        expect_not_null<void*>(bytes, "empty string produces non-null result");
        array = bytes.get_data();
        expect_true((void*) array == (void*) str0, "The address of the data has not changed");
        expect_int_equals(3, array.length, "abc string produces 3-length array");
        expect_uint_equals(0, array[3], "abc string produces 3-length array with [3] == '\\0'");
        expect_bytes_equal(new Bytes.take({'a', 'b', 'c'}), bytes, "strings equal");
    }
}

} // namespace Drt
