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

namespace Drtdb {

public class ObjectQueryTest: Drt.TestCase {
    private File db_file;
    private Database db;
    private Connection conn;

    public override void set_up() {
        base.set_up();
        db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
        delete_db_file();
        db = new Database(db_file);

        try {
            db.open();
            conn = db.open_connection();
            query(TABLE_USERS_SQL).exec();
            query("INSERT INTO %s(id, name, age, height, blob, alive, extra) VALUES(?, ?, ?, ?, ?, ?, ?)".printf(TABLE_USERS_NAME))
            .bind(1, 1).bind(2, "George").bind(3, 30).bind(4, 1.72)
            .bind_blob(5, new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7})
            .bind(6, true).bind_null(7).exec();
            query("INSERT INTO %s(id, name, age, height, blob, alive, extra) VALUES(?, ?, ?, ?, ?, ?, ?)".printf(TABLE_USERS_NAME))
            .bind(1, 2).bind(2, "Jean").bind(3, 50).bind(4, 2.72)
            .bind_blob(5, new uint8[] {7, 6, 6, 4, 3, 2, 1, 0, 1, 2, 3, 4, 6, 6, 7})
            .bind(6, false).bind_null(7).exec();
        } catch (GLib.Error e) {
            error("%s", e.message);
        }
    }

    public override void tear_down() {
        base.tear_down();
        try {
            if (db.opened)
            db.close();
        } catch (GLib.Error e) {
            error("%s", e.message);
        }
        delete_db_file();
    }

    private void delete_db_file() {
        if (db_file.query_exists()) {
            try {
                db_file.delete();
            } catch (GLib.Error e) {
                warning("Cannot delete %s: %s", db_file.get_path(), e.message);
            }
        }
    }

    private Query? query(string sql) throws GLib.Error, DatabaseError {
        return conn.query(sql);
    }

    public void test_get_cursor() {
        try {
            db.orm.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }

        try {
            User[] users = {};
            var cursor = conn.get_objects<User>().get_cursor();
            uint counter = 0;
            foreach (var user in cursor) {
                users += user;
                expect_uint_equals(++counter, cursor.counter, "cursor counter");
            }

            expect_int_equals(2, users.length, "users.length");

            expect_int64_equals(1, users[0].id, "id");
            expect_str_equals("George", users[0].name, "name");
            expect_int_equals(30, users[0].age, "age");
            expect_double_equals(1.72, users[0].height, "height");
            expect_true(users[0].alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7}),
                users[0].blob, "blob");
            expect(null == users[0].extra, "extra");
            expect_int_equals(1024, users[0].not_in_db, "not_in_db");

            expect_int64_equals(2, users[1].id, "id");
            expect_str_equals("Jean", users[1].name, "name");
            expect_int_equals(50, users[1].age, "age");
            expect_double_equals(2.72, users[1].height, "height");
            expect_false(users[1].alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 6, 4, 3, 2, 1, 0, 1, 2, 3, 4, 6, 6, 7}),
                users[1].blob, "blob");
            expect(null == users[1].extra, "extra");
            expect_int_equals(1024, users[1].not_in_db, "not_in_db");
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }

        try {
            User[] users = {};
            var cursor = conn.query_objects<User>(null, "WHERE id=?i", 2).get_cursor();
            uint counter = 0;
            foreach (var user in cursor) {
                users += user;
                expect_uint_equals(++counter, cursor.counter, "cursor counter");
            }

            expect_int_equals(1, users.length, "users.length");

            expect_int64_equals(2, users[0].id, "id");
            expect_str_equals("Jean", users[0].name, "name");
            expect_int_equals(50, users[0].age, "age");
            expect_double_equals(2.72, users[0].height, "height");
            expect_false(users[0].alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 6, 4, 3, 2, 1, 0, 1, 2, 3, 4, 6, 6, 7}),
                users[0].blob, "blob");
            expect(null == users[0].extra, "extra");
            expect_int_equals(1024, users[0].not_in_db, "not_in_db");
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }
    }

    public void test_iterator() {
        try {
            db.orm.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }

        try {
            User[] users = {};
            var q = conn.get_objects<User>(null);
            foreach (var user in q.get_cursor())
            users += user;

            expect_int_equals(2, users.length, "users.length");

            expect_int64_equals(1, users[0].id, "id");
            expect_str_equals("George", users[0].name, "name");
            expect_int_equals(30, users[0].age, "age");
            expect_double_equals(1.72, users[0].height, "height");
            expect_true(users[0].alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7}),
                users[0].blob, "blob");
            expect(null == users[0].extra, "extra");
            expect_int_equals(1024, users[0].not_in_db, "not_in_db");

            expect_int64_equals(2, users[1].id, "id");
            expect_str_equals("Jean", users[1].name, "name");
            expect_int_equals(50, users[1].age, "age");
            expect_double_equals(2.72, users[1].height, "height");
            expect_false(users[1].alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 6, 4, 3, 2, 1, 0, 1, 2, 3, 4, 6, 6, 7}),
                users[1].blob, "blob");
            expect(null == users[1].extra, "extra");
            expect_int_equals(1024, users[1].not_in_db, "not_in_db");
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }

    }

    public void test_get_one() {
        try {
            db.orm.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }

        try {
            conn.get_objects<User>(null).get_one();
            expectation_failed("Expected error");
        } catch (GLib.Error e) {
            expect_str_match("*More than one object have been returned for object query*", e.message, "more than one");
        }

        try {
            conn.query_objects<User>(null, "where id > 5").get_one();
            expectation_failed("Expected error");
        } catch (GLib.Error e) {
            expect_str_match("*No data has been returned for object query*", e.message, "less than one");
        }

        try {

            var user = conn.query_objects<User>(null, "WHERE id=?i", 2).get_one();
            expect_int64_equals(2, user.id, "id");
            expect_str_equals("Jean", user.name, "name");
            expect_int_equals(50, user.age, "age");
            expect_double_equals(2.72, user.height, "height");
            expect_false(user.alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 6, 4, 3, 2, 1, 0, 1, 2, 3, 4, 6, 6, 7}),
                user.blob, "blob");
            expect(null == user.extra, "extra");
            expect_int_equals(1024, user.not_in_db, "not_in_db");
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", e.message);
        }
    }
}

} // namespace Drtdb
