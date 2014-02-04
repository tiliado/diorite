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
public delegate void TestFunc(TestCase t);
[CCode(has_target=false)]
public delegate void TestFuncBegin(TestCase t, GLib.AsyncReadyCallback async_callback);
[CCode(has_target=false)]
public delegate void TestFuncEnd(TestCase t, GLib.AsyncResult result);
[CCode(has_target=false)]
public delegate void TestLoop(TestCase t, int i);
[CCode(has_target=false)]
public delegate void TestLoopBegin(TestCase t, int i, GLib.AsyncReadyCallback async_callback);
[CCode(has_target=false)]
public delegate void TestLoopEnd(TestCase t, GLib.AsyncResult result);

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
	
	public Adapter(TestCase test_case, string test_name, TestFunc test_func)
	{
		base(test_case, test_name);
		this.test_func = test_func;
	}
	
	public override void run()
	{
		test_func(test_case);
	}
}

public class LoopAdapter: TestAdapter
{
	private TestLoop test_func;
	private int loop_start;
	private int loop_end;
	private int loop_step;
	
	public LoopAdapter(TestCase test_case, string test_name, TestLoop test_func, int loop_start, int loop_end, int loop_step)
	{
		base(test_case, test_name);
		this.test_func = test_func;
		this.loop_start = loop_start;
		this.loop_end = loop_end;
		this.loop_step = loop_step;
	}
	
	public override void run()
	{
		var step = loop_step.abs();
		if (loop_end > loop_start)
		{
			for (var i = loop_start; i < loop_end; i += step)
			{
				test_case.mark = "loop%d".printf(i);
				test_func(test_case, i);
			}
		}
		else
		{
			for (var i = loop_start; i > loop_end; i -= step)
			{
				test_case.mark = "loop%d".printf(i);
				test_func(test_case, i);
			}
		}
	}
}

public class AsyncAdapter: TestAdapter
{
	private TestFuncBegin test_func_begin;
	private TestFuncEnd test_func_end;
	private MainLoop? loop;
	
	public AsyncAdapter(TestCase test_case, string test_name, TestFuncBegin test_func_begin, TestFuncEnd test_func_end)
	{
		base(test_case, test_name);
		this.test_func_begin = test_func_begin;
		this.test_func_end = test_func_end;
	}
	
	public override void run()
	{
		loop = new MainLoop();
		test_func_begin(test_case, async_done);
		if (loop != null)
			loop.run();
	}
	
	private void async_done(Object? source_object, AsyncResult res)
	{
		test_func_end(test_case, res);
		if (loop.is_running())
			loop.quit();
		loop = null;
	}
}

public class AsyncLoopAdapter: TestAdapter
{
	private TestLoopBegin test_func_begin;
	private TestLoopEnd test_func_end;
	private MainLoop? loop;
	private int loop_start;
	private int loop_end;
	private int loop_step;
	
	public AsyncLoopAdapter(TestCase test_case, string test_name, TestLoopBegin test_func_begin, TestLoopEnd test_func_end, int loop_start, int loop_end, int loop_step)
	{
		base(test_case, test_name);
		this.test_func_begin = test_func_begin;
		this.test_func_end = test_func_end;
		this.loop_start = loop_start;
		this.loop_end = loop_end;
		this.loop_step = loop_step;
	}
	
	public override void run()
	{
		var step = loop_step.abs();
		if (loop_end > loop_start)
		{
			for (var i = loop_start; i < loop_end; i += step)
			{
				test_case.mark = "loop%d".printf(i);
				loop = new MainLoop();
				test_func_begin(test_case, i, async_done);
				if (loop != null)
					loop.run();
			}
		}
		else
		{
			for (var i = loop_start; i > loop_end; i -= step)
			{
				test_case.mark = "loop%d".printf(i);
				loop = new MainLoop();
				test_func_begin(test_case, i, async_done);
				if (loop != null)
					loop.run();
			}
		}
	}
	
	private void async_done(Object? source_object, AsyncResult res)
	{
		test_func_end(test_case, res);
		if (loop.is_running())
			loop.quit();
		loop = null;
	}
}

} // namespace Diorite
