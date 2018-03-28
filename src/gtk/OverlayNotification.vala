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

using Drt;

namespace Drtgtk {

public class OverlayNotification : Gtk.Revealer {
	private static Quark response_id_quark;
	public Gtk.Grid content_area {get; construct;}
	public Gtk.Grid button_area {get; construct;}

	static construct {
		response_id_quark = GLib.Quark.from_string("OverlayNotification.response_id");
	}

    public OverlayNotification(string? text) {
		var content_area = new Gtk.Grid();
		content_area.orientation = Gtk.Orientation.HORIZONTAL;
		content_area.hexpand = content_area.vexpand = true;
		content_area.halign = content_area.valign = Gtk.Align.FILL;
		var button_area = new Gtk.Grid();
		button_area.orientation = Gtk.Orientation.HORIZONTAL;
		button_area.vexpand = true;
		button_area.hexpand = false;
		button_area.halign = button_area.valign = Gtk.Align.FILL;
		GLib.Object(content_area: content_area, button_area: button_area);
        var frame = new Gtk.Frame(null);
        base.add(frame);
		var grid = new Gtk.Grid();
		grid.orientation = Gtk.Orientation.HORIZONTAL;
		grid.column_spacing = grid.row_spacing = 10;
		frame.add(grid);
		frame.get_style_context().add_class("app-notification");
		grid.add(content_area);
		grid.add(button_area);
        
        transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
		hexpand = vexpand = false;
		hexpand = true;
		halign = Gtk.Align.CENTER;
		valign = Gtk.Align.START;
        
        var button = new Gtk.Button.from_icon_name("window-close-symbolic");
		button.set_qdata<int>(response_id_quark, Gtk.ResponseType.CLOSE);
		button.clicked.connect(on_button_clicked);
		button.hexpand = false;
		button.vexpand = true;
		button.halign = Gtk.Align.END;
		button.valign = Gtk.Align.CENTER;
		grid.add(button);
		
		if (text != null) {
			add_child(Drtgtk.Labels.plain(text, true));
		}

		frame.show_all();
    }
	
    public virtual signal void response(int response_id) {
	}

    public void reveal() {
		show();
		reveal_child = true;
	}

    public unowned Gtk.Button add_button(string label, int response_id) {
		var button = new Gtk.Button.with_label(label);
		button.set_qdata<int>(response_id_quark, response_id);
		button.clicked.connect(on_button_clicked);
		button.hexpand = false;
		button.vexpand = true;
		button.halign = Gtk.Align.END;
		button.valign = Gtk.Align.CENTER;
		button_area.add(button);
		button.show();
		unowned Gtk.Button tmp = button;
		return tmp;
	}

	public override void add(Gtk.Widget widget) {
		add_child(widget);
	}

	public void add_child(Gtk.Widget widget) {
		widget.vexpand = true;
		widget.valign = Gtk.Align.CENTER;
		widget.show();
		content_area.add(widget);
	}

	public override void remove(Gtk.Widget widget) {
		content_area.remove(widget);
	}

	private void on_button_clicked(Gtk.Button button) {
		response(button.get_qdata<int>(response_id_quark));
	}
}

} // namespace Drtgtk
