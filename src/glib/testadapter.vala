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

public delegate void TestFunc();
public delegate void TestFuncBegin(GLib.AsyncReadyCallback async_callback);
public delegate void TestFuncEnd(GLib.AsyncResult result);

public abstract class TestAdapter
{
	public TestCase test_case;
	public string test_name;
	public bool success = true;
	
	public TestAdapter(TestCase test_case, string test_name)
	{
		this.test_case = test_case;
		this.test_name = test_name;
	}
	
	public virtual void run()
	{
	}
}

public class Adapter: TestAdapter
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

public class AsyncAdapter: TestAdapter
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

} // namespace Diorite
