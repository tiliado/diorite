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

namespace Drt {

public class SystemTest: Drt.TestCase {
    public async void test_make_dirs() {
        unowned File tmp = get_tmp_dir();
        expect_true(tmp.query_file_type(0) == FileType.DIRECTORY, "tmp dir exists");
        try {
            yield System.make_dirs_async(tmp);
        } catch (GLib.Error e) {
            expectation_failed("Unexpected error: %s", error_to_string(e));
        }
        expect_true(tmp.query_file_type(0) == FileType.DIRECTORY, "tmp dir still exists");

        // Subdirectory
        File dir = tmp.get_child("dir1");
        expect_false(dir.query_file_type(0) == FileType.DIRECTORY, "subdir doesn't exist");
        try {
            yield System.make_dirs_async(dir);
        } catch (GLib.Error e) {
            unexpected_error(e, "failed to create dir");
        }
        expect_true(dir.query_file_type(0) == FileType.DIRECTORY, "subdir exists");

        // Sub-subdirectory
        dir = tmp.get_child("dir2/dir3/dir4/dir5");
        expect_false(dir.query_file_type(0) == FileType.DIRECTORY, "subdir doesn't exist");
        try {
            yield System.make_dirs_async(dir);
        } catch (GLib.Error e) {
            unexpected_error(e, "failed to create dir");
        }
        expect_true(dir.query_file_type(0) == FileType.DIRECTORY, "subdir exists");

        // Cannot overwrite file
        File file = tmp.get_child("file1");
        try {
            FileUtils.set_contents(file.get_path(), "abc");
        } catch (FileError e) {
            critical_error(e);
        }
        expect_true(file.query_file_type(0) == FileType.REGULAR, "file is file");
        try {
            yield System.make_dirs_async(file);
            expectation_failed("Should not overwrite a file");
        } catch (GLib.Error e) {
            expect_error_match(e, "*Error creating directory */file1: File exists*", "Cannot overwrite file.");
        }
        expect_true(file.query_file_type(0) == FileType.REGULAR, "file is still file");

        dir = tmp.get_child("file1/dir3/dir4/dir5");
        try {
            yield System.make_dirs_async(dir);
            expectation_failed("Should not overwrite a file");
        } catch (GLib.Error e) {
            expect_error_match(e, "*Error creating directory */file1/dir3/dir4/dir5: Not a directory*", "Cannot overwrite file.");
        }
        expect_true(file.query_file_type(0) == FileType.REGULAR, "file is still file");
    }

    public async void test_write_to_file_async() {
        unowned File tmp = get_tmp_dir();
        expect_true(tmp.query_file_type(0) == FileType.DIRECTORY, "tmp dir exists");
        unowned string contents = "abc";

        try {
            yield System.write_to_file_async(tmp, contents);
            expectation_failed("Should not overwrite a directory");
        } catch (GLib.Error e) {
            expect_error_match(e, "*Error opening file *: Is a directory*", "Cannot overwrite directory.");
        }

        foreach (unowned string path in new (unowned string)[] {"file1", "dir1/file2", "dir2/dir3/file3"}) {
            File file = tmp.get_child(path);
            try {
                yield System.write_to_file_async(file, contents);
                expect_true(file.query_file_type(0) == FileType.REGULAR, "file was created");
                string actual_contents;
                FileUtils.get_contents(file.get_path(), out actual_contents);
                expect_str_equal(contents, actual_contents, "contents equal");
            } catch (GLib.Error e) {
                unexpected_error(e, "Failed to create file.");
            }
        }

        File file = tmp.get_child("file1/file4");
        try {
            yield System.write_to_file_async(file, contents);
            expectation_failed("Should not overwrite a parent file");
        } catch (GLib.Error e) {
            expect_error_match(e, "*Error creating directory *file1: File exists*", "Cannot overwrite directory.");
        }
    }
}

} // namespace Drt
