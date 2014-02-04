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
 */

namespace My
{

class TestCase: Diorite.TestCase
{
	
	public void test_one()
	{
		message("One");
		assert("foo" == "foo");
		expect("foo" == "foo");
		expect("foo" == "goo");
		assert("foo" == "goo");
	}
	
	public void test_two()
	{
		message("Two");
		assert("foo" == "foo");
		expect("foo" == "foo");
		assert("foo" == "goo");
	}
	
	public void test_three()
	{
		message("Three");
		assert("foo" == "foo");
		expect("foo" == "foo");
		assert("foo" == "goo");
	}
	
	public void test_four()
	{
		message("four");
		assert("foo" == "foo");
		expect("foo" == "foo");
		assert("foo" == "goo");
		message("four success");
	}
	
	public async void test_five()
	{
		message("five starts");
		Idle.add(test_five.callback);
		yield;
		assert(5 == 4 + 1);
		message("five ends");
	}
	
	public void test_array()
	{
		string[] arr1 = {"hello", "world1"};
		string[] arr2 = {"hello", "world", "2"};
		expect_array<string>(arr1, arr2, str_equal, string.dup);
	}
}

} // namespace Diorite

[ModuleInit]
public void module_init(GLib.TypeModule type_module)
{
}
