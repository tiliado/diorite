/*
 * Copyright 2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt.EventLoop
{

/**
 * Pause async method and resume it later.
 */
public async void resume_later()
{
	add_idle(resume_later.callback);
	yield;
}

/**
 * Attach an idle callback to the thread-default {@link GLib.MainContext}.
 * 
 * Similar to {@link GLib.Idle.add} but uses the thread-default {@link GLib.MainContext} instead of the global
 * {@link GLib.MainContext} if context is not specified.
 * 
 * @param function    The idle callback function.
 * @param priority    The priority of the callback.
 * @param context        The context to use instead of the thread-default one.
 * @return Id of the corresponding event source.
 */
public uint add_idle(owned SourceFunc function, int priority=GLib.Priority.DEFAULT_IDLE,
MainContext? context=null) {
	var source = new IdleSource();
	source.set_priority(priority);
	source.set_callback((owned) function);
	return source.attach(context ?? MainContext.ref_thread_default());
}

/**
 * Attach a timeout callback to the thread-default {@link GLib.MainContext}.
 * 
 * Similar to {@link GLib.Timeout.add} but uses the thread-default {@link GLib.MainContext} instead of the global
 * {@link GLib.MainContext} if context is not specified.
 * 
 * @param interval_ms    The number of miliseconds to wait before the callback is called.
 * @param function       The callback function.
 * @param priority       The priority of the callback.
 * @param context        The context to use instead of the thread-default one.
 * @return Id of the corresponding event source.
 */
public uint add_timeout_ms(uint interval_ms, owned SourceFunc function, int priority=GLib.Priority.DEFAULT,
MainContext? context=null) {
	var source = new TimeoutSource(interval_ms);
	source.set_priority(priority);
	source.set_callback((owned) function);
	return source.attach(context ?? MainContext.ref_thread_default());
}

/**
 * Attach a timeout callback to the thread-default {@link GLib.MainContext}.
 * 
 * Similar to {@link GLib.Timeout.add_seconds} but uses the thread-default {@link GLib.MainContext} instead
 * of the global {@link GLib.MainContext} if context is not specified.
 * 
 * @param interval_s    The number of seconds to wait before the callback is called.
 * @param function      The callback function.
 * @param priority      The priority of the callback.
 * @param context        The context to use instead of the thread-default one.
 * @return Id of the corresponding event source.
 */
public uint add_timeout_sec(uint interval_s, owned SourceFunc function, int priority=GLib.Priority.DEFAULT,
MainContext? context=null) {
	return add_timeout_ms(interval_s * 1000, (owned) function, priority, context);
}

} // namespace Drt.EventLoop
