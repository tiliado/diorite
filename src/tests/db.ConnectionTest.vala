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

public class ConnectionTest: Diorite.TestCase
{
	private File db_file;
	private Database db;
	private Connection conn;
	
	public override void set_up()
	{
		base.set_up();
		db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
		delete_db_file();
		db = new Database(db_file);
		
		try
		{
			db.open();
			conn = new Connection(db);
			conn.query(TABLE_USERS_SQL).exec();
			conn.query("INSERT INTO %s(id, name, age, height, blob, alive, extra) VALUES(?, ?, ?, ?, ?, ?, ?)".printf(TABLE_USERS_NAME))
				.bind(1, 1).bind(2, "George").bind(3, 30).bind(4, 1.72)
				.bind_blob(5, new uint8[]{7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7})
				.bind(6, true).bind_null(7).exec();
			conn.query("INSERT INTO %s(id, name, age, height, blob, alive, extra) VALUES(?, ?, ?, ?, ?, ?, ?)".printf(TABLE_USERS_NAME))
				.bind(1, 2).bind(2, "Jean").bind(3, 50).bind(4, 2.72)
				.bind_blob(5, new uint8[]{7, 6, 6, 4, 3, 2, 1, 0, 1, 2, 3, 4, 6, 6, 7})
				.bind(6, false).bind_null(7).exec();
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
			error("%s", e.message);
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
	
	public void test_query()
	{
		try
		{
			conn.query("SELECT name FROM XX%sXX WHERE id = 1".printf(TABLE_USERS_NAME )); // No exec();
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such table: XX%sXX*".printf(TABLE_USERS_NAME), e.message, "");
		}
		
		try
		{
			conn.query("SELECT name FROM %s WHERE id = 1".printf(TABLE_USERS_NAME)); // No exec();
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
	
	public void test_query_objects()
	{
		try
		{
			conn.query_objects<User>(null);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*ObjectSpec for DioritedbUser has not been found.*", e.message, "missing ospec");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "not-in-db"));
			conn.query_objects<User>(null);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such column: DioritedbUser.not-in-db.*", e.message, "invalid column");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "id"));
			conn.query_objects<User>(null);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such column: DioritedbUser.not-in-db.*", e.message, "invalid column");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
			conn.query_objects<User>(null);
		}
		catch (GLib.Error e)
		{
			expectation_failed("Unexpected error: %s", e.message);
		}
	}
	
	public void test_get_object()
	{
		try
		{
			conn.get_object<SimpleUser>(1);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*type DioritedbSimpleUser is not supported*", e.message, "wrong type");
		}
		
		try
		{
			conn.get_object<User>(1);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*ObjectSpec for DioritedbUser has not been found.*", e.message, "missing ospec");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "not-in-db"));
			conn.get_object<User>(1);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such column: DioritedbUser.not-in-db.*", e.message, "invalid primary column");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "id"));
			conn.get_object<User>(1);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such column: DioritedbUser.not-in-db.*", e.message, "invalid column");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "not-in-db", User.all_props()));
			conn.get_object<User>(1);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such column: DioritedbUser.not-in-db.*", e.message, "invalid primary column");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
			conn.get_object<User>(0);
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*No data has been returned for object query*", e.message, "id == 0");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
			conn.get_object<User>("hello");
			expectation_failed("Expected error");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*No data has been returned for object query*", e.message, "id == hello");
		}
		
		try
		{
			db.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
			var user = conn.get_object<User>(2);
			expect_int64_equals(2, user.id, "id");
			expect_str_equals("Jean", user.name, "name");
			expect_int_equals(50, user.age, "age");
			expect_double_equals(2.72, user.height, "height");
			expect_false(user.alive, "alive");
			expect_bytes_equal(
				new GLib.Bytes.take(new uint8[]{7, 6, 6, 4, 3, 2 , 1, 0, 1, 2, 3, 4, 6, 6, 7}),
				user.blob, "blob");
			expect(null == user.extra, "extra");
			expect_int_equals(1024, user.not_in_db, "not_in_db");

		}
		catch (GLib.Error e)
		{
			expectation_failed("Unexpected error: %s", e.message);
		}
	}
}

} // namespace Dioritedb
