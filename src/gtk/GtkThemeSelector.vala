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

/**
 * A selector to list and change a GTK+ theme.
 */
public class GtkThemeSelector : Gtk.ComboBoxText {
    /**
     * Creates new GtkThemeSelector.
     */
    public GtkThemeSelector(bool select_current, string? select_theme=null) {
        changed.connect(on_changed);
        update.begin(select_current, select_theme, (o, res) => update.end(res));
    }

    ~GtkThemeSelector() {
        changed.disconnect(on_changed);
    }

    /**
     * Convert theme name to labels for humans.
     *
     * Default conversions replace separators with a space, make the first letter of each word uppercase, and split
     * "CamelCase" into separate words, e.g. "Arc-Darker-solid" → "Arc Darker Solid", "deepin-dark" → "Deepin Dark",
     * "deepin-dark" → "Deepin Dark", "HighContrast" → "High Contrast".
     *
     * The label for empty label is "Default".
     *
     * @param name    Theme name.
     * @return Human label.
     */
    public virtual string create_theme_label(string? name) {
        if (name == null || name == "") {
            return "Default";
        }

        var pretty = new StringBuilder("");
        int begin = 0;
        int cursor = 0;
        unichar c;
        bool need_upper = true;
        while (name.get_next_char(ref cursor, out c)) {
            if (need_upper && !c.isupper()) {
                if (begin < cursor - 1) {
                    pretty.append(name.slice(begin, cursor));
                }
                pretty.append_unichar(c.toupper());
                need_upper = false;
                begin = cursor;
            } else if (c.isupper()) {
                if (!need_upper) {
                    if (begin < cursor - 1) {
                        pretty.append(name.slice(begin, cursor - 1));
                    }
                    pretty.append_c(' ');
                    begin = cursor - 1;
                } else {
                    need_upper = false;
                }
            } else if (!c.isalnum()) {
                if (begin < cursor - 1) {
                    pretty.append(name.slice(begin, cursor - 1));
                }
                pretty.append_c(' ');
                begin = cursor;
                need_upper = true;
            }
        }
        if (begin < cursor - 1) {
            pretty.append(name.substring(begin));
        }
        return pretty.str;
    }

    private async void update(bool select_current, string? select_theme) {
        remove_all();
        HashTable<string, File> themes = yield DesktopShell.list_gtk_themes();
        List<unowned string> names = themes.get_keys();
        names.sort(strcmp);
        append("", create_theme_label(null));
        foreach (unowned string name in names) {
            append(name, create_theme_label(name));
        }
        if (select_theme != null) {
            active_id = select_theme;
        }
        if (active_id == null) {
            active_id = select_current ? DesktopShell.get_gtk_theme() : "";
        }
        if (active_id == null) {
            active_id = "";
        }
    }

    private void on_changed() {
        unowned string theme_name = active_id;
        if (theme_name == "") {
            DesktopShell.reset_gtk_theme();
        } else if (theme_name != null) {
            DesktopShell.set_gtk_theme(theme_name);
        }
    }

}

} // namespace Drtgtk
