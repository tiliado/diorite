/*
 * Copyright 2016-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

/**
 * Bi-directional channel of a RPC connection.
 */
public class RpcChannel: RpcConnection {
    static construct {
        log_comunication = Environment.get_variable("DIORITE_LOG_MESSAGE_CHANNEL") == "yes";
    }

    public Drt.DuplexChannel channel {get; construct;}
    public bool pending {get; protected set; default = false;}
    public bool closed {get; protected set; default = false;}
    public string name {get {return channel.name;}}
    private static bool log_comunication;

    /**
     * Create new channel from DuplexChannel.
     *
     * @param id           Channel id.
     * @param channel      The channel for i/o.
     * @param router       The RPC router for incoming requests.
     * @param api_token    The token to sign outgoing requests.
     */
    public RpcChannel(uint id, Drt.DuplexChannel channel, RpcRouter? router, string? api_token=null) {
        GLib.Object(id: id, channel: channel, router: router ?? new RpcRouter(), api_token: api_token);
    }

    /**
     * Create new channel for given name.
     *
     * @param id           Channel id.
     * @param name         The name of the channel for i/o.
     * @param router       The RPC router for incoming requests.
     * @param api_token    The token to sign outgoing requests.
     * @throws IOError on failure.
     */
    public RpcChannel.from_name(uint id, string name, RpcRouter? router, string? api_token=null, uint timeout)
    throws IOError {
        this(id, new SocketChannel.from_name(id, name, timeout), router, api_token);
    }

    construct {
        channel.notify["closed"].connect_after(on_channel_closed);
        channel.incoming_request.connect(on_incoming_request);
        channel.start();
    }

    ~RpcChannel() {
        channel.notify["closed"].disconnect(on_channel_closed);
    }

    /**
     * Send remote request asynchronously (non-blocking) with additional options.
     *
     * @param method           Remote method name.
     * @param parameters       Remote method parameters.
     * @param allow_private    Allow calling private methods.
     * @param flags            Remote call flags.
     * @return Remote response.
     * @throws GLib.Error on failure.
     */
    public override async Variant? call_full(string method, Variant? parameters, bool allow_private, string flags)
    throws GLib.Error {
        var method_full = create_full_method_name(method, allow_private, flags, Rpc.get_params_type(parameters));
        var request = serialize_request(method_full, parameters);
        var response = yield channel.send_request_async(request);
        return deserialize_response((owned) response);
    }

    /**
     * Send remote request synchronously (blocking) with additional options..
     *
     * @param method        Remote method name.
     * @param parameters    Remote method parameters.
     * @param allow_private    Allow calling private methods.
     * @param flags            Remote call flags.
     * @return Remote response.
     * @throws GLib.Error on failure.
     */
    public override Variant? call_full_sync(string method, Variant? parameters, bool allow_private, string flags)
    throws GLib.Error {
        var method_full = create_full_method_name(method, allow_private, flags, Rpc.get_params_type(parameters));
        var request = serialize_request(method_full, parameters);
        var response = channel.send_request(request);
        return deserialize_response((owned) response);
    }

    /**
     * Send a response to remote call.
     *
     * @param id          Request id.
     * @param response    The response.
     */
    public override void respond(uint id, Variant? response) {
        send_response(id, Rpc.RESPONSE_OK, response);
    }

    /**
     * Send an error to remote call.
     *
     * @param id    Request id.
     * @param e     The error.
     */
    public override void fail(uint id, GLib.Error e) {
        send_response(id, Rpc.RESPONSE_ERROR, serialize_error(e));
    }

    /**
     * Send response to remote call (low-level).
     *
     * @param id          Request id.
     * @param status      Response status.
     * @param response    Response data.
     */
    protected void send_response(uint id, string status, Variant? response) {
        var buffer = serialize_message(status, response, 0);
        var payload = new ByteArray.take((owned) buffer);
        try {
            channel.send_response(id, payload);
        } catch (GLib.Error e) {
            warning("Failed to send response: %s", e.message);
        }
    }

    /**
     * Serialize request to byte array.
     *
     * @param name    Request name.
     * @param parameters    Request parameters.
     * @return Serialized request as byte array.
     */
    private ByteArray? serialize_request(string name, Variant? parameters) {
        if (log_comunication) {
            debug("Channel(%u) Request: %s => %s",
                channel.id, name, parameters != null ? parameters.print(false) : "null");
        }
        var buffer = serialize_message(name, parameters, 0);
        return new ByteArray.take((owned) buffer);
    }

    /**
     * Deserialize response from byte array.
     *
     * @param data    Raw response data.
     * @return Deserialized data on success.
     * @throws GLib.Error on failure.
     */
    private Variant? deserialize_response(owned ByteArray? data) throws GLib.Error {
        var bytes = ByteArray.free_to_bytes((owned) data);
        var buffer = Bytes.unref_to_data((owned) bytes);
        string? label = null;
        Variant? parameters = null;
        if (!deserialize_message((owned) buffer, out label, out parameters, 0)) {
            throw new RpcError.INVALID_RESPONSE("Server returned invalid response. Cannot deserialize message.");
        }
        if (log_comunication) {
            debug("Channel(%u) Response #%u: %s => %s",
                channel.id, id, label, parameters != null ? parameters.print(false) : "null");
        }
        if (label == Rpc.RESPONSE_OK) {
            return parameters;
        }
        if (label == Rpc.RESPONSE_ERROR) {
            if (parameters == null) {
                throw new RpcError.INVALID_RESPONSE("Server returned empty error.");
            }
            var e = deserialize_error(parameters);
            if (e == null) {
                throw new RpcError.UNKNOWN("Server returned unknown error.");
            }
            throw new RpcError.REMOTE_ERROR("%s[%d]: %s.", e.domain.to_string(), e.code, e.message);
        }
        throw new RpcError.INVALID_RESPONSE("Server returned invalid response status '%s'.", label);
    }

    /**
     * Close the channel.
     *
     * @return true if channel has been closed.
     */
    public bool close() {
        var result = true;
        try {
            channel.close();
        } catch (GLib.IOError e) {
            warning("Failed to close channel '%s': [%d] %s", name, e.code, e.message);
            result = false;
        }
        if (closed == false) {
            closed = true;
        }
        return result;
    }

    /**
     * Handle incoming request
     *
     * @param id            request id
     * @param data          raw request data
     */
    private void on_incoming_request(uint id, owned ByteArray? data) {
        string? name = null;
        Variant? parameters = null;
        var bytes = ByteArray.free_to_bytes((owned) data);
        var buffer = Bytes.unref_to_data((owned) bytes);
        if (!deserialize_message((owned) buffer, out name, out parameters, 0)) {
            warning("Server sent invalid request. Cannot deserialize message.");
            return;
        }
        if (log_comunication) {
            debug("Channel(%u) Handle request: %s => %s",
                channel.id, name, parameters != null ? parameters.print(false) : "null");
        }
        try {
            router.handle_request(this, id, name, parameters);
        } catch (GLib.Error e) {
            fail(id, e);
        }
    }

    private void on_channel_closed(GLib.Object o, ParamSpec p) {
        if (closed != channel.closed) {
            closed = channel.closed;
        }
    }

    private string create_full_method_name(string name, bool allow_private, string flags,
        string params_format) {
        return "%s::%s%s,%s,%s".printf(
            name, allow_private ? "p" : "",
            flags, params_format,
            allow_private && api_token != null ? api_token : "");
    }
}

} // namespace Drt
