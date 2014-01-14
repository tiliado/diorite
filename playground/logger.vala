void main(string[] args)
{
	Diorite.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	var me = args[0];
	debug("Debug: %s", me);
	message("Info: %s", me);
	warning("Warning: %s", me);
	critical("Critical warning: %s", me);
	error("Fatal error: %s", me);
}
