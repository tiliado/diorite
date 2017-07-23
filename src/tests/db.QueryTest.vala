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

public class QueryTest: Drt.TestCase
{
	private File db_file;
	private Database db;
	private Rand? rand = null;
	
	public override void set_up()
	{
		base.set_up();
		db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
		delete_db_file();
		db = new Database(db_file);
		try
		{
			query(TABLE_USERS_SQL).exec();
		}
		catch (GLib.Error e)
		{
			warning("%s", e.message);
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
			warning("%s", e.message);
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
		
		return db.open_connection().query(sql);
	}
	
	public void test_exec_no_bind()
	{
		try
		{
			query("SELECT name FROM %s WHERE id = 1".printf(TABLE_USERS_NAME)).exec();
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_int()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				try
				{
					q.bind(index, 1);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_int(index, 1);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			foreach (var value in new int[]{0, 1, -1, int.MAX, int.MIN, 1980, -1989})
			{
				
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %d; %s", value, e.message);
				}
				try
				{
					q.bind_int(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %d; %s", value, e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_int64()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				int64 val = 2 * ((int64) int32.MAX);
				try
				{
					q.bind(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_int64(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			foreach (var value in new int64[]{0, 1, -1, int64.MAX, int64.MIN, 1980, -1989})
			{
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %s; %s", value.to_string(), e.message);
				}
				try
				{
					q.bind_int64(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %s; %s", value.to_string(), e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_double()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				double val = 3.14;
				try
				{
					q.bind(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_double(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			foreach (var value in new double[]{0.0, 1.4, -1.6, 6.023e23, -6.023e23, 1980.0, -1989.0})
			{
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %s; %s", value.to_string(), e.message);
				}
				try
				{
					q.bind_double(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %s; %s", value.to_string(), e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_string()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				string val = "Hello!";
				try
				{
					q.bind(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_string(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			foreach (var value in new string?[]{null, "Hello!", "How are you?", TABLE_USERS_SQL})
			{
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value '%s'; %s", value, e.message);
				}
				try
				{
					q.bind_string(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value '%s'; %s", value, e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_bool()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				try
				{
					q.bind(index, true);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_bool(index, true);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			foreach (var value in new bool[]{true, false})
			{
				
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %d; %s", (int) value, e.message);
				}
				try
				{
					q.bind_bool(1, value);
				}
				catch (GLib.Error e)
				{
					expectation_failed("value %d; %s", (int) value, e.message);
				}
			}
			
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_null()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				try
				{
					q.bind(index, null);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_null(index);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			try
			{
				q.bind(1, null);
			}
			catch (GLib.Error e)
			{
				expectation_failed("value null; %s", e.message);
			}
			try
			{
				q.bind_null(1);
			}
			catch (GLib.Error e)
			{
				expectation_failed("value null; %s", e.message);
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_void()
	{
		try
		{
			var void_null = GLib.Value(typeof(void*)), void_non_null = GLib.Value(typeof(void*));
			void_null.set_pointer(null);
			void_non_null.set_pointer(this);
			
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				try
				{
					q.bind(index, void_null);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d, null", index);
				}
				try
				{
					q.bind(index, void_non_null);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*Data type gpointer is supported only with a null pointer.*", e.message, "index %d, non_null", index);
				}
			}
			
			try
			{
				q.bind(1, void_null);
			}
			catch (GLib.Error e)
			{
				expectation_failed("value null; %s", e.message);
			}
			try
			{
				q.bind(1, void_non_null);
				expectation_failed("Expected error");
			}
			catch (GLib.Error e)
			{
				expect_str_match("*Data type gpointer is supported only with a null pointer.*", e.message, "value non_null");
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	private uint8[] rand_blob(int min_size=1, int max_size=50)
	{
		if (rand == null)
			rand = new Rand();
		
		var size = rand.int_range(min_size, max_size);
		uint8[] blob = new uint8[size];		
		for (var j = 0; j < size; j++)
			blob[j] = (uint8) rand.int_range(uint8.MIN, uint8.MAX);
		return blob;
		
	}
	
	public void test_bind_blob()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				uint8[] val = "Hello!".data;
				try
				{
					q.bind_blob(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			for (var j = 0; j < 100; j++)
			{
				var value = rand_blob();
				try
				{
					q.bind_blob(1, value);
				}
				catch (GLib.Error e)
				{
					string hex;
					Drt.bin_to_hex(value, out hex);
					expectation_failed("value %s; %s", hex, e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_bytes()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				GLib.Bytes val = new GLib.Bytes.take("Hello!".data);
				try
				{
					q.bind(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_bytes(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			for (var j = 0; j < 100; j++)
			{
				GLib.Bytes? value = j == 0 ? null : new GLib.Bytes.take(rand_blob());
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					string hex;
					Drt.bin_to_hex(value.get_data(), out hex);
					expectation_failed("value %s; %s", hex, e.message);
				}
				try
				{
					q.bind_bytes(1, value);
				}
				catch (GLib.Error e)
				{
					string hex;
					Drt.bin_to_hex(value.get_data(), out hex);
					expectation_failed("value %s; %s", hex, e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_bind_byte_array()
	{
		try
		{
			var q = query("SELECT name FROM %s WHERE id = ? and age < ?".printf(TABLE_USERS_NAME));
			foreach (var index in new int[]{int.MIN, -2, -1, 0, 3, 4, int.MAX})
			{
				GLib.ByteArray val = new GLib.ByteArray.take("Hello!".data);
				try
				{
					q.bind(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
				try
				{
					q.bind_byte_array(index, val);
					expectation_failed("Expected error");
				}
				catch (GLib.Error e)
				{
					expect_str_match("*%d is not in range 1..2*".printf(index), e.message, "index %d", index);
				}
			}
			
			for (var j = 0; j < 100; j++)
			{
				GLib.ByteArray? value = j == 0 ? null : new GLib.ByteArray.take(rand_blob());
				try
				{
					q.bind(1, value);
				}
				catch (GLib.Error e)
				{
					string hex;
					Drt.bin_to_hex(value.data, out hex);
					expectation_failed("value %s; %s", hex, e.message);
				}
				try
				{
					q.bind_byte_array(1, value);
				}
				catch (GLib.Error e)
				{
					string hex;
					Drt.bin_to_hex(value.data, out hex);
					expectation_failed("value %s; %s", hex, e.message);
				}
			}
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
}

} // namespace Drtdb
