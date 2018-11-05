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

public class JsonValueTest: Drt.TestCase
{
    public void test_null()
    {
        var val = new JsonValue.@null();
        string? str_val = null;
        bool bool_val = true;
        int int_val = -1;
        double double_val = -1.0;
        expect_enum(JsonValueType.NULL, val.value_type, "");
        expect_str_equals(null, val.get_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_str_equals(null, val.dup_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_false(val.try_string(out str_val), "");
        expect_null(str_val, "");
        expect_false(val.get_bool(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_BOOLEAN' failed", "");
        expect_false(val.try_bool(out bool_val), "");
        expect_false(bool_val, "");
        expect_int_equals(0, val.get_int(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_INTEGER' failed", "");
        expect_false(val.try_int(out int_val), "");
        expect_int_equals(0, int_val, "");
        expect_double_equals(0.0, val.get_double(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_DOUBLE' failed", "");
        expect_false(val.try_double(out double_val), "");
        expect_double_equals(0.0, double_val, "");
        expect_str_equals("null", val.to_string(), "to string");
    }

    public void test_bool()
    {
        var val = new JsonValue.@bool(true);
        string? str_val = null;
        bool bool_val = false;
        int int_val = -1;
        double double_val = -1.0;
        expect_enum(JsonValueType.BOOLEAN, val.value_type, "");
        expect_str_equals(null, val.get_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_str_equals(null, val.dup_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_false(val.try_string(out str_val), "");
        expect_null(str_val, "");
        expect_true(val.get_bool(), "");
        expect_true(val.try_bool(out bool_val), "");
        expect_true(bool_val, "");
        expect_int_equals(0, val.get_int(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_INTEGER' failed", "");
        expect_false(val.try_int(out int_val), "");
        expect_int_equals(1, int_val, "");
        expect_double_equals(0.0, val.get_double(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_DOUBLE' failed", "");
        expect_false(val.try_double(out double_val), "");
        expect_double_equals(0.0, double_val, "");
        expect_str_equals("true", new JsonValue.@bool(true).to_string(), "to string");
        expect_str_equals("false", new JsonValue.@bool(false).to_string(), "to string");
    }

    public void test_int()
    {
        var val = new JsonValue.@int(-1234);
        string? str_val = null;
        bool bool_val = true;
        int int_val = -1;
        double double_val = -1.0;
        expect_enum(JsonValueType.INTEGER, val.value_type, "");
        expect_str_equals(null, val.get_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_str_equals(null, val.dup_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_false(val.try_string(out str_val), "");
        expect_null(str_val, "");
        expect_false(val.get_bool(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_BOOLEAN' failed", "");
        expect_false(val.try_bool(out bool_val), "");
        expect_true(bool_val, "");
        expect_int_equals(-1234, val.get_int(), "");
        expect_true(val.try_int(out int_val), "");
        expect_int_equals(-1234, int_val, "");
        expect_double_equals(0.0, val.get_double(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_DOUBLE' failed", "");
        expect_false(val.try_double(out double_val), "");
        expect_double_equals(0.0, double_val, "");
        expect_str_equals("-1234", new JsonValue.@int(-1234).to_string(), "to string");
        expect_str_equals("4567", new JsonValue.@int(4567).to_string(), "to string");
    }

    public void test_double()
    {
        var val = new JsonValue.@double(-12.34);
        string? str_val = null;
        bool bool_val = true;
        int int_val = -1;
        double double_val = -1.0;
        expect_enum(JsonValueType.DOUBLE, val.value_type, "");
        expect_str_equals(null, val.get_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_str_equals(null, val.dup_string(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_STRING' failed", "");
        expect_false(val.try_string(out str_val), "");
        expect_null(str_val, "");
        expect_false(val.get_bool(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_BOOLEAN' failed", "");
        expect_false(val.try_bool(out bool_val), "");
        expect_false(bool_val, "");
        expect_int_equals(0, val.get_int(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_INTEGER' failed", "");
        expect_false(val.try_int(out int_val), "");
        expect_int_equals(0, int_val, "");
        expect_double_equals(-12.34, val.get_double(), "");
        expect_true(val.try_double(out double_val), "");
        expect_double_equals(-12.34, double_val, "");
        expect_str_equals("-12.34", new JsonValue.@double(-12.34).to_string(), "to string");
        expect_str_equals("45.68", new JsonValue.@double(45.68).to_string(), "to string");
    }

    public void test_string()
    {
        var str = "Test ";
        var val = new JsonValue.@string(str);
        string? str_val = null;
        bool bool_val = true;
        int int_val = -1;
        double double_val = -1.0;
        expect_enum(JsonValueType.STRING, val.value_type, "");
        expect_str_equals(str, val.get_string(), "");
        expect_str_equals(str, val.dup_string(), "");
        expect_true(val.try_string(out str_val), "");
        expect_str_equals(str, str_val, "");
        expect_false(val.get_bool(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_BOOLEAN' failed", "");
        expect_false(val.try_bool(out bool_val), "");
        expect_false(bool_val, "");
        expect_int_equals(0, val.get_int(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_INTEGER' failed", "");
        expect_false(val.try_int(out int_val), "");
        expect_int_equals(0, int_val, "");
        expect_double_equals(0.0, val.get_double(), "");
        expect_critical_message("DioriteGlib", "*assertion '* == DRT_JSON_VALUE_TYPE_DOUBLE' failed", "");
        expect_false(val.try_double(out double_val), "");
        expect_double_equals(0.0, double_val, "");
        expect_str_equals("\"\"", new JsonValue.@string("").to_string(), "to string");
        expect_str_equals("\"\\n\\r\\t \\\"\"", new JsonValue.@string("\n\r\t \"").to_string(), "to string");
        expect_str_equals("\"string\"", new JsonValue.@string("string").to_string(), "to string");
    }

    public void test_escape_string()
    {
        expect_str_equals("\\n\\r\\t\\b\\f \\\"", JsonValue.escape_string("\n\r\t\b\f \""), "");
        var buf = new uint8[32]; // the control characters U+0000 to U+001F
        for (uint8 c = 0; c < 31; c++)
        buf[c] = c + 1;
        buf[31] = 0;
        unowned string str = (string) buf;
        expect_str_equals("       \\b\\t\\n \\f\\r                  ", JsonValue.escape_string(str), "");
        expect_str_equals("", JsonValue.escape_string(null), "");
    }
}

} // namespace Drt
