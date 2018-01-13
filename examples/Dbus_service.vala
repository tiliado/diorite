
[DBus (name = "org.example.Demo")]
public class DemoServer : GLib.Object {

    private int counter;

    public int ping(string msg) {
        stdout.printf("%s\n", msg);
        return counter++;
    }
    
    public int slow_ping(string msg, uint sleep_ms) {
		stdout.printf("sleep %u ms\n", sleep_ms);
		Thread.usleep(sleep_ms * 1000);
        stdout.printf("%s\n", msg);
        return counter++;
    }

    public int ping_with_signal(string msg) {
        stdout.printf("%s\n", msg);
        pong(counter, msg);
        return counter++;
    }

    public int ping_with_sender(string msg, GLib.BusName sender) {
        stdout.printf ("%s, from: %s\n", msg, sender);
        return counter++;
    }


    public signal void pong(int count, string msg);
}

void on_bus_aquired(DBusConnection conn) {
    try {
        conn.register_object ("/org/example/demo", new DemoServer());
    } catch (IOError e) {
        stderr.printf ("Could not register service\n");
    }
}

void main() {
    Bus.own_name(BusType.SESSION, "org.example.Demo", BusNameOwnerFlags.NONE,
                  on_bus_aquired,
                  () => {},
                  () => stderr.printf ("Could not aquire name\n"));

    new MainLoop().run();
}
