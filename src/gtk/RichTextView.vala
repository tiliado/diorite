/*
 * Copyright 2012-2015 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drtgtk
{

public delegate void UriOpener(string uri);

/**
 * Simple Document View is supposed to properly display content of SimpleDocBuffer.
 * 
 * It understands all formating tags of SimpleDocBuffer, sets proper link color and
 * manages link actions (changes cursor and emits link_clicked signal).
 */
public class RichTextView: Gtk.TextView
{
	private UriOpener? _link_opener = null;
	public void set_link_opener(owned UriOpener? opener) {
		_link_opener = (owned) opener;
	}

	private UriOpener? _image_opener {get; owned set;}
	public void set_image_opener(owned UriOpener? opener) {
		_image_opener = (owned) opener;
	}
	
	private Gdk.Cursor? cursor = null;
	
	
	public static void default_opener(string uri)
	{
		try
		{
			Gtk.show_uri(null, uri, Gdk.CURRENT_TIME);
		}
		catch (GLib.Error e)
		{
			critical("Failed to open URI '%s'. %s", uri, e.message);
		}
	}
	
	/**
	 * Creates new SimpleDocView.
	 */
	public RichTextView(RichTextBuffer? buffer=null)
	{
		Object(editable: false, wrap_mode: Gtk.WrapMode.WORD);
		_link_opener = default_opener;
		_image_opener = default_opener;
		this.buffer = buffer ?? new RichTextBuffer();
	}
	
	/**
	 * Emitted when a link is clicked. The default handler opens the link
	 * via link_opener field.
	 * 
	 * @param uri    target URI of the link
	 */
	public virtual signal void link_clicked(string uri)
	{
		debug("Open link: %s", uri);
		if (_link_opener != null)
			_link_opener(uri);
	}
	
	/**
	 * Emitted when an image is clicked. The default handler opens the image
	 * via image_opener field.
	 * 
	 * @param path    path of the image
	 */
	public virtual signal void image_clicked(string path)
	{
		debug("Open image: %s", path);
		if (_image_opener != null)
			_image_opener(path);
	}
	
	public override void realize()
	{
		base.realize();
		set_link_color();
	}
	
	public override void style_updated(){
		base.style_updated();
		if (get_realized())
			set_link_color();
	}
	
	private void set_link_color()
	{
		Gdk.RGBA? link_color = null;
		var doc_buffer = buffer as RichTextBuffer;
		if (doc_buffer == null)
			return;
		
		if (!get_style_context().lookup_color("link-color", out link_color)
		&& !get_style_context().lookup_color("link_color", out link_color))
		{
			link_color = null;  // Clear link color
			var prop = find_style_property("link-color");
			if (prop != null)
			{
				unowned Gdk.Color? color = null;
				style_get("link-color", out color);
				if (!prop.value_type.is_a(typeof(Gdk.Color)) && color != null) // See tiliado/nuvolaplayer#197
					link_color = {color.red / 65535.0, color.green / 65535.0, color.blue / 65535.0, 1.0};
			}
		}
		
		if (link_color != null)
			doc_buffer.set_link_color(link_color);
	}
	
	public override bool button_release_event(Gdk.EventButton event)
	{
		var cont = base.button_release_event(event);
		if (event.button == 1)
		{
			int x, y;
			window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int) event.x, (int) event.y, out x, out y);
			unowned RichTextLink link;
			if (get_link_at_pos(x, y, out link))
			{
				link_clicked(link.uri);
			}
			else
			{
				var pixbuf = get_pixbuf_at_pos(x, y);
				if (pixbuf != null)
				{
					var path = pixbuf.get_data<string?>(RichTextBuffer.IMAGE_PATH);
					if (path != null)
						image_clicked(path);
				}
			}
		}
		return cont;
	}
	
	/**
	 * Get link at given position
	 * 
	 * @param x       x coordinate
	 * @param y       y coordinate
	 * @param link    link when found
	 * @return true if a link has been found
	 */
	public bool get_link_at_pos(int x, int y, out unowned RichTextLink link)
	{
		link = null;
		Gtk.TextIter iter;
		get_iter_at_location(out iter, x, y);
		foreach (weak Gtk.TextTag tag in iter.get_tags())
		{
			weak RichTextLink? maybe_link = tag as RichTextLink;
			if (maybe_link != null)
			{
				link = maybe_link;
				return true;
			}
		}
		return false;
	}
	
	/**
	 * Check whether position is inside iter area.
	 * 
	 * @param iter    iter
	 * @param x       x coordinate
	 * @param y       y coordinate
	 * @return true if (x, y) is inside area of iter
	 */
	public bool is_in_iter_area(Gtk.TextIter iter, int x, int y)
	{
		Gdk.Rectangle area;
		get_iter_location(iter, out area);
		return x >= area.x && x <= area.x + area.width
		&& y >= area.y && y <= area.y + area.height;
	}
	
	/**
	 * Get pixbuf at given position.
	 * 
	 * @param x    coordinate x
	 * @param y    coordinate y
	 * @return pixbuf if found, null otherwise
	 */
	public Gdk.Pixbuf? get_pixbuf_at_pos(int x, int y)
	{
		Gtk.TextIter iter;
		get_iter_at_location(out iter, x, y);
		var pixbuf = iter.get_pixbuf();
		if (pixbuf != null && is_in_iter_area(iter, x, y))
			return pixbuf;
		
		/* When mouse cursor in over the second half of a pixbuf, iter on the right hand side
		 * is returned instead the right one, so we have to go backward and
		 * check a pixbuf presence again. */
		 
		iter.backward_char();
		pixbuf = iter.get_pixbuf();
		if (pixbuf != null && is_in_iter_area(iter, x, y))
			return pixbuf;
		
		return null;
	}
	
	public override bool motion_notify_event(Gdk.EventMotion event)
	{
		var cont = base.motion_notify_event(event);
		int x, y;
		window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int) event.x, (int) event.y, out x, out y);
		update_cursor(x, y);
		return cont;
	}
	
	private void update_cursor(int x, int y)
	{
		var display = get_display();
		Gdk.Cursor cursor = get_link_at_pos(x, y, null) || get_pixbuf_at_pos(x, y) != null
			? new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND2) : null;
		
		if (this.cursor != cursor)
		{
			get_window(Gtk.TextWindowType.TEXT).set_cursor(cursor);
			display.flush();
			this.cursor = cursor;
		}
	}
}

} // namespace Drtgtk
