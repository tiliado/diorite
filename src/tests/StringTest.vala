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

namespace Drt
{

public class StringTest: Diorite.TestCase
{
	public void test_semicolon_separated_set()
	{
		var result = Diorite.String.semicolon_separated_set(null, true);
		expect_uint_equals(0, result.length, "null string");
		result = Diorite.String.semicolon_separated_set("", true);
		expect_uint_equals(0, result.length, "empty string");
		result = Diorite.String.semicolon_separated_set(";", true);
		expect_uint_equals(0, result.length, "empty set");
		var dataset = " hello ; Bye;;1234;byE;;;";
		result = Diorite.String.semicolon_separated_set(dataset, false);
		expect_uint_equals(4, result.length, "original set");
		foreach (var s in new string[]{"hello", "Bye", "1234", "byE"})
			expect_true(result.contains(s), "item: %s", s);
		expect_false(result.contains("bye"), "item: %s", "bye");
		result = Diorite.String.semicolon_separated_set(dataset, true);
		expect_uint_equals(3, result.length, "lowercase set");
		foreach (var s in new string[]{"hello", "bye", "1234"})
			expect_true(result.contains(s), "item: %s", s);
		expect_false(result.contains("Bye"), "item: %s", "Bye");
	}
}

} // namespace Diorite
