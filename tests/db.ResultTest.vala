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

namespace Dioritedb
{

public class ResultTest: Diorite.TestCase
{
	private File db_file;
	private Database db;
	private string[] column_names = {"id", "name", "age", "height", "blob", "alive", "extra"};
	
	public override void set_up()
	{
		base.set_up();
		db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
		delete_db_file();
		db = new Database(db_file);
		try
		{
			query(TABLE_USERS_SQL).exec();
			query("INSERT INTO users(id, name, age, height, blob, alive, extra) VALUES(?, ?, ?, ?, ?, ?, ?)")
				.bind(1, 1).bind(2, "George").bind(3, 30).bind(4, 1.72)
				.bind_blob(5, new uint8[]{7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7})
				.bind(6, true).bind_null(7).exec();
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public override void tear_down()
	{
		base.tear_down();
		try
		{
			if (db.opened)
				db.close();
		}
		catch (GLib.Error e)
		{
			assert_not_reached("%s", e.message);
		}
		delete_db_file();
	}
	
	private void delete_db_file()
	{
		if (db_file.query_exists())
		{
			try
			{
				db_file.delete();
			}
			catch (GLib.Error e)
			{
				warning("Cannot delete %s: %s", db_file.get_path(), e.message);
			}
		}
	}
	
	private Query? query(string sql) throws GLib.Error, DatabaseError
	{
		
		if (!db.opened)
			db.open();
		
		return db.get_master_connection().query(sql);
	}
	
	private Result select_data()  throws GLib.Error, DatabaseError
	{
		return query("SELECT id, name, age, height, blob, alive, extra FROM users WHERE id = ?")
			.bind(1, 1).exec();
	}
	
	public void test_get_column_name()
	{
		try
		{
			var result = select_data();
			foreach (var index in new int[]{-int.MAX, -1, 7, 8, int.MAX})
				expect_str_equals(null, result.get_column_name(index), "index %d", index);
			for (var index = 0; index < column_names.length; index++)
				expect_str_equals(column_names[index], result.get_column_name(index), "index %d", index);
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_get_column_index()
	{
		try
		{
			var result = select_data();
			foreach (var name in new string[]{"hello", "", "baby"})
				expect_int_equals(-1, result.get_column_index(name), "column '%s'", name);
			for (var index = 0; index < column_names.length; index++)
				expect_int_equals(index, result.get_column_index(column_names[index]), "column '%s'", column_names[index]);
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_is_null()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_false(result.fetch_is_null(0), "id");
			expect_false(result.fetch_is_null(1), "name");
			expect_false(result.fetch_is_null(2), "age");
			expect_false(result.fetch_is_null(3), "height");
			expect_false(result.fetch_is_null(4), "blob");
			expect_false(result.fetch_is_null(5), "alive");
			expect_true(result.fetch_is_null(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_is_null(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	// expect_str_equals("2", result.fetch_string(0), "");
	public void test_fetch_int()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_int_equals(1, result.fetch_int(0), "id");
			expect_int_equals(0, result.fetch_int(1), "name");
			expect_int_equals(30, result.fetch_int(2), "age");
			expect_int_equals(1, result.fetch_int(3), "height");
			expect_int_equals(0, result.fetch_int(4), "blob");
			expect_int_equals(1, result.fetch_int(5), "alive");
			expect_int_equals(0, result.fetch_int(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_int(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_int64()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_int64_equals((int64) 1, result.fetch_int64(0), "id");
			expect_int64_equals((int64) 0, result.fetch_int64(1), "name");
			expect_int64_equals((int64) 30, result.fetch_int64(2), "age");
			expect_int64_equals((int64) 1, result.fetch_int64(3), "height");
			expect_int64_equals((int64) 0, result.fetch_int64(4), "blob");
			expect_int64_equals((int64) 1, result.fetch_int64(5), "alive");
			expect_int64_equals((int64) 0, result.fetch_int64(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_int64(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_bool()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_true(result.fetch_bool(0), "id");
			expect_false(result.fetch_bool(1), "name");
			expect_true(result.fetch_bool(2), "age");
			expect_true(result.fetch_bool(3), "height");
			expect_false(result.fetch_bool(4), "blob");
			expect_true(result.fetch_bool(5), "alive");
			expect_false(result.fetch_bool(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_bool(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
			
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_double()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_double_equals(1.0, result.fetch_double(0), "id");
			expect_double_equals(0.0, result.fetch_double(1), "name");
			expect_double_equals(30.0, result.fetch_double(2), "age");
			expect_double_equals(1.72, result.fetch_double(3), "height");
			expect_double_equals(0.0, result.fetch_double(4), "blob");
			expect_double_equals(1.0, result.fetch_double(5), "alive");
			expect_double_equals(0.0, result.fetch_double(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_double(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
			
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_string()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_str_equals("1", result.fetch_string(0), "id");
			expect_str_equals("George", result.fetch_string(1), "name");
			expect_str_equals("30", result.fetch_string(2), "age");
			expect_str_equals("1.72", result.fetch_string(3), "height");
			expect_str_equals("\x07\x06\x05\x04\x03\x02\x01", result.fetch_string(4), "blob");
			expect_str_match(
				"*Result may be truncated. Original blob size was 15, but string size is 7.*",
				last_fatal_log_message, "blob warning");
			expect_str_equals("1", result.fetch_string(5), "alive");
			expect_str_equals(null, result.fetch_string(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_string(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_blob()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_blob_equal("1".data, result.fetch_blob(0), "id");
			expect_blob_equal("George".data, result.fetch_blob(1), "name");
			expect_blob_equal("30".data, result.fetch_blob(2), "age");
			expect_blob_equal("1.72".data, result.fetch_blob(3), "height");
			expect_blob_equal(
				new uint8[]{7, 6, 5, 4, 3, 2 , 1, 0, 1, 2, 3, 4, 5, 6, 7},
				result.fetch_blob(4), "blob");
			expect_blob_equal("1".data, result.fetch_blob(5), "alive");
			expect_blob_equal(null, result.fetch_blob(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_blob(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_bytes()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_bytes_equal(new GLib.Bytes.take("1".data), result.fetch_bytes(0), "id");
			expect_bytes_equal(new GLib.Bytes.take("George".data), result.fetch_bytes(1), "name");
			expect_bytes_equal(new GLib.Bytes.take("30".data), result.fetch_bytes(2), "age");
			expect_bytes_equal(new GLib.Bytes.take("1.72".data), result.fetch_bytes(3), "height");
			expect_bytes_equal(
				new GLib.Bytes.take(new uint8[]{7, 6, 5, 4, 3, 2 , 1, 0, 1, 2, 3, 4, 5, 6, 7}),
				result.fetch_bytes(4), "blob");
			expect_bytes_equal(new GLib.Bytes.take("1".data), result.fetch_bytes(5), "alive");
			expect_bytes_equal(null, result.fetch_bytes(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_bytes(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_fetch_byte_array()
	{
		try
		{
			var result = select_data();
			
			/* Test data type conversions */
			expect_byte_array_equal(new GLib.ByteArray.take("1".data), result.fetch_byte_array(0), "id");
			expect_byte_array_equal(new GLib.ByteArray.take("George".data), result.fetch_byte_array(1), "name");
			expect_byte_array_equal(new GLib.ByteArray.take("30".data), result.fetch_byte_array(2), "age");
			expect_byte_array_equal(new GLib.ByteArray.take("1.72".data), result.fetch_byte_array(3), "height");
			expect_byte_array_equal(
				new GLib.ByteArray.take(new uint8[]{7, 6, 5, 4, 3, 2 , 1, 0, 1, 2, 3, 4, 5, 6, 7}),
				result.fetch_byte_array(4), "blob");
			expect_byte_array_equal(new GLib.ByteArray.take("1".data), result.fetch_byte_array(5), "alive");
			expect_byte_array_equal(null, result.fetch_byte_array(6), "extra");
			
			/* Test index check */
			foreach (var i in new int[]{-int.MAX, -1, 7, 8, int.MAX})
			{
				try
				{
					result.fetch_byte_array(i);
					expectation_failed("Expected error: index %d", i);
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 0..6*".printf(i), e.message, "index %d", i);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
}

} // namespace Dioritedb
