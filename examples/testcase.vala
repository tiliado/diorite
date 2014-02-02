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
}

} // namespace Diorite

[ModuleInit]
public void module_init(GLib.TypeModule type_module)
{
}
