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

public class OrmManagerTest: Drt.TestCase {
    private File db_file;
    private Database db;
    private OrmManager orm;
//~     private string[] column_names = {"id", "name", "age", "height", "blob", "alive", "extra"};

    public override void set_up() {
        base.set_up();
        db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
        delete_db_file();
        db = new Database(db_file);
        orm = db.orm;
        try {
            query(TABLE_USERS_SQL).exec();
            query("INSERT INTO %s(id, name, age, height, blob, alive, extra) VALUES(?, ?, ?, ?, ?, ?, ?)".printf(TABLE_USERS_NAME))
            .bind(1, 1).bind(2, "George").bind(3, 30).bind(4, 1.72)
            .bind_blob(5, new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7})
            .bind(6, true).bind_null(7).exec();
        } catch (GLib.Error e) {
            warning("%s", e.message);
        }
    }

    public override void tear_down() {
        base.tear_down();
        try {
            if (db.opened) {
                db.close();
            }
        } catch (GLib.Error e) {
            warning("%s", e.message);
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

        if (!db.opened) {
            db.open();
        }

        return db.open_connection().query(sql);
    }

    private Result select_data()  throws GLib.Error, DatabaseError {
        return query("SELECT id, name, age, height, blob, alive, extra FROM %s WHERE id = ?".printf(TABLE_USERS_NAME))
        .bind(1, 1).exec();
    }

    public void test_create_object() {
        try {
            Result result = select_data();
            /* All fields */
            try {
                orm.create_object<User>(result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*ObjectSpec for DrtdbUser has not been found*", e.message, "no ospec");
            }


            try {
                orm.add_object_spec(new ObjectSpec(typeof(User), "id"));
                orm.create_object<User>(result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*no column named 'not-in-db'*", e.message, "invalid column");
            }
            try {
                orm.add_object_spec(new ObjectSpec(typeof(User), "not-in-db"));
                orm.create_object<User>(result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*no column named 'not-in-db'*", e.message, "invalid column");
            }

            try {
                orm.add_object_spec(new ObjectSpec(typeof(User), "id", User.all_props()));
                User user = orm.create_object<User>(result);
                expect_int64_equal(1, user.id, "id");
                expect_str_equal("George", user.name, "name");
                expect_int_equal(30, user.age, "age");
                expect_double_equal(1.72, user.height, "height");
                expect_true(user.alive, "alive");
                expect_bytes_equal(
                    new GLib.Bytes.take(new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7}),
                    user.blob, "blob");
                expect(null == user.extra, "extra");
                expect_int_equal(1024, user.not_in_db, "not_in_db");
            } catch (GLib.Error e) {
                unexpected_error(e, "ORM");
            }
            try {
                orm.add_object_spec(new ObjectSpec(typeof(User), "not-in-db", User.all_props()));
                User user = orm.create_object<User>(result);
                expect_int64_equal(1, user.id, "id");
                expect_str_equal("George", user.name, "name");
                expect_int_equal(30, user.age, "age");
                expect_double_equal(1.72, user.height, "height");
                expect_true(user.alive, "alive");
                expect_bytes_equal(
                    new GLib.Bytes.take(new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7}),
                    user.blob, "blob");
                expect(null == user.extra, "extra");
                expect_int_equal(1024, user.not_in_db, "not_in_db");
            } catch (GLib.Error e) {
                unexpected_error(e, "ORM");
            }

            /* Not GObject */
            try {
                orm.create_object<SimpleUser>(result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*Data type DrtdbSimpleUser is not supported*", e.message, "invalid type");
            }
        } catch (GLib.Error e) {
            unexpected_error(e, "ORM");
        }
    }

    public void test_fill_object() {
        try {
            Result result = select_data();
            User user;

            try {
                user = new User(2, "Lololo", 45, 2.25, false);
                orm.fill_object(user, result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*ObjectSpec for DrtdbUser has not been found*", e.message, "mismatch, all fields");
            }

            orm.add_object_spec(new ObjectSpec(typeof(User), "not-in-db", User.all_props()));

            try {
                user = new User(2, "Lololo", 45, 2.25, false);
                orm.fill_object(user, result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_equal("Read-only value of property 'id' doesn't match database data.", e.message, "mismatch");
            }

            /* Matches */
            user = new User(1, "Lololo", 45, 2.25, false);
            orm.fill_object(user, result);
            expect_int64_equal(1, user.id, "id");
            expect_str_equal("George", user.name, "name");
            expect_int_equal(30, user.age, "age");
            expect_double_equal(1.72, user.height, "height");
            expect_true(user.alive, "alive");
            expect_bytes_equal(
                new GLib.Bytes.take(new uint8[] {7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7}),
                user.blob, "blob");
            expect(null == user.extra, "extra");
            expect_int_equal(1024, user.not_in_db, "not_in_db");

            try {
                orm.add_object_spec(new ObjectSpec(typeof(User), "id"));
                user = new User(1, "Lololo", 45, 2.25, false);
                orm.fill_object(user, result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*no column named 'not-in-db'*", e.message, "invalid column");
            }

            try {
                orm.add_object_spec(new ObjectSpec(typeof(User), "not-in-db"));
                user = new User(1, "Lololo", 45, 2.25, false);
                orm.fill_object(user, result);
                expectation_failed("Expected error");
            } catch (GLib.Error e) {
                expect_str_match("*no column named 'not-in-db'*", e.message, "invalid column");
            }
        } catch (GLib.Error e) {
            unexpected_error(e, "ORM");
        }
    }
}

} // namespace Drtdb
