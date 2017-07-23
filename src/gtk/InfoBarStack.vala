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

namespace Drt
{

public class InfoBarStack: Gtk.Stack
{
	private Gtk.Button left_button;
	private Gtk.Button right_button;
	
	public InfoBarStack()
	{
		GLib.Object(hexpand: true, transition_type: Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
		notify["visible-child"].connect_after(on_visible_child_changed);
		
		left_button = new Gtk.Button();
		left_button.valign = Gtk.Align.CENTER;
		left_button.expand = false;
		left_button.relief = Gtk.ReliefStyle.NONE;
		left_button.margin_left = 6;
		left_button.no_show_all = true;
		left_button.clicked.connect(() => {go_previous();});
		var img = new Gtk.Image.from_icon_name("go-previous-symbolic", Gtk.IconSize.BUTTON);
		left_button.add(img);
		img.show();
		
		right_button = new Gtk.Button();
		right_button.valign = Gtk.Align.CENTER;
		right_button.expand = false;
		right_button.relief = Gtk.ReliefStyle.NONE;
		right_button.margin_left = 6;
		right_button.no_show_all = true;
		right_button.clicked.connect(() => {go_next();});
		img = new Gtk.Image.from_icon_name("go-next-symbolic", Gtk.IconSize.BUTTON);
		right_button.add(img);
		img.show();
	}
	
	public override void add(Gtk.Widget child)
	{
		return_if_fail(child is Gtk.InfoBar);
		base.add(child);
		child.show();
		visible_child = child;
	}
	
	public override void remove(Gtk.Widget child)
	{
		if (child == visible_child && !go_next())
			go_previous();
		base.remove(child);
		update_arrows();
	}
	
	private void update_arrows()
	{
		var visible_child = this.visible_child;
		var first = get_children();
		unowned List<weak Gtk.Widget> last = first.last();
		left_button.visible = first != null && first.data != visible_child;
		right_button.visible = last != null && last.data != visible_child;
	}
	
	public bool go_previous()
	{
		var children = get_children();
		var visible_child = this.visible_child;
		unowned List<weak Gtk.Widget> cursor = children;
		unowned List<weak Gtk.Widget> next;
		for (var i = 0; cursor != null; i++)
		{
			next = cursor.next;
			if (next != null && next.data == visible_child)
			{
				this.visible_child = cursor.data;
				return true;
			}
			cursor = next;
		}
		return false;
	}
	
	public bool go_next()
	{
		var children = get_children();
		var visible_child = this.visible_child;
		unowned List<weak Gtk.Widget> cursor = children;
		unowned List<weak Gtk.Widget> next;
		for (var i = 0; cursor != null; i++)
		{
			next = cursor.next;
			if (cursor.data == visible_child)
			{
				if (next == null)
					return false;
				this.visible_child = next.data;
				return true;
			}
			cursor = next;
		}
		return false;
	}
	
	/**
	 * Create and show new closable Gtk.InfoBar
	 * 
	 * The info bar has close button and is removed after a response signal.
	 * 
	 * @param text            text of the info bar
	 * @param message_type    type of the info bar
	 * @return a newly created Gtk.InfoBar
	 */
	public Gtk.InfoBar create_info_bar(string text, Gtk.MessageType message_type=Gtk.MessageType.INFO)
	{
		var bar = new Gtk.InfoBar();
		bar.message_type = message_type;
		bar.show_close_button = true;
		var label = new Gtk.Label(text);
		label.hexpand = true;
		bar.get_content_area().add(label);
		bar.show_all();
		bar.response.connect(on_create_info_bar_response);
		add(bar);
		return bar;
	}
	
	private void on_create_info_bar_response(Gtk.InfoBar bar, int response)
	{
		bar.response.disconnect(on_create_info_bar_response);
		remove(bar);
	}
	
	private void on_visible_child_changed(GLib.Object o, ParamSpec p)
	{
		Gtk.Container? parent;
		if ((parent = left_button.get_parent() as Gtk.Container) != null)
			parent.remove(left_button);
		if ((parent = right_button.get_parent() as Gtk.Container) != null)
			parent.remove(right_button);
		update_arrows();
		if (visible_child != null)
		{
			var info_bar = visible_child as Gtk.InfoBar;
			return_if_fail(info_bar != null);
			var box = info_bar.get_action_area().get_parent() as Gtk.Box;
			return_if_fail(box != null);
			box.pack_start(left_button, false, false, 0);
			box.reorder_child(left_button, 0);
			box.pack_start(right_button, false, false, 0);
			box.reorder_child(right_button, 3);
		}
	}
}

} // namespace Drt
