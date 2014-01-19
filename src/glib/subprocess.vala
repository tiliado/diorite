/*
 * Copyright 2013-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

public enum SubprocessFlags
{
	NONE,
	INPUT_PIPE,
	INPUT_INHERIT,
	OUTPUT_PIPES,
	OUTPUT_SILENCE,
	INHERIT_FDS
}

/**
 * Subprocess is a class for creation of child process and interaction with it.
 * (See also GIO Subprocess for more robust alternative.)
 */
public class Subprocess: GLib.Object
{
	public int pid {get; private set; default = -1;}
	public int status {get; set; default = -1;}
	public GLib.InputStream? stdin_pipe {get; private set;}
	public GLib.OutputStream? stdout_pipe {get; private set;}
	public GLib.OutputStream? stderr_pipe {get; private set;}
	public bool running {get; private set; default = false;}
	private string[] argv;
	private SubprocessFlags flags;
	private MainLoop? loop = null;
	private bool loop_result = false;
	private uint loop_timeout = 0;
	
	/**
	 * Creates new subprocess.
	 * 
	 * @param argv     vector of commandline arguments
	 * @param flags    flags that define the behavior of the subprocess
	 * @throw GLib.Error on failure
	 */
	public Subprocess([CCode (array_length=false, array_null_terminated=true)] string[] argv,
	SubprocessFlags flags) throws GLib.Error
	{
		if (argv.length < 1)
			throw new Error.INVALID_ARGUMENT("Commandline arguments vector is empty.");
		
		this.argv = argv;
		this.flags = flags;
		
		GLib.SpawnFlags spawn_flags = SpawnFlags.DO_NOT_REAP_CHILD;
		if (!(Path.DIR_SEPARATOR_S in argv[0]))
			spawn_flags |=  SpawnFlags.SEARCH_PATH;
		if ((flags & SubprocessFlags.INPUT_INHERIT) != 0)
			spawn_flags |= SpawnFlags.CHILD_INHERITS_STDIN;
		if ((flags & SubprocessFlags.INHERIT_FDS) != 0)
			spawn_flags |= SpawnFlags.LEAVE_DESCRIPTORS_OPEN;
		if ((flags & SubprocessFlags.OUTPUT_SILENCE) != 0)
		{
			spawn_flags |= SpawnFlags.STDOUT_TO_DEV_NULL;
			spawn_flags |= SpawnFlags.STDERR_TO_DEV_NULL;
		}
		
		int child_pid = -1;
		int child_stdin = -1;
		int child_stdout = -1;
		int child_stderr = -1;
		
		if ((flags & SubprocessFlags.INPUT_PIPE) == 0)
		{
			if ((flags & SubprocessFlags.OUTPUT_PIPES) == 0)
				running = Process.spawn_async_with_pipes(null, argv, null, spawn_flags,
				null, out child_pid, null, null, null );
			else
				running = Process.spawn_async_with_pipes(null, argv, null, spawn_flags,
				null, out child_pid, null, out child_stdout, out child_stderr);
		}
		else
		{
			if ((flags & SubprocessFlags.OUTPUT_PIPES) == 0)
				running = Process.spawn_async_with_pipes(null, argv, null, spawn_flags,
				null, out child_pid, out child_stdin, null, null );
			else
				running = Process.spawn_async_with_pipes(null, argv, null, spawn_flags,
				null, out child_pid, out child_stdin, out child_stdout, out child_stderr);
		}
		
		ChildWatch.add(child_pid, child_watch);
		if (running)
		{
			pid = child_pid;
			stdin_pipe = input_stream_from_pipe(child_stdin);
			stdout_pipe = output_stream_from_pipe(child_stdout);
			stderr_pipe = output_stream_from_pipe(child_stderr);
		}
	}
	
	/**
	 * Emitted when the subprocess exited.
	 */
	public signal void exited();
	
	/**
	 * Waits for the subprocess to exit
	 * 
	 * @param timeout    Miliseconds to wait or zero to wait forever.
	 * @return true in the subprocess exited before timeout
	 */
	public bool wait(uint timeout=0)
	{
		return_val_if_fail(loop == null, false);
		if (!running)
			return true;
		
		lock (loop)
		{
			loop = new MainLoop();
			loop_result = true;
			if (timeout > 0)
				loop_timeout = Timeout.add(timeout,on_loop_timeout); 
		}
		loop.run();
		lock (loop)
		{
			loop = null;
			if (loop_timeout > 0)
			{
				Source.remove(loop_timeout);
				loop_timeout = 0;
			}
		}
		return loop_result;
	}
	
	/**
	 * Forcefully terminate the subprocess.
	 * 
	 * On Unix, it sends signal SIGKILL. On Windows, it uses TerminateProcess call.
	 */
	public void force_exit()
	{
		#if LINUX
		send_signal(Posix.SIGKILL);
		#elif WIN
		((Win32.Process) pid).terminate(0);
		#else
		UNSUPPORTED PLATFORM!
		#endif
	}
	
	#if LINUX
	// Intentionally not exposed as public.
	private void send_signal(int signum)
	{
		if (pid != 0)
			Posix.kill((Posix.pid_t) pid, signum);
	}
	#endif
	
	private void child_watch(Pid pid, int status)
	{
		Process.close_pid(pid);
		this.status = status;
		running = false;
		this.pid = -1;
		lock (loop)
		{
			if (loop != null && loop.is_running())
				loop.quit();
		}
		exited();
	}
	
	private bool on_loop_timeout()
	{
		lock (loop)
		{
			if (loop != null && loop.is_running())
			{
				loop_result = false;
				loop_timeout = 0;
				loop.quit();
			}
		}
		return false;
	}
}

} // namespace Diorite
