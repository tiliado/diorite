/*
 * Copyright 2018 Jiří Janoušek <janousek.jiri@gmail.com>
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

using Drt;

namespace Drtgtk {

/**
 * Arrow button used to switch {@link Gtk.Stack} pages in one direction.
 */
public class StackArrow : Gtk.Button {
	private Gtk.PositionType _position = Gtk.PositionType.LEFT;
	[Description(nick = "The direction of the arrow.", blurb = "{@link Gtk.PositionType.LEFT} and {@link Gtk.PositionType.TOP} go to he previous page, {@link Gtk.PositionType.RIGHT} and {@link Gtk.PositionType.BOTTOM} go to the next page.")]
	public Gtk.PositionType position {
		get {return _position;}
		construct set {
			this._position = value;
			var image = get_child() as Gtk.Image;
			if (image != null) {
				image.icon_name = Icons.get_icon_name_for_position(value);
			}
		}
	}
	[Description(nick = "The stack to control.")]
	public Gtk.Stack? stack {get; set; default = null;}

	/**
	 * Create new Stack Arrow button.
	 *
	 * It switches pages depending on the `position`. {@link Gtk.PositionType.LEFT} and {@link Gtk.PositionType.TOP}
	 * go to he previous page, {@link Gtk.PositionType.RIGHT} and {@link Gtk.PositionType.BOTTOM} go to the next
	 * page.
	 *
	 * @param position    The position of the button. It affects the direction of page switching and the side
	 *                    the arrow is pointing to.
	 * @param stack       {@link Gtk.Stack} to control.
	 * @param relief      Whether to show relief around the button. Disabled by default.
	 */
	public StackArrow(Gtk.PositionType position, Gtk.Stack? stack=null, bool relief=false) {
		GLib.Object(
			position: position, relief: relief ? Gtk.ReliefStyle.NORMAL : Gtk.ReliefStyle.NONE,
			expand: false, valign: Gtk.Align.CENTER, halign: Gtk.Align.CENTER);
		this.stack = stack;
	}

	construct {
		var image = new Gtk.Image.from_icon_name(Icons.get_icon_name_for_position(_position), Gtk.IconSize.BUTTON);
		image.show();
		add(image);
	}

	public override void clicked() {
		if (stack == null) {
			return;
		}
		Gtk.Widget current = stack.visible_child;
		List<unowned Gtk.Widget> children = stack.get_children();
		if (children == null) {
			return;
		}
		if (current == null) {
			stack.visible_child = children.data;
		} else {
			bool previous = _position == Gtk.PositionType.LEFT || _position == Gtk.PositionType.TOP;
			unowned List<unowned Gtk.Widget> cursor = children;
			while (cursor != null) {
				if (cursor.data == current) {
					if (previous) {
						stack.visible_child = cursor.prev != null ? cursor.prev.data : cursor.last().data;
					} else {
						stack.visible_child = cursor.next != null ? cursor.next.data : cursor.first().data;
					}
					break;
				}
				cursor = cursor.next;
			}
		}
	}
}
	
} // namespace Drtgtk
