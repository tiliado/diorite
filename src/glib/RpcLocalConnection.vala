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
 * Local Rpc Connection is used to call {@link RpcRouter} methods from the same process.
 */
public class RpcLocalConnection: RpcConnection {
    private static bool log_comunication;
    private uint last_payload_id = 0;
    private HashTable<void*, Response?> pending_requests;

    static construct {
        log_comunication = Environment.get_variable("DIORITE_LOG_MESSAGE_CHANNEL") == "yes";
    }

    /**
     * Create new RpcLocalConnection.
     *
     * @param id    Channel id.
     * @param router    RpcRouter for requests to perform.
     * @param api_token    The token to sign requests.
     */
    public RpcLocalConnection(uint id, RpcRouter? router, string? api_token=null) {
        GLib.Object(id: id, router: router ?? new RpcRouter(), api_token: api_token);
        pending_requests = new HashTable<void*, Response?>(direct_hash, direct_equal);
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
        string method_full = create_full_method_name(method, allow_private, flags, Rpc.get_params_type(parameters));
        MainContext ctx = MainContext.ref_thread_default();
        assert(ctx.is_owner());
        uint id = dispatch_request(method_full, parameters, (ResumeCallback) call_full.callback, ctx);
        yield;
        assert(ctx.is_owner());
        return get_response(id);
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
        string method_full = create_full_method_name(method, allow_private, flags, Rpc.get_params_type(parameters));
        MainContext ctx = MainContext.ref_thread_default();
        var loop = new MainLoop(ctx);
        uint id = dispatch_request(method_full, parameters, loop.quit, ctx);
        loop.run();
        return get_response(id);
    }

    /**
     * Dispatch local request
     *
     * @param method      RPC method to call.
     * @param parameters  Method parameters.
     * @param callback    The callback to call when response is received.
     * @param ctx         MainContext to execute the callback in.
     * @return Request id to be passed to {@link get_response}.
     */
    private uint dispatch_request(string method, Variant? parameters, owned ResumeCallback callback,
        MainContext ctx) {
        Response response;
        uint id;
        lock (last_payload_id) {
            lock (pending_requests) {
                id = last_payload_id;
                do {
                    if (id == uint.MAX) {
                        id = 1;
                    } else {
                        id++;
                    }
                }
                while (pending_requests.contains(id.to_pointer()));
                last_payload_id = id;
                response = new Response(id, (owned) callback, ctx);
                pending_requests[id.to_pointer()] = response;
            }
        }
        if (log_comunication) {
            debug("Channel(%u) Handle local request (%u): %s => %s",
                this.id, id, method, parameters != null ? parameters.print(false) : "null");
        }
        try {
            router.handle_request(this, id, method, parameters);
        } catch (GLib.Error e) {
            fail(id, e);
        }
        return id;
    }

    /**
     * Send a response to remote call.
     *
     * @param id          Request id.
     * @param response    The response.
     */
    public override void respond(uint id, Variant? response) {
        Response? resp = find_response(id);
        assert(resp != null);
        resp.response = response;
        resp.schedule_callback();
    }

    /**
     * Send an error to remote call.
     *
     * @param id    Request id.
     * @param e     The error.
     */
    public override void fail(uint id, GLib.Error e) {
        Response? resp = find_response(id);
        assert(resp != null);
        resp.error = e;
        resp.schedule_callback();
    }

    private string create_full_method_name(string name, bool allow_private, string flags,
        string params_format) {
        return "%s::%s%s,%s,%s".printf(
            name, allow_private ? "p" : "",
            flags, params_format,
            allow_private && api_token != null ? api_token : "");
    }

    /**
     * Find response by id.
     *
     * @param id    Response id.
     * @return Response if it is found, null otherwise.
     */
    private Response? find_response(uint id) {
        Response? resp;
        lock (pending_requests) {
            resp = pending_requests[id.to_pointer()];
        }
        return resp;
    }

    /**
     * Get response by id and remove it from queue.
     *
     * @param id    Response id.
     * @return Data of the response if it is found.
     * @throws GLib.Error if the response has not been found or it ended with an error.
     */
    private Variant? get_response(uint id) throws GLib.Error {
        Response? resp;
        lock (pending_requests) {
            resp = pending_requests.get(id.to_pointer());
            pending_requests.remove(id.to_pointer());
        }
        if (resp == null) {
            throw new GLib.IOError.NOT_FOUND("Response with id %u has not been found.", id);
        } else if (resp.error != null) {
            throw resp.error;
        } else {
            return resp.response;
        }
    }

    /**
     * Callback to be called when response is received.
     */
    public delegate void ResumeCallback();

    private class Response {
        public uint id;
        public Variant? response = null;
        public GLib.Error? error = null;
        private ResumeCallback? callback = null;
        private MainContext? ctx;

        public Response(uint id, owned ResumeCallback? callback, MainContext? ctx) {
            this.id = id;
            this.response = null;
            this.callback = (owned) callback;
            this.ctx = ctx;
            assert(callback == null || ctx != null);
        }

        public void schedule_callback() {
            assert(this.callback != null);
            EventLoop.add_idle(idle_callback, Priority.HIGH_IDLE, ctx);
        }

        private bool idle_callback() {
            this.callback();
            return false;
        }
    }
}

} // namespace Drt
