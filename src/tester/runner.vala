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

static TestModule module = null;

/**
 * Runs tests.
 */
public class TestRunner
{
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
		output = stderr;
	}
	
	/**
	 * Starts testing.
	 * 
	 * @param args    arguments vector
	 */
	public int run(string[] args)
	{
		if (args.length < 3)
		{
			return 1;
		}
		
		if (args.length >= 4)
			return run_test(args[1], args[2], args[3]);
		
		var spec_reader = new TestSpecReader(args[2]);
		foreach (string test in spec_reader)
		{
			if (run_subprocess(args[0], args[1], args[2], test))
				tests_passed++;
			else
				tests_failed++;
		}
		
		log("*** SUMMARY:\n");
		logf("- tests run: %u\n- tests passed: %u\n- tests failed: %u\n",
		tests_passed + tests_failed, tests_passed, tests_failed);
		logf("- checks run: %u\n- checks passed: %u\n- checks failed: %u\n",
		checks_passed + checks_failed, checks_passed, checks_failed);
		return tests_failed == 0 ? 0 : 1;
	}
	
	private int run_test(string module_name, string specfile, string path)
	{
		this.path = path;
		module = new TestModule(module_name);
		if (!module.load())
		{
			logf("*** ERROR: %s\n", module.error);
			return 1;
		}
		
		var spec_reader = new TestSpecReader(specfile);
		try
		{
			var spec = spec_reader.get_spec(path);
			adapter = module.load_test(spec);
		}
		catch (Error e)
		{
			logf("*** ERROR: %s\n", e.message);
			return 1;
		}
		
		if (adapter == null)
		{
			logf("*** ERROR: %s\n", module.error);
			return 1;
		}
		
		test_case = adapter.test_case;
		test_case.assertion_failed = this.assertion_failed;
		test_case.expectation_failed = this.expectation_failed;
		started();
		test_case.set_up();
		adapter.run();
		test_case.tear_down();
		module.unload();
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
	
	private void expectation_failed(string? message=null)
	{
		checks_failed++; // TODO: pass to parent runner
		adapter.success = false;
		logf("*** FAIL  %s: %s\n", path, message ?? "(no message)");
	}
	
	private void assertion_failed(string? message=null)
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
		Process.exit(success ? 0 : 2);
		return success ? 0 : 2;
	}
	
	private bool run_subprocess(string binary, string module_name, string specfile, string path)
	{
		string[] argv = {binary, module_name, specfile, path};
		logf("+ %s %s %s %s\n", binary, module_name, specfile, path);
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
			
			#if LINUX
			var status = process.status;
			if (Process.if_exited(status))
			{
				status = Process.exit_status(status);
				if (status == 0)
					return true;
				logf("*** EXIT with status %d\n", status);
				return false;
			}
			
			if(Process.if_signaled(status))
			{
				logf("*** SIGNAL %s\n", (Process.term_sig(status)).to_string());
				return false;
			}
			
			if (Process.core_dump(status))
			{
				logf("*** SIGNAL %s\n", (Process.term_sig(status)).to_string());
				return false;
			}
			
			logf("*** UNKNOWN EXIT %s\n", (Process.term_sig(status)).to_string());
			return false;
			#else
			if (process.status == 0)
				return true;
			
			logf("*** EXIT with status %d", process.status);
			return false;
			#endif
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return false;
		}
	}
}

} // namespace Diorite
