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

namespace Drt
{

public class JsonNodeTest: Drt.TestCase
{
	public void test_null()
	{
		var node = (JsonNode) new JsonValue.@null();
		expect_true(node.is_value(), "is value");
		expect_true(node.is_null(), "is null");
		expect_false(node.is_bool(), "is bool");
		expect_false(node.is_int(), "is int");
		expect_false(node.is_double(), "is double");
		expect_false(node.is_string(), "is string");
		expect_false(node.is_object(), "is object");
		expect_false(node.is_array(), "is array");
	}

	public void test_bool()
	{
		var node = (JsonNode) new JsonValue.@bool(true);
		expect_true(node.is_value(), "is value");
		expect_false(node.is_null(), "is null");
		expect_true(node.is_bool(), "is bool");
		expect_false(node.is_int(), "is int");
		expect_false(node.is_double(), "is double");
		expect_false(node.is_string(), "is string");
		expect_false(node.is_object(), "is object");
		expect_false(node.is_array(), "is array");
	}

	public void test_int()
	{
		var node = (JsonNode) new JsonValue.@int(-1234);
		expect_true(node.is_value(), "is value");
		expect_false(node.is_null(), "is null");
		expect_false(node.is_bool(), "is bool");
		expect_true(node.is_int(), "is int");
		expect_false(node.is_double(), "is double");
		expect_false(node.is_string(), "is string");
		expect_false(node.is_object(), "is object");
		expect_false(node.is_array(), "is array");
	}

	public void test_double()
	{
		var node = (JsonNode) new JsonValue.@double(-12.34);
		expect_true(node.is_value(), "is value");
		expect_false(node.is_null(), "is null");
		expect_false(node.is_bool(), "is bool");
		expect_false(node.is_int(), "is int");
		expect_true(node.is_double(), "is double");
		expect_false(node.is_string(), "is string");
		expect_false(node.is_object(), "is object");
		expect_false(node.is_array(), "is array");
	}

	public void test_string()
	{
		var str = "Test ";
		var node = (JsonNode) new JsonValue.@string(str);
		expect_true(node.is_value(), "is value");
		expect_false(node.is_null(), "is null");
		expect_false(node.is_bool(), "is bool");
		expect_false(node.is_int(), "is int");
		expect_false(node.is_double(), "is double");
		expect_true(node.is_string(), "is string");
		expect_false(node.is_object(), "is object");
		expect_false(node.is_array(), "is array");
	}

	public void test_object()
	{
		var node = (JsonNode) new JsonObject();
		expect_false(node.is_value(), "is value");
		expect_false(node.is_null(), "is null");
		expect_false(node.is_bool(), "is bool");
		expect_false(node.is_int(), "is int");
		expect_false(node.is_double(), "is double");
		expect_false(node.is_string(), "is string");
		expect_true(node.is_object(), "is object");
		expect_false(node.is_array(), "is array");
	}

	public void test_array()
	{
		var node = (JsonNode) new JsonArray();
		expect_false(node.is_value(), "is value");
		expect_false(node.is_null(), "is null");
		expect_false(node.is_bool(), "is bool");
		expect_false(node.is_int(), "is int");
		expect_false(node.is_double(), "is double");
		expect_false(node.is_string(), "is string");
		expect_false(node.is_object(), "is object");
		expect_true(node.is_array(), "is array");
	}
}

} // namespace Drt
