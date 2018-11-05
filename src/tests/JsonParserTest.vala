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

public class JsonParserTest: Drt.TestCase {
    private static inline string load_data(string name, int i) throws GLib.Error {
        return Drt.System.read_file(File.new_for_path("src/tests/data/json/%s%d.json".printf(name, i)));
    }

    public void test_pass() {
        int i;
        for (i = 1; i <= 3; i++) {
            expect_no_error(() => JsonParser.load(load_data("pass", i)), "pass%d.json", i);
        }
        for (i = 1; i <= 2; i++) {
            expect_no_error(() => JsonParser.load_array(load_data("pass", i)), "pass%d.json", i);
            expect_error(() => JsonParser.load_object(load_data("pass", i)),
                "The data doesn't represent a JavaScript object.", "pass%d.json", i);
        }

        i = 3;
        expect_no_error(() => JsonParser.load_object(load_data("pass", i)), "pass%d.json", i);
        expect_error(() => JsonParser.load_array(load_data("pass", i)),
            "The data doesn't represent a JavaScript array.", "pass%d.json", i);
    }

    public void test_fail() {
        int i = 0;
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "The outermost value must be an object or array.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:17 Unexpected end of data. Characters ',' or ']' expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:2 Unexpected character 'u'. A string expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:15 Unexpected character ']'. An object, an array, a string or a primitive value expected.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:22 Unexpected character ','. An object, an array, a string or a primitive value expected.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:4 Unexpected character ','. An object, an array, a string or a primitive value expected.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:26 Extra data has been found after a parsed JSON document. The first character is ','.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:16 Extra data has been found after a parsed JSON document. The first character is ']'.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:22 Unexpected character '}'. A string expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:35 Extra data has been found after a parsed JSON document. The first character is '\"'.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:26 Unexpected character '+'. Characters ',' or '}' expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:23 Unexpected character 'a'. An object, an array, a string or a primitive value expected.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:40 Invalid number: Numbers cannot have leading zeroes.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:28 Unexpected character 'x'. Characters ',' or '}' expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:30 Invalid escape sequence.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:1 Unexpected character '\\'. An object, an array, a string or a primitive value expected.",
            "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:30 Invalid escape sequence.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:20 Maximal array recursion depth reached.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:18 Unexpected character 'n'. A ':' character expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:16 Unexpected character ':'. An object, an array, a string or a primitive value expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:26 Unexpected character ','. A ':' character expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:26 Unexpected character ':'. Characters ',' or ']' expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:18 Unexpected character 't'. The 'e' character of 'true' expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:1 Unexpected character '''. An object, an array, a string or a primitive value expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:3 Invalid control character (09) in a string.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:7 Invalid escape sequence.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "2:0 Invalid control character (0A) in a string.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "2:0 Invalid escape sequence.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:3 Unexpected character ']'. A number character expected", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:4 Unexpected character ']'. A number character expected", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:4 Invalid number: A digit expected but '-' found.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:40 Unexpected end of data. A string expected.", "fail%d.json", i);
        i++; expect_error(() => JsonParser.load(load_data("fail", i)),
            "1:12 Unexpected character '}'. Characters ',' or ']' expected.", "fail%d.json", i);
    }
}

} // namespace Nuvola
