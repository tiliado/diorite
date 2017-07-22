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

namespace Drt.Css
{

/**
 * Default badge class for {@link Gtk.Label} or {@link Gtk.Button}.
 */
public const string BADGE_DEFAULT = "badge-default";
/**
 * Success badge class for {@link Gtk.Label} or {@link Gtk.Button}.
 */
public const string BADGE_OK = "badge-ok";
/**
 * Informational badge class for {@link Gtk.Label} or {@link Gtk.Button}.
 */
public const string BADGE_INFO = "badge-info";
/**
 * Warning badge class for {@link Gtk.Label} or {@link Gtk.Button}.
 */
public const string BADGE_WARNING = "badge-warning";
/**
 * Error badge class for {@link Gtk.Label} or {@link Gtk.Button}.
 */
public const string BADGE_ERROR = "badge-error";

private const string CUSTOM_CSS = """
label.badge-default,  button.badge-default,
label.badge-warning,  button.badge-warning,
label.badge-error,  button.badge-error,
label.badge-ok,  button.badge-ok,
label.badge-info,  button.badge-info {
	font-weight: bold;
}
label.badge-default,
label.badge-ok,
label.badge-info,
label.badge-warning,
label.badge-error {
	border-radius: 10px;
	padding: 5px 5px;
	font-size: 95%;
}

label.badge-warning,  button.badge-warning {
	background: #FFD600;
	color: #000000;
}
button.badge-warning:hover {
	background-color: #E7C200;
}

label.badge-error,  button.badge-error {
	background: #FF0000;
	color: #FFFFFF;
}
button.badge-error:hover {
	background-color: #C70000;
}

label.badge-info,  button.badge-info {
	background: #5FB0FF;
	color: #000000;
}
button.badge-info:hover {
	background-color: #43A2FF;
}

label.badge-default,  button.badge-default {
	background: #BFBFBF;
	color: #000000;
}
button.badge-default:hover {
	background-color: #ABABAB;
}

label.badge-ok,  button.badge-ok {
	background: #6FEF6F;
	color: #000000;
}
button.badge-ok:hover {
	background-color: #52CA52;
}

""";

/**
 * Apply Diorite CSS styles.
 * 
 * Not necessary if {@link Diorite.Application} is used.
 */
public Gtk.CssProvider apply_custom_styles(Gdk.Screen screen) throws GLib.Error
{
	var provider = new Gtk.CssProvider();
	provider.load_from_data(CUSTOM_CSS, -1);
	Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	return provider;
}

} // namespace Drt.Css
