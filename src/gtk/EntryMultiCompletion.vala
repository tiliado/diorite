/*
 * Copyright 2016 Jiří Janoušek <janousek.jiri@gmail.com>
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

public class EntryMultiCompletion : Gtk.EntryCompletion {
    public Gtk.Entry? entry {get {return base.get_entry() as Gtk.Entry;}}
    public string? key {get; private set; default = null;}
    public bool key_valid {get; private set; default = false;}
    public int key_start {get; private set; default = -1;}
    public int key_end {get; private set; default = -1;}
    public int cursor {get; private set; default = -1;}

    public EntryMultiCompletion(Gtk.Entry entry, Gtk.TreeModel? model = null, int text_column = -1) {
        GLib.Object(model: model, minimum_key_length: 1);
        if (text_column >= 0) {
            this.text_column = text_column;
        }

        entry.set_completion(this);
        entry.notify["cursor-position"].connect_after(on_cursor_position_changed);
        set_match_func(search_match_func);
        match_selected.connect(on_match_selected);
        cursor_on_match.connect(on_cursor_on_match);
        insert_prefix.connect(on_insert_prefix);
    }

    public void complete_inline() {
        if (key_valid && cursor == key_end) {
            complete(); // Update filter first
            string? prefix = compute_prefix(key);
            if (prefix != null) {
                insert_match(prefix, true);
            }
        }
    }

    protected virtual void parse_key() {
        string text = entry.text;
        cursor = entry.cursor_position;
        key = null;
        key_start = key_end = -1;
        key_valid = false;
        if (cursor > 0 && !String.is_empty(text)) {
            key_start = String.last_index_of_char(text, ' ', 0, cursor) + 1;
            if (cursor > key_start) {
                key_end = String.index_of_char(text, ' ', cursor);
                if (key_end < 0) {
                    key_end = text.length;
                }
                key = text.slice(key_start, cursor);
//~                 debug("Text '%s', key '%s', %d→%d→%d", text, key, key_start, cursor, key_end);
                if (!String.is_empty(key.strip())) {
                    key_valid = true;
                }
            }
        }
    }

    private bool search_match_func(Gtk.EntryCompletion completion, string text, Gtk.TreeIter iter) {
        if (!key_valid) {
            return false;
        }
        string candidate;
        model.get(iter, text_column, out candidate);
        string prefix = key.strip().down();
        if (String.is_empty(prefix)) {
            return false;
        }
        return candidate.down().has_prefix(prefix);
    }

    private void insert_match(string match, bool select) {
        return_if_fail(key_valid);
        freeze_notify();
        string text = entry.text;
        int original_cursor = cursor;
        int match_end_cursor = key_start + match.length;
        entry.text = text.slice(0, cursor) + match.substring(cursor - key_start) + text.substring(key_end);
        if (select) {
            entry.select_region(match_end_cursor, original_cursor);
        } else {
            entry.set_position(match_end_cursor);
        }
        thaw_notify();
    }

    private void on_cursor_position_changed(GLib.Object emitter, ParamSpec property) {
        parse_key();
        /* Necessary for pop-up window to be shown */
        entry.changed();
        /* Built-in inline completion works only for a single word */
        if (inline_completion) {
            complete_inline();
        }
    }

    private bool on_match_selected(
        Gtk.EntryCompletion completion, Gtk.TreeModel model, Gtk.TreeIter iter) {
        set_text_from_match(model, iter, false);
        return true;
    }

    private bool on_cursor_on_match(
        Gtk.EntryCompletion completion, Gtk.TreeModel model, Gtk.TreeIter iter) {
        set_text_from_match(model, iter, true);
        return true;
    }

    private void set_text_from_match(Gtk.TreeModel model, Gtk.TreeIter iter, bool select) {
        return_if_fail(key_valid);
        freeze_notify();
        string match;
        model.get(iter, text_column, out match);
        insert_match(match, select);
    }

    private bool on_insert_prefix(Gtk.EntryCompletion completion, string prefix) {
        /* We use complete_inline() method.*/
        return true;
    }
}

} // namespace Drtgtk
