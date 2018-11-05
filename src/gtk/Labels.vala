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

namespace Drtgtk.Labels
{

public Gtk.Label plain(string? label, bool wrap=false, bool use_markup=false)
{
    return (Gtk.Label) GLib.Object.@new(typeof(Gtk.Label),
        label: label, wrap: wrap, vexpand: false, hexpand: true, use_markup: use_markup,
        halign: Gtk.Align.START, yalign: 0.0f, xalign: 0.0f);
}


public Gtk.Label markup(string? markup, ...)
{
    return (Gtk.Label) GLib.Object.@new(typeof(Gtk.Label),
        label: markup != null ? Markup.vprintf_escaped(markup, va_list()) : markup,
        use_markup: true, wrap: true, vexpand: false, hexpand: true,
        halign: Gtk.Align.START, yalign: 0.0f, xalign: 0.0f);
}


public Gtk.Label header(string text)
{
    return (Gtk.Label) GLib.Object.@new(typeof(Gtk.Label),
        label: Markup.printf_escaped("<span size='large'><b>%s</b></span>", text),
        use_markup: true, wrap: true, vexpand: false, hexpand: true,
        halign: Gtk.Align.CENTER, yalign: 0.0f, xalign: 0.0f);
}

} // namespace Drtgtk.Labels
