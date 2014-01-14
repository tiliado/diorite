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

/**
 * Logger for GLib
 */
public class Logger
{
	private static GLib.LogLevelFlags display_level;
	private static unowned FileStream output;
	
	/**
	 * Initializes new logger for GLib
	 * 
	 * @param output           output to write logger messages to (e. g. sys.stderr)
	 * @param display_level    lowest log level to log
	 */
	public static void init(FileStream output, GLib.LogLevelFlags display_level=GLib.LogLevelFlags.LEVEL_DEBUG)
	{
		Logger.output = output;
		Logger.display_level = display_level;
		GLib.Log.set_default_handler(Logger.log_handler);
	}
	
	/**
	 * Prints message to log
	 * 
	 * @param format    message format
	 */
	[PrintfFormat]
	public static void printf(string format, ...)
	{
		lock (output)
		{
			output.vprintf(format, va_list());
			output.flush();
			output.flush();
		}
	}
	
	/**
	 * Prints line to log
	 * 
	 * @param line    line to log
	 */
	public static void log(string line)
	{
		lock (output)
		{
			output.puts(line);
			output.flush();
		}
	}
	
	private static void log_handler(string? domain, LogLevelFlags level, string message)
	{
		if (level > Logger.display_level)
			return;
		
		print(domain ?? "<unknown>", level, message);
		
		switch ((int)level)
		{
		case LogLevelFlags.LEVEL_ERROR:
		case 6:
			print(domain ?? "<unknown>", level, "Application will be terminated.");
			break;
		case LogLevelFlags.LEVEL_CRITICAL:
			print(domain ?? "<unknown>", level, "Application will not function properly.");
			break;
		}
	}
	
	private static void print(string domain, LogLevelFlags level, string message)
	{
		string name = "";
		switch ((int)level)
		{
		case LogLevelFlags.LEVEL_CRITICAL:
			name = "CRITICAL";
			break;
		case LogLevelFlags.LEVEL_ERROR:
		case 6:
			name = "ERROR";
			break;
		case LogLevelFlags.LEVEL_WARNING:
			name = "WARNING";
			break;
		case LogLevelFlags.LEVEL_MESSAGE:
		case LogLevelFlags.LEVEL_INFO:
			name = "INFO";
			break;
		case LogLevelFlags.LEVEL_DEBUG:
			name = "DEBUG";
			break;
		case LogLevelFlags.LEVEL_MASK:
			name = "MASK";
			break;
		case LogLevelFlags.FLAG_RECURSION:
			name = "Recursion";
			break;
		case LogLevelFlags.FLAG_FATAL:
			name = "Fatal";
			break;
		default:
			name = "Unknown";
			break;
		}
		
		lock (output)
		{
			output.printf("[%-8s %5s] %s\n", name, domain, message);
			output.flush();
		}
	}
}

} // namespace Diorite
