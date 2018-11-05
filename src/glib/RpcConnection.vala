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
 * RPC Connection
 */
public abstract class RpcConnection: GLib.Object {
    public RpcRouter router {get; construct;}
    public uint id {get; construct;}
    public string? api_token {protected get; set; default = null;}

    /**
     * Send remote request asynchronously (non-blocking).
     *
     * @param method        Remote method name.
     * @param parameters    Remote method parameters.
     * @return Remote response.
     * @throws GLib.Error on failure.
     */
    public async Variant? call(string method, Variant? parameters) throws GLib.Error	{
        return yield call_full(method, parameters, true, "rw");
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
    public abstract async Variant? call_full(string method, Variant? parameters, bool allow_private, string flags)
    throws GLib.Error;

    /**
     * Send remote request synchronously (blocking).
     *
     * @param method        Remote method name.
     * @param parameters    Remote method parameters.
     * @return Remote response.
     * @throws GLib.Error on failure.
     */
    public Variant? call_sync(string method, Variant? parameters) throws GLib.Error {
        return call_full_sync(method, parameters, true, "rw");
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
    public abstract Variant? call_full_sync(string method, Variant? parameters, bool allow_private, string flags)
    throws GLib.Error;

    /**
     * Subscribe to notification.
     *
     * @param notification    Notification path.
     * @param detail          Reserved for future use, pass `null`.
     * @throws GLib.Error on failure
     */
    public async void subscribe(string notification, string? detail=null) throws GLib.Error	{
        yield call_full(notification, new Variant("(bms)", true, detail), true, "ws");
    }

    /**
     * Unsubscribe from notification.
     *
     * @param notification    Notification path.
     * @param detail          Reserved for future use, pass `null`.
     * @throws GLib.Error on failure
     */
    public async void unsubscribe(string notification, string? detail=null) throws GLib.Error {
        yield call_full(notification, new Variant("(bms)", false, detail), true, "ws");
    }

    /**
     * Send a response to remote call.
     *
     * @param id          Request id.
     * @param response    The response.
     */
    public abstract void respond(uint id, Variant? response);

    /**
     * Send an error to remote call.
     *
     * @param id    Request id.
     * @param e     The error.
     */
    public abstract void fail(uint id, GLib.Error e);
}

} // namespace Drt
