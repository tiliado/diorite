/*
 * Copyright 2014-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

public errordomain TestError
{
	FAIL;
}

public delegate void TestCallback() throws GLib.Error;

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
	private SList<LogMessage> log_messages = null;
	private bool first_result = true;
	
	construct
	{
		if (GLib.Test.verbose())
			stdout.puts("----------------------------8<----------------------------\n");
	}
	
	/**
	 * Set up environment before each test of this test case.
	 */
	public virtual void set_up()
	{
		first_result = true;
		Test.log_set_fatal_handler(log_fatal_func);
		log_messages = null;
		GLib.Log.set_default_handler(log_handler);
	}
	
	/**
	 * Clean up environment after each test of this test case.
	 */
	public virtual void tear_down()
	{
		check_log_messages();
		log_messages = null;
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
	protected void assert(bool expression, string format, ...) throws TestError
	{
		if (!process(expression, format, va_list()))
			abort_test();
	}
	
	/**
	 * Assertion failed
	 * 
	 * Test is terminated.
	 * 
	 */
	[Diagnostics]
	[PrintFormat]
	protected void assert_not_reached(string format, ...) throws TestError
	{
		process(false, format, va_list());
		abort_test();
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
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expression    expression expected to be true
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_true(bool expression, string format, ...)
	{
		return process(expression, format, va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expression    expression expected to be false
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_false(bool expression, string format, ...)
	{
		return process(!expression, format, va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_int_equals(int expected, int value, string format, ...)
	{
		return process(expected == value, "%s: %d == %d".printf(format, expected, value), va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_uint_equals(uint expected, uint value, string format, ...)
	{
		return process(expected == value, "%s: %u == %u".printf(format, expected, value), va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_int64_equals(int64 expected, int64 value, string format, ...)
	{
		return process(expected == value, "%s: %s == %s".printf(
			format, expected.to_string(), value.to_string()), va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_double_equals(double expected, double value, string format, ...)
	{
		return process(expected == value, "%s: %s == %s".printf(
			format, expected.to_string(), value.to_string()), va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_str_equals(string? expected, string? value, string format, ...)
	{
		var result = process(expected == value, format, va_list());
		if (!result && !Test.quiet())
			stdout.printf("\t '%s' == '%s' failed.\n", expected, value);
		return result;
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_str_not_equal(string? expected, string? value, string format, ...)
	{
		var result = process(expected != value, format, va_list());
		if (!result && !Test.quiet())
			stdout.printf("\t '%s' != '%s' failed.\n", expected, value);
		return result;
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_blob_equal(uint8[]? expected, uint8[]? value, string format, ...)
	{
		return process_bytes_equal(
			expected != null ? new Bytes.static(expected): null,
			value != null ? new Bytes.static(value): null,
			format, va_list());
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_bytes_equal(GLib.Bytes? expected, GLib.Bytes? value, string format, ...)
	{
		return process_bytes_equal(expected, value, format, va_list());
	}
	
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_byte_array_equal(GLib.ByteArray? expected, GLib.ByteArray? value, string format, ...)
	{
		return process_bytes_equal(
			expected != null ? new Bytes.static(expected.data): null,
			value != null ? new Bytes.static(value.data): null,
			format, va_list());
	}
	
	private bool process_bytes_equal(GLib.Bytes? expected, GLib.Bytes? value, string format, va_list args)
	{
		var result = process(
			(expected == null && value == null)
			|| (expected != null && value != null && expected.compare(value) == 0),
			format, args);
		if (!result && !Test.quiet())
		{
			string? expected_hex = null, value_hex = null;
			if (expected != null)
				Diorite.bin_to_hex(expected.get_data(), out expected_hex);
			if (value != null)
				Diorite.bin_to_hex(value.get_data(), out value_hex);
			stdout.printf("\t '%s' == '%s' failed.\n", expected_hex, value_hex);
		}
		return result;
	}
	
	/**
	 * Expectation
	 * 
	 * Test is not terminated when expectation fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected bool expect_value_equal(GLib.Value? expected, GLib.Value? actual, string format, ...)
	{
		return process_value_equal(expected, actual, format, va_list());
	}
	
	/**
	 * Assertion
	 * 
	 * Test is terminated when assertion fails.
	 * 
	 * @param expected    expected value
	 * @param value       real value
	 */
	[Diagnostics]
	[PrintFormat]
	protected void assert_value_equal(GLib.Value? expected, GLib.Value? actual, string format, ...) throws TestError
	{
		if (!process_value_equal(expected, actual, format, va_list()))
			abort_test();
	}
	
	private bool process_value_equal(GLib.Value? expected, GLib.Value? actual, string format, va_list args)
	{
		string description;
		var result = process(Value.equal_verbose(expected, actual, out description), format, args);
		if (!result && !Test.quiet())
			stdout.printf("\t %s\n", description);
		return result;
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
	protected void fail(string format="", ...) throws TestError
	{
		process(false, format, va_list());
		abort_test();
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
			if (format != "" && (Test.verbose() || !result))
			{
				if (first_result)
				{
					stdout.putc('\n');
					first_result = false;
				}
				stdout.vprintf(format, args);
			}
			
			if (!result)
				stdout.puts(" FAIL\n");
			else if (Test.verbose())
				stdout.puts(" PASS\n");
		}
	}
	
	private void abort_test() throws TestError
	{
		 throw new TestError.FAIL("Test failed");
	}
	
	public void exception(GLib.Error e)
	{
		if (!(e is TestError))
			expectation_failed("Uncaught exception: %s %d %s", e.domain.to_string(), e.code, e.message);
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_no_error(TestCallback func, string format, ...)
	{
		string? err = null;
		try
		{
			func();
		}
		catch (GLib.Error e)
		{
			err = "\tUnexpected error: %s %d %s\n".printf(e.domain.to_string(), e.code, e.message);
		}
		var result = process(err == null, format, va_list());
		if (!result && !Test.quiet())
			stdout.puts(err);
		return result;
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_error(TestCallback func, string message_pattern, string format, ...)
	{
		var result = false;
		string? err = null;
		try
		{
			func();
		}
		catch (GLib.Error e)
		{
			result = PatternSpec.match_simple(message_pattern, e.message);
			err = e.message;
		}
		process(result, format, va_list());
		if (!result && !Test.quiet())
		{
			stdout.printf("An exception was expected: %s\n", message_pattern);
			if (err != null)
				stdout.printf("Other exception has been thrown: %s\n", err);
			
		}
		return result;
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_type<T>(void* object, string format, ...)
	{
		string? type_found = null;
		var expected_type = typeof(T);
		var result = false;
		if (object != null)
		{
			var object_type = Type.from_instance(object);
			type_found = object_type.name();
			result = (object_type == expected_type || object_type.is_a(expected_type));
		}
		process(result, format, va_list());
		if (!result && !Test.quiet())
		{
			stdout.printf("A type %s expected but %s found.\n", expected_type.name(), type_found);
		}
		return result;
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_enum<T>(T expected, T found, string format, ...)
	{
		var expected_type = typeof(T);
		var enum_name = expected_type.name();
		var result = false;
		string? err = null;
		unowned EnumClass enum_class = expected_type.is_enum() ? (EnumClass) expected_type.class_ref() : null;
		if (enum_class == null)
		{
			err = enum_name + "is not an enumeration.\n";
		}
		else
		{
			var expected_member = enum_class.get_value((int) expected);
			if (expected_member == null)
			{
				err = "The value expected (%d) is not a member of the %s enumeration.\n".printf(
					(int) expected, enum_name);
			}
			else
			{
				var member_found = enum_class.get_value((int) found);
				if (member_found == null)
				{
					err = "The value found (%d) is not a member of the %s enumeration.\n".printf(
						(int) found, enum_name);
				}
				else if ((int) found != (int) expected)
				{
					err = "Expected the enum value %s (%d) but the value %s (%d) found.\n".printf(
						expected_member.value_name, (int) expected, member_found.value_name, (int) found);
				}
				else
				{
					result = true;
				}
			}
		}
		process(result, format, va_list());
		if (!result && err != null && !Test.quiet())
			stdout.puts(err);
		return result;
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_null<T>(T? val, string format, ...)
	{
		return process(val == null, "assertion val is null failed; " + format, va_list());
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_not_null<T>(T? val, string format, ...)
	{
		return process(val != null, "assertion val is not null failed; " + format, va_list());
	}
	
	public void summary()
	{
		if (!Test.quiet())
		{
			stdout.printf(("[%s] %d run, %d passed, %d failed"),
			failed > 0 ? "FAIL" : "PASS", passed + failed, passed, failed);
			if (GLib.Test.verbose())
				stdout.puts("\n----------------------------8<----------------------------\n");
			else
				stdout.puts(" ");
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
	protected void assert_str_match(string pattern, string data, string format, ...) throws TestError
	{
		if (!process_str_match(true, pattern, data, format, va_list()))
			abort_test();
	}
	
	[Diagnostics]
	[PrintFormat]
	protected void assert_str_not_match(string pattern, string data, string format, ...) throws TestError
	{
		if (!process_str_match(false, pattern, data, format, va_list()))
			abort_test();
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
	protected void assert_array<T>(T[] expected, T[] found, EqualData eq, string format, ...) throws TestError
	{
		if(!process_array<T>(expected, found, eq, format, va_list()))
			abort_test();
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
	
	public virtual bool log_fatal_func(string? log_domain, LogLevelFlags log_levels, string message)
	{
		return false;
	}
	
	private void log_handler(string? domain, LogLevelFlags level, string text)
	{
		log_messages.append(new LogMessage(domain, level, text));
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_critical_message(string? domain, string text_pattern, string format, ...)
	{
		return expect_log_message_va(domain, LogLevelFlags.LEVEL_CRITICAL, text_pattern, format, va_list());
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_warning_message(string? domain, string text_pattern, string format, ...)
	{
		return expect_log_message_va(domain, LogLevelFlags.LEVEL_WARNING, text_pattern, format, va_list());
	}
	
	[Diagnostics]
	[PrintFormat]
	protected bool expect_log_message(string? domain, LogLevelFlags level, string text_pattern, string format, ...)
	{
		return expect_log_message_va(domain, level, text_pattern, format, va_list());
	}
	
	private bool expect_log_message_va(string? domain, LogLevelFlags level, string text_pattern, string format, va_list args)
	{
		var result = false;	
		if (log_messages != null)
		{
			foreach (unowned LogMessage msg in log_messages)
			{
				if ((msg.level & level) == 0 || msg.domain != domain)
					continue;
				if (PatternSpec.match_simple(text_pattern, msg.text))
				{
					result = true;
					log_messages.remove(msg);
				}
				break;
			}
		}
		process(result, format, args);
		if (!result && !Test.quiet())
			stdout.printf("\t Expected log message '%s' '%s' not found.\n", domain, text_pattern);
		return result;
	}
	
	private void check_log_messages()
	{
		foreach (unowned LogMessage msg in log_messages)
		{
			if ((msg.level & LogLevelFlags.LEVEL_ERROR) != 0)
				expectation_failed("Uncaught error log message: %s %s", msg.domain, msg.text);
			else if ((msg.level & LogLevelFlags.LEVEL_WARNING) != 0)
				expectation_failed("Uncaught warning log message: %s %s", msg.domain, msg.text);
			else if ((msg.level & LogLevelFlags.LEVEL_CRITICAL) != 0)
				expectation_failed("Uncaught critical log message: %s %s", msg.domain, msg.text);
		}
	}
	
	private class LogMessage
	{
		public string? domain;
		public LogLevelFlags level;
		public string text;
		
		public LogMessage(string? domain, LogLevelFlags level, string text)
		{
			this.text = text;
			this.level = level;
			this.domain = domain;
		}
	}
}

} // namespace Diorite
