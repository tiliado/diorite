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
			assertion_failed("%s:%d Assertion %s failed .".printf(
			file, line, expr));
		return result;
	}
	
	/**
	 * For internal usage of dioritetestgen.
	 */
	public bool real_expect1(bool result, string expr, string file, int line)
	{
		if (!result)
			expectation_failed("%s:%d Expectation %s failed.".printf(
			file, line, expr));
		return result;
	}
	
	/**
	 * For internal usage of dioritetestgen.
	 */
	public bool real_assert2(bool result, string expr_left, string op, string expr_right,
	string? str_left, Stringify? val_left, string? str_right, Stringify? val_right,
	string file, int line)
	{
		if (!result)
			assertion_failed("%s:%d Assertion %s %s %s failed: %s %s %s.".printf(
			file, line, expr_left, op, expr_right,
			str_left != null ? strquote(str_left) : val_left(),
			op,
			str_right != null ? strquote(str_right) : val_right()));
		return result;
	}
	
	/**
	 * For internal usage of dioritetestgen.
	 */
	public bool real_expect2(bool result, string expr_left, string op, string expr_right,
	string? str_left, Stringify? val_left, string? str_right, Stringify? val_right,
	string file, int line)
	{
		if (!result)
			expectation_failed("%s:%d Expectation %s %s %s failed: %s %s %s.".printf(
			file, line, expr_left, op, expr_right,
			str_left != null ? strquote(str_left) : val_left(),
			op,
			str_right != null ? strquote(str_right) : val_right()));
		return result;
	}
}

} // namespace Diorite
