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

public class DatabaseTest: Drt.TestCase
{
	
	private File db_file;
	private Database db;
	
	public override void set_up()
	{
		base.set_up();
		db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
		delete_db_file();
		db = new Database(db_file);
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
	
	public void test_open_close() throws Drt.TestError
	{
		assert(!db_file.query_exists(), "");
		try
		{
			db.open();
			db.close();
		}
		catch (GLib.Error e)
		{
			assert_not_reached("%s", e.message);
		}
		assert(db_file.query_exists(), "");
	}
	
	public void test_exec() throws Drt.TestError
	{
		try
		{
			db.open();
		}
		catch (GLib.Error e)
		{
			assert_not_reached("%s", e.message);
		}
		try
		{
			db.exec("SELECT name FROM users WHERE id = 1");
		}
		catch (GLib.Error e)
		{
			expect_str_match("*no such table: users*", e.message, "");
		}
		try
		{
			db.exec("CREATE TABLE users(id INTEGER PRIMARY KEY ASC, name TEXT)");
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
		try
		{
			db.exec("SELECT name FROM users WHERE id = 1");
		}
		catch (GLib.Error e)
		{
			expectation_failed("%s", e.message);
		}
	}
}

} // namespace Drtdb
