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

using Drt.Utils;

namespace Drt {

public class UtilsTest: Drt.TestCase {
    public void test_slist_to_strv() {
        SList<string> list = null;
        string[] expected = new string[10];
        for (var i = 0; i < 10; i++) {
            expected[i] = "item%d".printf(i);
            list.append(expected[i]);
        }
        var result = Drt.Utils.slist_to_strv(list);
        expect_array(wrap_strv(expected), wrap_strv(result), str_eq, "array");
    }

    public void test_list_to_strv() {
        List<string> list = null;
        string[] expected = new string[10];
        for (var i = 0; i < 10; i++) {
            expected[i] = "item%d".printf(i);
            list.append(expected[i]);
        }
        var result = Drt.Utils.list_to_strv(list);
        expect_array(wrap_strv(expected), wrap_strv(result), str_eq, "array");
    }
}

} // namespace Drt
