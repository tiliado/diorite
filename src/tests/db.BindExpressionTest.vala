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

namespace Drtdb
{

public class BindExpressionTest: Drt.TestCase
{


	public override void set_up()
	{
		base.set_up();
	}

	public override void tear_down()
	{
		base.tear_down();

	}

	public void test_parse_ok()
	{
		var binder = new BindExpression();
		var bytes = new Bytes.take({1, 2, 3, 4});
		var byte_array = new ByteArray.take({1, 2, 3, 4});
		var gvalue = Value(typeof(int));
		gvalue.set_int(1234);
		expect_no_error(() => binder.parse(
				"WHERE name = ?s AND age = ?i AND weight = ?f AND money = ?l AND married = ?b"
				+ " AND image = ?B AND key = ?A AND val = ?v",
				"John", 18, (double) 65.5, (int64) 123456, true, bytes, byte_array, gvalue),
			"binder.parse");
		var sql = binder.get_sql();
		expect_str_equals(
			"WHERE name = ? AND age = ? AND weight = ? AND money = ? AND married = ?"
			+ " AND image = ? AND key = ? AND val = ?",
			sql, "sql");
		unowned Value? val;
		unowned SList<Value?> values = binder.get_values();
		expect_uint_equals(8, values.length(), "n values");

		val = values.data; values = values.next;
		expect_type_equals(typeof(string), val.type(), "str");
		expect_str_equals("John", val.get_string(), "str");

		val = values.data; values = values.next;
		expect_type_equals(typeof(int), val.type(), "int");
		expect_int_equals(18, val.get_int(), "int");

		val = values.data; values = values.next;
		expect_type_equals(typeof(double), val.type(), "double");
		expect_double_equals(65.5, val.get_double(), "double");

		val = values.data; values = values.next;
		expect_type_equals(typeof(int64), val.type(), "int64");
		expect_int64_equals(123456, val.get_int64(), "int64");

		val = values.data; values = values.next;
		expect_type_equals(typeof(bool), val.type(), "bool");
		expect_true(val.get_boolean(), "bool");

		val = values.data; values = values.next;
		expect_type_equals(typeof(Bytes), val.type(), "Bytes");
		expect_int_equals(0, bytes.compare((Bytes) val.get_boxed()), "Bytes");

		val = values.data; values = values.next;
		expect_type_equals(typeof(ByteArray), val.type(), "ByteArray");
		expect_int_equals(0, bytes.compare(ByteArray.free_to_bytes((ByteArray) val.get_boxed())), "ByteArray");

		val = values.data; values = values.next;
		expect_type_equals(typeof(int), val.type(), "gvalue");
		expect_int_equals(1234, val.get_int(), "gvalue");
	}

	public void test_reset_ok()
	{
		var binder = new BindExpression();
		expect_no_error(() => binder.parse("WHERE name = ?s", "John"), "binder.parse");
		var sql = binder.get_sql();
		expect_str_equals("WHERE name = ?",	sql, "sql");
		unowned SList<Value?> values = binder.get_values();
		expect_uint_equals(1, values.length(), "n values");

		binder.reset();
		sql = binder.get_sql();
		expect_str_equals("",	sql, "sql");
		values = binder.get_values();
		expect_uint_equals(0, values.length(), "n values");
	}

}

} // namespace Drtdb
