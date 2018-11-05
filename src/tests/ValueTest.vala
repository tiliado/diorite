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

public class ValueTest: Drt.TestCase
{
    public void test_to_string()
    {
        expect_str_equals("string", Value.to_string("string"), "string");
        expect_str_equals("1024", Value.to_string((int)1024), "int");
        expect_str_equals("1024", Value.to_string((uint)1024), "uint");
        expect_str_equals("1024", Value.to_string((int64)1024), "int64");
        expect_str_equals("1024", Value.to_string((uint64)1024), "uint64");
        expect_str_equals("true", Value.to_string(true), "true");
        expect_str_equals("false", Value.to_string(false), "false");
        expect_str_equals("1024.25", Value.to_string((double)1024.25), "double");
        expect_str_equals("1024.25", Value.to_string((float)1024.25), "float");

        expect_str_equals("%p".printf(this), Value.to_string(this), "object");
        var dummy = new DummyObject();
        expect_str_equals("%p".printf(dummy), Value.to_string(dummy), "simple object");

        var bytes = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        expect_str_equals("01020304050607", Value.to_string(bytes), "bytes");
        var byte_array = new ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        expect_str_equals("01020304050607", Value.to_string(byte_array), "byte array");
    }

    public void test_describe()
    {
        expect_str_equals("<gchararray:string>", Value.describe("string"), "string");
        expect_str_equals("<gint:1024>", Value.describe((int)1024), "int");
        expect_str_equals("<guint:1024>", Value.describe((uint)1024), "uint");
        expect_str_equals("<gint64:1024>", Value.describe((int64)1024), "int64");
        expect_str_equals("<guint64:1024>", Value.describe((uint64)1024), "uint64");
        expect_str_equals("<gboolean:true>", Value.describe(true), "true");
        expect_str_equals("<gboolean:false>", Value.describe(false), "false");
        expect_str_equals("<gdouble:1024.25>", Value.describe((double)1024.25), "double");
        expect_str_equals("<gfloat:1024.25>", Value.describe((float)1024.25), "float");

        expect_str_equals("<DrtValueTest:%p>".printf(this), Value.describe(this), "object");
        var dummy = new DummyObject();
        expect_str_equals("<DrtValueTestDummyObject:%p>".printf(dummy), Value.describe(dummy), "simple object");

        var bytes = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        expect_str_equals("<GBytes:01020304050607>", Value.describe(bytes), "bytes");
        var byte_array = new ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        expect_str_equals("<GByteArray:01020304050607>", Value.describe(byte_array), "byte array");
    }

