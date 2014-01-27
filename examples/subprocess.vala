/* 
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

int main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	message("Process started: %s", args[0]);
	var size = args.length;
	if (size > 1)
	{
		for (var i = 1; i < size; i++)
		{
			Posix.sleep(1);
			debug("%d: '%s'", i, args[i]);
		}
	}
	else
	{
		string[] argv = {"notepad", "Hello", "the", "best", "world", "ever!"};
		message("New subprocess: %s",argv[0]);
		try
		{
			var process = new Diorite.Subprocess(argv, Diorite.SubprocessFlags.NONE);
			message("Waiting 1 s");
			message("Result: %s", process.wait(1000).to_string());
			message("Try to exit.");
			process.exit();
			message("Waiting 5 s");
			message("Result: %s", process.wait(5000).to_string());
			
			if(process.running)
			{
				message("Kill!");
				process.force_exit();
			}
			message("Waiting forever");
			message("Result: %s", process.wait().to_string());
			message("Status: %d", process.status);
			
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return 1;
		}
		argv[0] = args[0];
		try
		{
			var process = new Diorite.Subprocess(argv, Diorite.SubprocessFlags.NONE);
			message("Waiting 2 s");
			message("Result: %s", process.wait(2000).to_string());
			message("Try to exitcleanly");
			process.exit();
			message("Waiting 2 s");
			message("Result: %s", process.wait(2000).to_string());
			if(process.running)
			{
				message("Kill!");
				process.force_exit();
			}
			message("Waiting forever");
			message("Result: %s", process.wait().to_string());
			message("Status: %d", process.status);
			return 0;
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return 1;
		}
	}
	return 0;
}
