
[DBus (name = "org.example.Demo")]
public interface Demo : GLib.Object {
    public abstract int ping(string msg) throws IOError;
    public abstract int slow_ping(string msg, uint sleep_ms) throws IOError;
    public abstract int ping_with_signal(string msg) throws IOError;
    public abstract int ping_with_sender (string msg) throws IOError;
    public signal void pong(int count, string msg);
}


void main () {
    var loop = new MainLoop();
    Demo demo = null;
    try {
        demo = Bus.get_proxy_sync(BusType.SESSION, "org.example.Demo", "/org/example/demo");

        demo.pong.connect((c, m) => {
            stdout.printf("Got pong %d for msg '%s'\n", c, m);
            loop.quit();
        });

        var reply = demo.ping("Hello from Vala");
        stdout.printf("%d\n", reply);
        reply = demo.ping_with_sender("Hello from Vala with sender");
        stdout.printf("%d\n", reply);
        reply = demo.ping_with_signal("Hello from Vala with signal");
        stdout.printf("%d\n", reply);
        try {
			reply = demo.slow_ping("Slow ping", 30*1000);
			stdout.printf("%d\n", reply);
		} catch (IOError e2) {
			if (e2 is GLib.IOError.TIMED_OUT) {
				stdout.printf("Slow ping timed out\n");
			} else {
				throw e2;
			}
		}

    } catch (IOError e) {
        stderr.printf("%s\n", e.message);
    }
    loop.run();
}
