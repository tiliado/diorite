/*
 * Copyright 2011-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

public delegate void TestFunc();
public delegate void TestFuncBegin(GLib.AsyncReadyCallback async_callback);
public delegate void TestFuncEnd(GLib.AsyncResult result);

public abstract class BaseAdapter
{
	public TestCase test_case;
	public string test_name;
	
	public BaseAdapter(TestCase test_case, string test_name)
	{
		this.test_case = test_case;
		this.test_name = test_name;
	}
	
	public virtual void run()
	{
	}
}

public class Adapter: BaseAdapter
{
	private TestFunc test_func;
	
	public Adapter(TestCase test_case, string test_name, owned TestFunc test_func)
	{
		base(test_case, test_name);
		this.test_func = (owned) test_func;
	}
	
	public override void run()
	{
		test_func();
	}
}

public class AsyncAdapter: BaseAdapter
{
	private TestFuncBegin test_func_begin;
	private TestFuncEnd test_func_end;
	private MainLoop loop;
	
	public AsyncAdapter(TestCase test_case, string test_name, owned TestFuncBegin test_func_begin, owned TestFuncEnd test_func_end)
	{
		base(test_case, test_name);
		this.test_func_begin = (owned) test_func_begin;
		this.test_func_end = (owned) test_func_end;
	}
	
	public override void run()
	{
		test_func_begin(async_done);
		loop.run();
	}
	
	public void async_done(Object? source_object, AsyncResult res)
	{
		test_func_end(res);
		loop.quit();
	}
}

public abstract class TestCase: GLib.Object
{
	internal List<BaseAdapter> adapters = null;
	
	public void add_test(string name, owned TestFunc test)
	{
		var adapter = new Adapter(this, name, (owned) test);
		adapters.append(adapter);
	}
	
	public void add_async_test(string name, owned TestFuncBegin test_begin, owned TestFuncEnd test_end)
	{
		var adapter = new AsyncAdapter(this, name, (owned) test_begin, (owned) test_end);
		adapters.append(adapter);
	}
	
	
	public virtual void set_up()
	{
	}
	
	public virtual void tear_down()
	{
	}
}

public class TestRunner
{
	private HashTable<string, Type?> test_cases;
	public TestRunner(ref string[] args)
	{
		test_cases = new HashTable<string, Type>(str_hash, str_equal);
	}
	
	/**
	 * Loads test metadata from file
	 */
	public void add_test_case(string name, Type test_case)
	{
		test_cases.insert(name, test_case);
	}
	
	public void run_all()
	{
		var keys = test_cases.get_keys();
		keys.sort(strcmp);
		foreach (var name in keys)
		{
			var test_case = get_test_case(name);
			if (test_case == null)
				continue;
			
			foreach (var adapter in test_case.adapters)
				run_subprocess(name + "/" + adapter.test_name);
		}
	}
	
	public TestCase? get_test_case(string name)
	{
		var type = test_cases.lookup(name);
		if (type == null)
			return null;
		
		return Object.new(type) as TestCase;
	}
	
	public int run()
	{
		return 1;
	}
	
	public void run_test(string path)
	{
//~ 		var test_case = get_test_case(Path.get_dirname(path))
//~ 		var test_case != null
//~ 		var name = Path.get_basename(path);
//~ 		Adapter? adapter = null;
//~ 		foreach(var a in test_case.adapters)
//~ 		{
//~ 			if (a.test_name == name)
//~ 			{
//~ 				adapter = a;
//~ 				break;
//~ 			}
//~ 		}
//~ 		
//~ 		if (adapter == null)
//~ 		{
//~ 			error;
//~ 		}
//~ 		
//~ 		started();
//~ 		test_case.set_up();
//~ 		adapter.run();
//~ 		test_case.tear_down();
//~ 		finished();
	}
	
	private void run_subprocess(string path)
	{
//~ 		excex arg[0] --run path
	}
}

class MyTestCase: TestCase
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
	}
	
	public void test_two()
	{
		message("Two");
	}
	
	public void test_three()
	{
		message("Three");
	}
	
	public void test_four()
	{
		message("four");
	}
}

int main(string[] args)
{
	var runner = new TestRunner(ref args);
	runner.add_test_case("MyTestCase", typeof(MyTestCase));
	return runner.run();
}

} // namespace Diorite
