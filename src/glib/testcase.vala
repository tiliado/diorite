/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Diorite
{

public delegate void TestLog(string message);

/**
 * Delegate to return a string.
 * 
 * @return non-null string
 */
public delegate string Stringify();

[CCode(has_target=false)]
public delegate bool EqualData(void* data1, void* data2);

[CCode(has_target=false)]
public delegate string StringifyData(void* data);

namespace Test
{
	public bool str_eq(void* data1, void* data2)
	{
		uint8* p1 = *((uint8**) data1);
		uint8* p2 = *((uint8**) data2);
		unowned string str1 = (string) p1;
		unowned string str2 = (string) p2;
		return str_equal(str1, str2);
	}
	
	public bool int_eq(void* data1, void* data2)
	{
		return *((int*)data1) == *((int*)data2);
	}
	
	public static string str_int(void* data)//, string? def=null)
	{
		int i = *((int*)data);
		return i.to_string();
	}
	
	public static string str_str(void* data)//, string? def=null)
	{
		uint8* p = *((uint8**) data);
		unowned string str = (string) p;
		return str.dup();
	}
}

private static string strquote(string str)
{
	return "\"" + str.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
}

/**
 * Base class for test cases.
 */
public abstract class TestCase: GLib.Object
{
	public unowned TestLog assertion_failed = null;
	public unowned TestLog expectation_failed = null;
	public string? mark = null;
	
	/**
	 * Set up environment before each test of this test case.
	 */
	public virtual void set_up()
	{
	}
	
	/**
	 * Clean up environment after each test of this test case.
	 */
	public virtual void tear_down()
	{
	}
	
	/**
	 * Assertion
	 * 
	 * Test is terminated when assertion fails.
	 * 
	 * @param expression    expression expected to be true
	 */
	public void assert(bool expression)
	{
		GLib.assert_not_reached();
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expression    expression expected to be true
	 */
	public void expect(bool expression)
	{
		GLib.assert_not_reached();
	}
	
	/**
	 * For internal usage of dioritetestgen.
	 */
	public bool real_assert1(bool result, string expr, string file, int line)
	{
		if (!result)
		{
			var mrk = mark != null ? ":" + mark : "";
			assertion_failed("%s:%d%s Assertion %s failed .".printf(
			file, line, mrk, expr));
		}
		return result;
	}
	
	/**
	 * For internal usage of dioritetestgen.
	 */
	public bool real_expect1(bool result, string expr, string file, int line)
	{
		if (!result)
		{
			var mrk = mark != null ? ":" + mark : "";
			expectation_failed("%s:%d%s Expectation %s failed.".printf(
			file, line, mrk, expr));
		}
		return result;
	}
	
	/**
	 * For internal usage of dioritetestgen.
	 */
	public bool real_expect2(bool assertion, bool result, string expr_left, string op, string expr_right,
	string? str_left, string? str_right,
	string file, int line)
	{
		if (!result)
		{
			var check_type = assertion ? "Assertion" : "Expectation";
			var mrk = mark != null ? ":" + mark : "";
			expectation_failed("%s:%d%s %s %s %s %s failed: %s %s %s.".printf(
			file, line, mrk, check_type, expr_left, op, expr_right,
			str_left != null ? str_left : "???",
			op,
			str_right != null ? str_right : "???"));
		}
		return result;
	}
	
	public void expect_array(ulong type_size, void* expected, void* found,
	EqualData equal_func, StringifyData stringify_func)
	{
		GLib.assert_not_reached();
	}
	
	public void assert_array(ulong type_size, void* expected, void* found,
	EqualData equal_func, StringifyData stringify_func)
	{
		GLib.assert_not_reached();
	}
	
	public bool _expect_array(bool assertion, string expr_left, string expr_right,
	ulong type_size, void* expected, int expected_length, void* found, int found_length,
	EqualData eq, StringifyData str, string file, int line)
	{
		var buffer = new StringBuilder();
		var limit = int.max(expected_length, found_length);
		if (expected_length != found_length)
			buffer.append_printf("Length mismatch: %d != %d\n", expected_length, found_length);
		
		// Pointer arithmetics. Big thanks to Understanding and Using C Pointers by Richard Reese
		uint8* exp = expected;
		uint8* fnd = found;
		
		for (var i = 0; i < limit; i++)
		{
			if (i >= expected_length)
				buffer.append_printf("Extra element (%d): %s\n", i, str(fnd + i * type_size));
			else if (i >= found_length)
				buffer.append_printf("Missing element (%d): %s\n", i, str(exp + i * type_size));
			else if (!eq(exp + i * type_size, fnd + i * type_size))
				buffer.append_printf("Element mismatch (%d): %s != %s\n", i, str(exp + i * type_size), str(fnd + i * type_size));
		}
		
		if (buffer.len > 0)
		{
			var mrk = mark != null ? ":" + mark : "";
			var check_type = assertion ? "Assertion" : "Expectation";
			buffer.prepend("%s:%d%s %s %s == %s failed:\n".printf(file, line, mrk, check_type, expr_left, expr_right));
			if (assertion)
				assertion_failed(buffer.str);
			else
				expectation_failed(buffer.str);
			return false;
		}
		return true;
	}
}

} // namespace Diorite
