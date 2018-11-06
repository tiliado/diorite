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
namespace Drt {

public class KeyValueStorageProxy: KeyValueStorage {
    public KeyValueStorageClient client {get; construct;}
    public string name {get; construct;}

    public KeyValueStorageProxy(KeyValueStorageClient client, string name) {
        GLib.Object(name: name, client: client);
        client.changed.connect(on_changed);
        toggle_listener(true);
    }

    ~KeyValueStorageProxy() {
        client.changed.disconnect(on_changed);
        toggle_listener(false);
    }

    private void on_changed(string provider_name, string key, Variant? old_value) {
        if (provider_name == name) {
            changed(key, old_value);
        }
    }

    public override bool has_key(string key) {
        unowned string method = KeyValueStorageServer.METHOD_HAS_KEY;
        try {
            Variant? response = client.channel.call_sync(method, new Variant("(ss)", name, key));
            if (response.is_of_type(VariantType.BOOLEAN)) {
                return response.get_boolean();
            }
            critical("Invalid response to %s: %s", method,
                response == null ? "null" : response.print(false));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
        return false;
    }

    public override async bool has_key_async(string key) {
        unowned string method = KeyValueStorageServer.METHOD_HAS_KEY;
        try {
            Variant? response = yield client.channel.call(method, new Variant("(ss)", name, key));
            if (response.is_of_type(VariantType.BOOLEAN)) {
                return response.get_boolean();
            }
            critical("Invalid response to %s: %s", method,
                response == null ? "null" : response.print(false));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
        return false;
    }

    protected override Variant? get_value(string key) {
        unowned string method = KeyValueStorageServer.METHOD_GET_VALUE;
        try {
            return unbox_variant(client.channel.call_sync(method, new Variant("(ss)", name, key)));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
            return null;
        }
    }

    protected override async Variant? get_value_async(string key) {
        unowned string method = KeyValueStorageServer.METHOD_GET_VALUE;
        try {
            return unbox_variant(yield client.channel.call(method, new Variant("(ss)", name, key)));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
            return null;
        }
    }

    protected override void set_value_unboxed(string key, Variant? value) {
        unowned string method = KeyValueStorageServer.METHOD_SET_VALUE;
        try {
            client.channel.call_sync(method, new Variant("(ssmv)", name, key, value));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
    }

    protected override async void set_value_unboxed_async(string key, Variant? value) {
        unowned string method = KeyValueStorageServer.METHOD_SET_VALUE;
        try {
            yield client.channel.call(method, new Variant("(ssmv)", name, key, value));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
    }

    protected override void set_default_value_unboxed(string key, Variant? value) {
        unowned string method = KeyValueStorageServer.METHOD_SET_DEFAULT_VALUE;
        try {
            client.channel.call_sync(method, new Variant("(ssmv)", name, key, value));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
    }

    protected override async void set_default_value_unboxed_async(string key, Variant? value) {
        unowned string method = KeyValueStorageServer.METHOD_SET_DEFAULT_VALUE;
        try {
            yield client.channel.call(method, new Variant("(ssmv)", name, key, value));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
    }

    public override void unset(string key) {
        unowned string method = KeyValueStorageServer.METHOD_UNSET;
        try {
            client.channel.call_sync(method, new Variant("(ss)", name, key));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
    }

    public override async void unset_async(string key) {
        unowned string method = KeyValueStorageServer.METHOD_UNSET;
        try {
            yield client.channel.call(method, new Variant("(ss)", name, key));
        } catch (GLib.Error e) {
            critical("%s client error: %s", method, e.message);
        }
    }

    private void toggle_listener(bool state) {
        string method;
        Variant payload;
        if (state) {
            method = KeyValueStorageServer.METHOD_ADD_LISTENER;
            payload = new Variant("(s)", name);
        } else {
            method = KeyValueStorageServer.METHOD_REMOVE_LISTENER;
            payload = new Variant("(s)", name);
        }
        RpcChannel channel = client.channel;
        channel.call.begin(method, payload, (o, res ) => {
            try {
                Variant? response = channel.call.end(res);
                if (response == null || !response.is_of_type(VariantType.BOOLEAN) || !response.get_boolean()) {
                    warning("Invalid response to %s: %s", method, response == null ? "null" : response.print(false));
                }
            } catch (GLib.Error e) {
                critical("%s client error: %s", method, e.message);
            }
        });
    }
}

} // namespace Drt

