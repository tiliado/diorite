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
		string[] argv = {args[0], "Hello", "the", "best", "world", "ever!"};
		message("New subprocess: %s", args[0]);
		try
		{
			var process = new Diorite.Subprocess(argv, Diorite.SubprocessFlags.NONE);
			message("Waiting 0.5 s");
			message("Result: %s", process.wait(500).to_string());
			message("Kill!");
			process.force_exit();
			message("Waiting forever");
			message("Result: %s", process.wait().to_string());
			message("Status: %d", process.status);
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return 1;
		}
		
		try
		{
			var process = new Diorite.Subprocess(argv, Diorite.SubprocessFlags.NONE);
			message("Waiting 0.5 s");
			message("Result: %s", process.wait(500).to_string());
			message("Waiting forever");
			message("Result: %s", process.wait().to_string());
			message("Status: %d", process.status);
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return 1;
		}
		
		try
		{
			var process = new Diorite.Subprocess(argv, Diorite.SubprocessFlags.NONE);
			message("Waiting 0.5 s");
			message("Result: %s", process.wait(500).to_string());
			message("Waiting forever");
			message("Result: %s", process.wait().to_string());
			message("Status: %d", process.status);
		}
		catch (GLib.Error e)
		{
			critical("Error: %s", e.message);
			return 1;
		}
		
	}
	return 0;
}
