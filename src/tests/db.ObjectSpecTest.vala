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

public class ObjectSpecTest: Drt.TestCase {
    private File db_file;
    private Database db;

    public override void set_up() {
        base.set_up();
        db_file = File.new_for_path("../build/tests/tmp/db.sqlite");
        delete_db_file();
        db = new Database(db_file);
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

    public void test_new() {
        try {
            new ObjectSpec(typeof(SimpleUser), "");
            expectation_failed("Expected error");
        } catch (GLib.Error e) {
            expect_str_match("*Data type DrtdbSimpleUser is not supported*", e.message, "invalid type");
        }

        try {
            new ObjectSpec(typeof(User), "");
            expectation_failed("Expected error");
        } catch (GLib.Error e) {
            expect_str_match("*no property named ''*", e.message, "empty primary key");
        }

        try {
            new ObjectSpec(typeof(User), "foo");
            expectation_failed("Expected error");
        } catch (GLib.Error e) {
            expect_str_match("*no property named 'foo'*", e.message, "invalid primary key");
        }

        try {
            new ObjectSpec(typeof(User), "id", {"foo", "bar", "baz"});
            expectation_failed("Expected error");
        } catch (GLib.Error e) {
            expect_str_match("*no property named 'foo'.*", e.message, "invalid property");
        }

        try {
            new ObjectSpec(typeof(User), "id", User.all_props());
        } catch (GLib.Error e) {
            unexpected_error(e, "Could not create object spec.");
        }

        try {
            new ObjectSpec(typeof(User), "id");
        } catch (GLib.Error e) {
            unexpected_error(e, "Could not create object spec.");
        }
    }
}

} // namespace Drtdb