    public void test_equal()
    {
        expect_true(Value.equal(null, null), "both null");
        expect_false(Value.equal("string", null), "(\"string\", null)");
        expect_false(Value.equal(null, "string"), "(null, \"string\")");
        expect_true(Value.equal("string", "string"), "(\"string\", \"string\")");
        expect_false(Value.equal("string", "another string"), "(\"string\", \"another string\")");

        expect_false(Value.equal((int)1024, "string"), "(1024, \"string\")");
        expect_true(Value.equal((int)1024, (int)1024), "int == int");
        expect_false(Value.equal((int)1024, (int)1000), "int != int");
        expect_true(Value.equal((uint)1024, (uint)1024), "uint == uint");
        expect_false(Value.equal((uint)1024, (uint)1000), "uint != uint");
        expect_true(Value.equal((int64)1024, (int64)1024), "int64 == int64");
        expect_false(Value.equal((int64)1024, (int64)1000), "int64 != int64");
        expect_true(Value.equal((uint64)1024, (uint64)1024), "uint64 == uint64");
        expect_false(Value.equal((uint64)1024, (uint64)1000), "uint64 != uint64");
        expect_true(Value.equal(true, true), "bool == bool");
        expect_false(Value.equal(true, false), "bool != bool");
        expect_true(Value.equal((double)1024.25, (double)1024.25), "double == double");
        expect_false(Value.equal((double)1024.25, (double)1024.26), "double != double");
        expect_true(Value.equal((float)1024.25, (float)1024.25), "float == float");
        expect_false(Value.equal((float)1024.25, (float)1024.26), "float != float");

        expect_true(Value.equal(this, this), "object == object");
        expect_false(Value.equal(this, new DummyObject()), "object != object");

        var bytes = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        var bytes2 = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        var bytes3 = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 8});
        expect_true(Value.equal(bytes, bytes), "bytes == bytes");
        expect_true(Value.equal(bytes, bytes2), "bytes == bytes");
        expect_false(Value.equal(bytes, bytes3), "bytes != bytes");

        var byte_array = new ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        var byte_array2 = new ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        var byte_array3 = new ByteArray.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 8});
        expect_true(Value.equal(byte_array, byte_array), "byte_array == byte_array");
        expect_true(Value.equal(byte_array, byte_array2), "byte_array == byte_array");
        expect_false(Value.equal(byte_array, byte_array3), "byte_array != byte_array");
    }

    public void test_equal_verbose()
    {
        string description;
        expect_true(Value.equal_verbose(null, null, out description), "both null");
        expect_str_equals("equal <null>", description, "both null");
        expect_false(Value.equal_verbose("string", null, out description), "(\"string\", null)");
        expect_str_equals("<gchararray:string> != <null>", description, "(\"string\", null)");
        expect_false(Value.equal_verbose(null, "string", out description), "(null, \"string\")");
        expect_str_equals("<null> != <gchararray:string>", description, "(null, \"string\")");
        expect_true(Value.equal_verbose("string", "string", out description), "(\"string\", \"string\")");
        expect_str_equals("equal <gchararray:string>", description, "(\"string\", \"string\")");
        expect_false(Value.equal_verbose("string", "another string", out description), "(\"string\", \"another string\")");
        expect_str_equals("<gchararray:string> != <gchararray:another string>", description, "(\"string\", \"another string\")");

        expect_false(Value.equal_verbose((int)1024, "string", out description), "(1024, \"string\")");
        expect_str_equals("<gint:1024> != <gchararray:string>", description, "(1024, \"string\")");
        expect_true(Value.equal_verbose((int)1024, (int)1024, out description), "int == int");
        expect_str_equals("equal <gint:1024>", description, "int == int");
        expect_false(Value.equal_verbose((int)1024, (int)1000, out description), "int != int");
        expect_str_equals("<gint:1024> != <gint:1000>", description, "int != int");
        expect_true(Value.equal_verbose((uint)1024, (uint)1024, out description), "uint == uint");
        expect_str_equals("equal <guint:1024>", description, "uint == uint");
        expect_false(Value.equal_verbose((uint)1024, (uint)1000, out description), "uint != uint");
        expect_str_equals("<guint:1024> != <guint:1000>", description, "uint != uint");
        expect_true(Value.equal_verbose((int64)1024, (int64)1024, out description), "int64 == int64");
        expect_str_equals("equal <gint64:1024>", description, "int64 == int64");
        expect_false(Value.equal_verbose((int64)1024, (int64)1000, out description), "int64 != int64");
        expect_str_equals("<gint64:1024> != <gint64:1000>", description, "int64 != int64");
        expect_true(Value.equal_verbose((uint64)1024, (uint64)1024, out description), "uint64 == uint64");
        expect_str_equals("equal <guint64:1024>", description, "uint64 == uint64");
        expect_false(Value.equal_verbose((uint64)1024, (uint64)1000, out description), "uint64 != uint64");
        expect_str_equals("<guint64:1024> != <guint64:1000>", description, "uint64 != uint64");
        expect_true(Value.equal_verbose(true, true, out description), "bool == bool");
        expect_str_equals("equal <gboolean:true>", description, "bool == bool");
        expect_false(Value.equal_verbose(true, false, out description), "bool != bool");
        expect_str_equals("<gboolean:true> != <gboolean:false>", description, "bool != bool");
        expect_true(Value.equal_verbose((double)1024.25, (double)1024.25, out description), "double == double");
        expect_str_equals("equal <gdouble:1024.25>", description, "double == double");
        expect_false(Value.equal_verbose((double)1024.25, (double)1024.26, out description), "double != double");
        expect_str_equals("<gdouble:1024.25> != <gdouble:1024.26>", description, "double != double");
        expect_true(Value.equal_verbose((float)1024.25, (float)1024.25, out description), "float == float");
        expect_str_equals("equal <gfloat:1024.25>", description, "float == float");
        expect_false(Value.equal_verbose((float)1024.25, (float)1024.26, out description), "float != float");
        expect_str_equals("<gfloat:1024.25> != <gfloat:1024.26>", description, "float != float");

        expect_true(Value.equal_verbose(this, this, out description), "object == object");
        expect_str_equals("equal <DrtValueTest:%p>".printf(this), description, "object == object");
        var dummy = new DummyObject();
        expect_false(Value.equal_verbose(this, dummy, out description), "object != simple object");
        expect_str_equals("<DrtValueTest:%p> != <DrtValueTestDummyObject:%p>".printf(this, dummy), description, "object != simple object");

        var bytes = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        var bytes2 = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7});
        var bytes3 = new Bytes.take(new uint8[]{1, 2, 3, 4, 5, 6, 7, 8});
        expect_true(Value.equal_verbose(bytes, bytes, out description), "bytes == bytes");
        expect_str_equals("equal <GBytes:01020304050607>", description, "bytes == bytes");
        expect_true(Value.equal_verbose(bytes, bytes2, out description), "bytes == bytes");
        expect_str_equals("equal <GBytes:01020304050607>", description, "bytes == bytes");
        expect_false(Value.equal_verbose(bytes, bytes3, out description), "bytes != bytes");
        expect_str_equals("<GBytes:01020304050607> != <GBytes:0102030405060708>", description, "bytes != bytes");
    }

    private class DummyObject
    {
    }
}

} // namespace Drt
