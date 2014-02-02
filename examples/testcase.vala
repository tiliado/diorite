/* 
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

namespace My
{

class TestCase: Diorite.TestCase
{
	construct
	{
		add_test("one", test_one);
		add_test("two", test_two);
		add_test("three", test_three);
		add_test("four", test_four);
	}
	
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
}

int main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	var runner = new Diorite.TestRunner(args);
	runner.add_test_case("MyTestCase", typeof(TestCase));
	return runner.run(args);
}

} // namespace Diorite
