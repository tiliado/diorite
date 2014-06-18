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

private const string G_LOG_DOMAIN="DioriteGlib";
namespace Diorite
{

/**
 * Logger for GLib
 */
public class Logger
{
	private static GLib.LogLevelFlags display_level;
	private static unowned FileStream output;
	private static bool colorful;
	
	public static const int COLOR_FOREGROUND = 30;
	public static const int COLOR_BACKGROUND = 40;
	public static const int COLOR_BLACK = 0;
	public static const int COLOR_RED = 1;
	public static const int COLOR_GREEN = 2;
	public static const int COLOR_YELLOW = 3;
	public static const int COLOR_BLUE = 4;
	public static const int COLOR_MAGENTA = 5;
	public static const int COLOR_CYAN = 6;
	public static const int COLOR_WHITE = 7;
	
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
		var use_colors = Environment.get_variable("DIORITE_LOGGER_USE_COLORS");
		if (use_colors == "yes")
		{
			colorful = true;
		}
		else if (use_colors == "no")
		{
			colorful = false;
		}
		else
		{
			colorful = colors_supported();
			// For subprocesses (they might have redirected output)
			Environment.set_variable("DIORITE_LOGGER_USE_COLORS", colorful ? "yes" : "no", false);
		}
		
		GLib.Log.set_default_handler(Logger.log_handler);
	}
	
	public static bool colors_supported()
	{
		#if LINUX
			return Posix.isatty(output.fileno());
		#else
			return false;
		#endif
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
		var color = -1;
		switch ((int)level)
		{
		case LogLevelFlags.LEVEL_CRITICAL:
			name = "CRITICAL";
			color = COLOR_RED;
			break;
		case LogLevelFlags.LEVEL_ERROR:
		case 6:
			name = "ERROR";
			color = COLOR_RED;
			break;
		case LogLevelFlags.LEVEL_WARNING:
			name = "WARNING";
			color = COLOR_YELLOW;
			break;
		case LogLevelFlags.LEVEL_MESSAGE:
		case LogLevelFlags.LEVEL_INFO:
			name = "INFO";
			color = COLOR_GREEN;
			break;
		case LogLevelFlags.LEVEL_DEBUG:
			name = "DEBUG";
			color = COLOR_BLUE;
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
			if (Logger.colorful && color >= 0)
				output.printf("\x1b[%dm[%-8s %5s]\x1b[0m %s\n", COLOR_FOREGROUND + color, name, domain, message);
			else
				output.printf("[%-8s %5s] %s\n", name, domain, message);
			output.flush();
		}
	}
}

} // namespace Diorite
