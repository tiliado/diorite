/*
 * Copyright 2015 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drtgtk.Icons
{

/**
 * Get icon name for given position.
 *
 * @param position    The position.
 * @return The ison name for given position.
 */
public static unowned string get_icon_name_for_position(Gtk.PositionType position) {
	switch (position) {
	case Gtk.PositionType.LEFT: return "go-previous-symbolic";
	case Gtk.PositionType.RIGHT: return "go-next-symbolic";
	case Gtk.PositionType.TOP: return "go-up-symbolic";
	case Gtk.PositionType.BOTTOM: return "go-down-symbolic";
	default: return "go-previous-symbolic";
	}
}

public static Gdk.Pixbuf? load_theme_icon(string[] names, int size)
{
	foreach (var name in names)
	{
		try
		{
			var icon = Gtk.IconTheme.get_default().load_icon(name, size, 0);
			if (icon != null)
				return icon;
		}
		catch (GLib.Error e)
		{
			warning("Failed to load icon '%s': %s", name, e.message);
		}
	}
	return null;
}

} // namespace Drtgtk
