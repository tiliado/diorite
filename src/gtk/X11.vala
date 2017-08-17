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

namespace Drtgtk.X11
{

/**
 * Retrieve window property of type window.
 * 
 * @param window      target window or ``null`` to use the default root window
 * @param property    name of the requested property
 * @return            the value of property as {@link Gdk.X11.Window} on success,
 *                    null on failure such as invalid ``window``, non-existent ``property``
 *                    or different property type than {@link X.XA_WINDOW}.
 */
public Gdk.X11.Window? get_window_property_as_win(Gdk.Window? window, string property)
{
	Gdk.X11.Window? win, result = null;
	if (window != null)
		win = window as Gdk.X11.Window;
	else
		win = Gdk.get_default_root_window() as Gdk.X11.Window;
	var display = win.get_display() as Gdk.X11.Display;
	
	X.Atom type;
	int format;
	ulong n_items;
	ulong bytes_after;
	void* data;
	
	display.error_trap_push();
	display.get_xdisplay().get_window_property(
		win.get_xid(), Gdk.X11.get_xatom_by_name_for_display(display, property),
		0, long.MAX, false, X.XA_WINDOW, out  type, out format, out n_items, out bytes_after, out data);
	display.error_trap_pop_ignored();	
	
	if (type == X.XA_WINDOW)
	{
		X.Window xwin = *(X.Window *) data;
		result = new Gdk.X11.Window.foreign_for_display(display, xwin);
	}
	
	if (data != null)
		X.free(data);
	return result;
}


/**
 * Retrieve window property of type UTF-8 string.
 * 
 * @param window      target window or ``null`` to use the default root window
 * @param property    name of the requested property
 * @return            the value of property as string on success,
 *                    null on failure such as invalid ``window`` or non-existent ``property``.
 */
public string? get_window_property_as_utf8(Gdk.Window? window, string property)
{
	Gdk.X11.Window win;
	if (window != null)
		win = window as Gdk.X11.Window;
	else
		win = Gdk.get_default_root_window() as Gdk.X11.Window;
	var display = win.get_display() as Gdk.X11.Display;
	
	X.Atom type;
	int format;
	ulong n_items;
	ulong bytes_after;
	void* data;
	string? name = null;
	
	display.error_trap_push();
	display.get_xdisplay().get_window_property(
		win.get_xid(), Gdk.X11.get_xatom_by_name_for_display(display, property), 0, long.MAX, false,
		Gdk.X11.get_xatom_by_name_for_display(display, "UTF8_STRING"),
		out type, out format, out n_items, out bytes_after, out data);
	display.error_trap_pop_ignored();
	
	if (data != null)
	{
		name = (string) data;
		X.free(data);
	}
	return name;
}


/**
 * Retrieve WM_CHECK Window of a compliant window manager
 * 
 * See [[http://standards.freedesktop.org/wm-spec/1.3/ar01s03.html|Extended Window Manager Hints]].
 * 
 * @return    WM_CHECK Window of a compliant window manager of null if there is not any
 */
public Gdk.X11.Window? get_net_wm_check_window()
{
	var window = get_window_property_as_win(null, "_NET_SUPPORTING_WM_CHECK");
	if (window == null)
		return null;
	if (get_window_property_as_win(window, "_NET_SUPPORTING_WM_CHECK").get_xid() != window.get_xid())
		return null;
	return window;
}

} // namespace Drtgtk.X11
