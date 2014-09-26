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

[CCode(has_target=false)]
public delegate bool EqualData(void* data1, void* data2);

/**
 * Base class for test cases.
 */
public abstract class TestCase: GLib.Object
{
	public static bool str_eq(void* data1, void* data2)
	{
		uint8* p1 = *((uint8**) data1);
		uint8* p2 = *((uint8**) data2);
		unowned string str1 = (string) p1;
		unowned string str2 = (string) p2;
		return str_equal(str1, str2);
	}
	
	public static bool int_eq(void* data1, void* data2)
	{
		return *((int*)data1) == *((int*)data2);
	}

	
	public int passed = 0;
	public int failed = 0;
	
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
	[Diagnostics]
	[PrintFormat]
	protected void assert(bool expression, string format, ...)
	{
		if (!process(expression, format, va_list()))
			failure();
	}
	
	/**
	 * Assertion failed
	 * 
	 * Test is terminated.
	 * 
	 */
	[Diagnostics]
	[PrintFormat]
	protected void assert_not_reached(string format, ...)
	{
		process(false, format, va_list());
		failure();
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expression    expression expected to be true
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect(bool expression, string format, ...)
	{
		return process(expression, format, va_list());
	}
	
	/**
	 * Expectation failed
	 * 
	 * Test is not terminated.
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expectation_failed(string format, ...)
	{
		return process(false, format, va_list());
	}
	
	[Diagnostics]
	[PrintFormat]
	protected void fail(string format="", ...)
	{
		process(false, format, va_list());
		failure();
	}
	
	[Diagnostics]
	[PrintFormat]
	protected void message(string format, ...)
	{
		if (!Test.quiet())
		{
			stdout.vprintf(format, va_list());
			stdout.putc('\n');
		}
	}
	
	private bool process(bool expression, string format, va_list args)
	{
		print_result(expression, format, args);
		
		if (expression)
		{
			passed++;
		}
		else
		{
			failed++;
			Test.fail();
		}
		
		return expression;
	}
	
	private void print_result(bool result, string format, va_list args)
	{
		if (!Test.quiet())
		{
			if (format != "")
				stdout.vprintf(format, args);
			
			if (result)
				stdout.puts(" PASS");
			else
				stdout.puts(" FAIL");
			stdout.putc('\n');
		}
	}
	
	private void failure()
	{
		tear_down();
		summary();
		Process.abort();
	}
	
	public void summary()
	{
		if (!Test.quiet())
		{
			stdout.printf(("[%s] %d run, %d passed, %d failed\n"),
			failed > 0 ? "FAIL" : "PASS", passed + failed, passed, failed);
		}
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_str_match(string pattern, string data, string format, ...)
	{
		return process_str_match(true, pattern, data, format, va_list());
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_str_not_match(string pattern, string data, string format, ...)
	{
		return process_str_match(false, pattern, data, format, va_list());
	}
	
	[Diagnostics]
	[PrintFormat]
	protected void assert_str_match(string pattern, string data, string format, ...)
	{
		if (!process_str_match(true, pattern, data, format, va_list()))
			failure();
	}
	
	[Diagnostics]
	[PrintFormat]
	protected void assert_str_not_match(string pattern, string data, string format, ...)
	{
		if (!process_str_match(false, pattern, data, format, va_list()))
			failure();
	}
	
	private bool process_str_match(bool expected, string pattern, string data, string format, va_list args)
	{
		var result = process(PatternSpec.match_simple(pattern, data) == expected, format, args);
		if (!result && !Test.quiet())
			stdout.printf("\tPattern %s should%s match string '%s'.\n", pattern, expected ? "" : " not", data);
		return result;
	}
	
	[Diagnostics]
	[PrintFormat]
	protected void assert_array<T>(T[] expected, T[] found, EqualData eq, string format, ...)
	{
		if(!process_array<T>(expected, found, eq, format, va_list()))
			failure();
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_array<T>(T[] expected, T[] found, EqualData eq, string format, ...)
	{
		return process_array<T>(expected, found, eq, format, va_list());
	}
	
	protected bool process_array<T>(T[] expected, T[] found, EqualData eq, string format, va_list args)
	{
		var limit = int.max(expected.length, found.length);
		var result = true;
		if (expected.length != found.length)
		{
			if (result)
				print_result(false, format, args);
				
			result = false;
			if (!Test.quiet())
				stdout.printf("\tLength mismatch: %d != %d\n", expected.length, found.length);
		}
		
		for (var i = 0; i < limit; i++)
		{
			if (i >= expected.length)
			{
				if (result)
					print_result(false, format, args);
				
				result = false;
				if (!Test.quiet())
					stdout.printf("\tExtra element (%d)\n", i);
			}
			else if (i >= found.length)
			{
				if (result)
					print_result(false, format, args);
				
				result = false;
				if (!Test.quiet())
					stdout.printf("\tMissing element (%d)\n", i);
			}
			else if (!eq(&expected[i], &found[i]))
			{
				if (result)
					print_result(false, format, args);
				
				result = false;
				if (!Test.quiet())
					stdout.printf("\tElement mismatch (%d)\n", i);
			}
		}
		
		if (result)
		{
			print_result(result, format, args);
			passed++;
		}
		else
		{
			failed++;
			Test.fail();
		}
		
		return result;
	}
}

} // namespace Diorite
