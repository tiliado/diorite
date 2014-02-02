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

/**
 * Runs tests.
 */
public class TestRunner
{
	private HashTable<string, Type?> test_cases;
	private string? path;
	private TestAdapter? adapter;
	private TestCase test_case;
	private unowned FileStream output;
	private uint tests_failed = 0;
	private uint tests_passed = 0;
	private uint checks_failed = 0;
	private uint checks_passed = 0;
	
	/**
	 * Creates new test runner object.
	 * 
	 * @param args    arguments vector
	 */
	public TestRunner(string[] args)
	{
		test_cases = new HashTable<string, Type>(str_hash, str_equal);
		output = stderr;
	}
	
	/**
	 * Adds test case
	 * 
	 * @param name    test case name
	 * @param type    class of the test case
	 */
	public void add_test_case(string name, Type type)
	{
		test_cases.insert(name, type);
	}
	
	/**
	 * Creates new test case object for given name.
	 * 
	 * @param name    a test case name
	 * @return newly initialized test case
	 */
	public TestCase? get_test_case(string name)
	{
		var type = test_cases.lookup(name);
		if (type == null)
			return null;
		
		return Object.new(type) as TestCase;
	}
	
	/**
	 * Starts testing.
	 * 
	 * @param args    arguments vector
	 */
	public int run(string[] args)
	{
		if (args.length >= 2)
			return run_test(args[1]);
		
		foreach(var key in test_cases.get_keys())
		{
			var t_case = get_test_case(key);
			foreach (var adapter in t_case.adapters)
			{
				var result = run_subprocess(args[0], key + "/" + adapter.test_name);
				if (result != 0)
					tests_failed++;
				else
					tests_passed++;
			}
		}
		
		log("*** SUMMARY:\n");
		logf("- tests run: %u\n- tests passed: %u\n- tests failed: %u\n",
		tests_passed + tests_failed, tests_passed, tests_failed);
		logf("- checks run: %u\n- checks passed: %u\n- checks failed: %u\n",
		checks_passed + checks_failed, checks_passed, checks_failed);
		return tests_failed == 0 ? 0 : 1;
	}
	
	private int run_test(string path)
	{
		this.path = path;
		test_case = get_test_case(Path.get_dirname(path));
		return_val_if_fail(test_case != null, 1);
		var name = Path.get_basename(path);
		foreach(var a in test_case.adapters)
		{
			if (a.test_name == name)
			{
				adapter = a;
				break;
			}
		}
		
		return_val_if_fail(adapter != null, 1);
		started();
		test_case.runner = this;
		test_case.set_up();
		adapter.run();
		test_case.tear_down();
		return finished(path, adapter.success);
	}
	
	private void started()
	{
		logf("*** START %s\n", path); // TODO: pass to parent runner
	}
	
	public void check_passed()
	{
		checks_passed++;  // TODO: pass to parent runner
	}
	
	public void expectation_failed(string? message=null)
	{
		checks_failed++; // TODO: pass to parent runner
		adapter.success = false;
		logf("*** FAIL  %s: %s\n", path, message ?? "(no message)");
	}
	
	public void assertion_failed(string? message=null)
	{
		checks_failed++; // TODO: pass to parent runner
		adapter.success = false;
		logf("*** FAIL  %s: %s\n", path, message ?? "(no message)");
		test_case.tear_down();
	}
	
	/**
	 * Prints message to log
	 * 
	 * @param format    message format
	 */
	[PrintfFormat]
	public void logf(string format, ...)
	{
		var text = format.vprintf(va_list());
		log(text);
	}
	
	/**
	 * Prints line to log
	 * 
	 * @param line    line to log
	 */
	public void log(string line)
	{
		lock (output)
		{
			output.puts(line);
			output.flush();
		}
	}
	 
	private int finished(string path, bool success)
	{
		logf("*** DONE  %s %s\n", path, success.to_string());
		return success ? 0 : 2;
	}
	
	private int run_subprocess(string binary, string path)
	{
		string[] argv = {binary, path};
		try
		{
			var process = new Diorite.Subprocess(argv, Diorite.SubprocessFlags.NONE);
			if(!process.wait(30000)) // TODO: param to change timeout
			{
				logf("*** TIMEOUT %s\n", path);
				process.exit();
				if (!process.wait(15000));
					process.force_exit();
			}
			
			return process.status; // TODO: parse status
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return 1;
		}
	}
}

} // namespace Diorite
