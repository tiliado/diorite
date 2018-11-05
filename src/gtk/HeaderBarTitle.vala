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

namespace Drtgtk {

public class HeaderBarTitle: Gtk.Grid {
    public Gtk.Label? title_label {get; private set; default = null;}
    public Gtk.Label? subtitle_label {get; private set; default = null;}
    public Gtk.Widget? start_widget {
        get {return _start_widget;}
        set {
            if (_start_widget != null && _start_widget.get_parent() == this) {
                remove(_start_widget);
            }
            _start_widget = value;
            if (value != null) {
                value.vexpand = true;
                attach(value, 0, 0, 1, 2);
            }
        }
    }
    public Gtk.Widget? end_widget {
        get {return _end_widget;}
        set {
            if (_end_widget != null && _end_widget.get_parent() == this) {
                remove(_end_widget);
            }
            _end_widget = value;
            if (value != null) {
                value.vexpand = true;
                attach(value, 2, 0, 1, 2);
            }
        }
    }
    private Gtk.Widget? _start_widget  = null;
    private Gtk.Widget? _end_widget = null;

    public HeaderBarTitle(string? title=null, string? subtitle=null) {
        set_title(title);
        set_subtitle(subtitle);
        hexpand = vexpand = false;
    }

    public void set_title(string? title) {
        if (title == null) {
            if (title_label != null) {
                remove(title_label);
                title_label = null;
            }
        } else if (title_label == null) {
            title_label = new Gtk.Label(title);
            title_label.hexpand = false;
            title_label.vexpand = true;
            title_label.halign = Gtk.Align.CENTER;
            title_label.valign = Gtk.Align.CENTER;
            attach(title_label, 1, 0, 1, 1);
            title_label.get_style_context().add_class("title");
            title_label.show();
        } else {
            title_label.label = title;
        }
    }

    public void set_subtitle(string? subtitle) {
        if (subtitle == null) {
            if (subtitle_label != null) {
                remove(subtitle_label);
                subtitle_label = null;
            }
        } else if (subtitle_label == null) {
            subtitle_label = new Gtk.Label(subtitle);
            subtitle_label.hexpand = false;
            subtitle_label.vexpand = true;
            subtitle_label.halign = Gtk.Align.CENTER;
            subtitle_label.valign = Gtk.Align.CENTER;
            subtitle_label.ellipsize = Pango.EllipsizeMode.END;
            attach(subtitle_label, 1, 1, 1, 1);
            subtitle_label.get_style_context().add_class("subtitle");
            subtitle_label.show();
        } else {
            subtitle_label.label = subtitle;
        }
    }
}

} // namespace Drtgtk
