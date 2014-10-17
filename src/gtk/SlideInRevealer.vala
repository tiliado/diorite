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

namespace Diorite
{

/**
 * This widget contains arrow button to slide in/hide its child.
 */
public class SlideInRevealer: Gtk.Box
{
	public Gtk.Revealer revealer {get; construct;}
	public Gtk.Arrow arrow {get; private set;}
	public Gtk.EventBox button {get; private set;}
	
	public SlideInRevealer(Gtk.Revealer? revealer=null)
	{
		GLib.Object(
			revealer: revealer ?? new Gtk.Revealer(),
			orientation: Gtk.Orientation.VERTICAL,
			spacing: 0);
		if (revealer == null)
			this.revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
	}
	
	construct
	{
		arrow = new Gtk.Arrow(Gtk.ArrowType.DOWN, Gtk.ShadowType.NONE);
		arrow.set_padding(0, 0);
		arrow.margin = 0;
		arrow.opacity = 0.7;
		
		button =  new Gtk.EventBox();
		button.override_background_color(Gtk.StateFlags.PRELIGHT, {1.0, 1.0, 1.0, 0.4});
		button.button_press_event.connect(on_button_press_event);
		button.enter_notify_event.connect(on_enter_notify_event);
		button.leave_notify_event.connect(on_leave_notify_event);
		
		button.add(arrow);
		base.add(revealer);
		base.pack_end(button, false, true, 0);
		revealer.notify["reveal-child"].connect_after(on_reveal_child_changed);
		revealer.show();
		button.show_all();
	}
	
	public override void add(Gtk.Widget child)
	{
		revealer.add(child);
	}
	
	public override void remove(Gtk.Widget child)
	{
		if (revealer.get_child() == child)
			revealer.remove(child);
		else
			base.remove(child);
	}
	
	public void toggle()
	{
		revealer.reveal_child = !revealer.reveal_child;
	}
	
	private bool on_button_press_event(Gdk.EventButton event)
	{
		toggle();
		return true;
	}
	
	private void on_reveal_child_changed(GLib.Object o, ParamSpec p)
	{
		arrow.arrow_type = revealer.reveal_child ? Gtk.ArrowType.UP : Gtk.ArrowType.DOWN;
	}
	
	private bool on_enter_notify_event(Gdk.EventCrossing event)
	{
		arrow.opacity = 1.0;
		button.set_state_flags(button.get_state_flags() | Gtk.StateFlags.PRELIGHT, true);
		return false;
	}
	
	private bool on_leave_notify_event(Gdk.EventCrossing event)
	{
		arrow.opacity = 0.7;
		button.set_state_flags(button.get_state_flags() & ~Gtk.StateFlags.PRELIGHT, true);
		return false;
	}
}

} // namespace Diorite
