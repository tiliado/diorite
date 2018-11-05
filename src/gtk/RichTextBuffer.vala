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

namespace Drtgtk {

/**
 * Function that returns real image path for uri.
 *
 * @param uri    image uri
 * @return real image path
 */
public delegate string ImageLocator(string uri);

/**
 * Rich Text Buffer is used to load a XML-like document with
 * a limited formating.
 *
 * Simple Document buffer supports a very very limited subset of HTML, you should
 * use WebKitGtk to render HTML documents. Supported tags are:
 *
 * * <h1>, <h2>, <h3> - headings
 * * <p> - a paragraph
 * * <br /> - line break
 * * <b> - bold text
 * * <strong> - alias for <b>
 * * <i> - italic text
 * * <em> - alias for <i>
 * * <a href="uri"> - a link
 * * <dl> - a definition list
 * * <dt> - the defined term (must be inside <dl>)
 * * <dd> - definition (must be inside <dl>)
 * * <img src="uri" width="" height="" /> - an image
 * * <ul> - unordered list (bullets)
 * * <li> - list item
 *
 * Tag <a> is inserted as anonymous Drt.SimpleDocLink, <img> is inserted as Gtk.Pixbuf.
 * Other tags are inserted as Gtk.TextTags with names TEXT_TAG_*.
 */
public class RichTextBuffer: Gtk.TextBuffer {
    /**
     * Name of a Gtk.TextTag for tag <h1>.
     */
    public const string TEXT_TAG_HEADING1 = "h1";
    /**
     * Name of a Gtk.TextTag for tag <h2>.
     */
    public const string TEXT_TAG_HEADING2 = "h2";
    /**
     * Name of a Gtk.TextTag for tag <h3>.
     */
    public const string TEXT_TAG_HEADING3 = "h3";
    /**
     * Name of a Gtk.TextTag for tag <p>.
     */
    public const string TEXT_TAG_PARAGRAPH = "p";
    /**
     * Name of a Gtk.TextTag for tag <b>.
     */
    public const string TEXT_TAG_BOLD = "b";
    /**
     * Name of a Gtk.TextTag for tag <i>.
     */
    public const string TEXT_TAG_ITALIC = "i";
    /**
     * Name of a Gtk.TextTag for tag <dl>.
     */
    public const string TEXT_TAG_DEFINITION_LIST = "dl";
    /**
     * Name of a Gtk.TextTag for tag <dt>.
     */
    public const string TEXT_TAG_DEFINED_TERM = "dt";
    /**
     * Name of a Gtk.TextTag for tag <dd>.
     */
    public const string TEXT_TAG_DEFINITION = "dd";
    /**
     * Name of a Gtk.TextTag for tag <ul>.
     */
    public const string TEXT_TAG_UNORDERED_LIST = "ul";
    /**
     * Name of a Gtk.TextTag for tag <li>.
     */
    public const string TEXT_TAG_LIST_ITEM = "li";
    /**
     * Name of a hashtable key for path of images.
     *
     * var path = pixbuf.get_data<string?>(IMAGE_PATH);
     */
    public const string IMAGE_PATH = "path";

    private Gdk.RGBA? _link_color = null;

    public Gdk.RGBA? get_link_color() {
        return _link_color;
    }

    public void set_link_color(Gdk.RGBA? color) {
        _link_color = color;
        if (_link_color != null) {
            tag_table.@foreach(find_link_and_set_color);
        }
    }

    private ImageLocator? _image_locator = null;
    public void set_image_locator(owned ImageLocator? locator) {
        _image_locator = (owned) locator;
    }

    /* Input tags supported by parser */
    private const string INPUT_TAG_HEADING1 = "h1";
    private const string INPUT_TAG_HEADING2 = "h2";
    private const string INPUT_TAG_HEADING3 = "h3";
    private const string INPUT_TAG_PARA = "p";
    private const string INPUT_TAG_LINE_BREAK = "br";
    private const string INPUT_TAG_BOLD = "b";
    private const string INPUT_TAG_STRONG = "strong";
    private const string INPUT_TAG_ITALIC = "i";
    private const string INPUT_TAG_EM = "em";
    private const string INPUT_TAG_LINK = "a";
    private const string LINK_TARGET = "href";
    private const string INPUT_TAG_DL = "dl";
    private const string INPUT_TAG_DT = "dt";
    private const string INPUT_TAG_DD = "dd";
    private const string INPUT_TAG_IMAGE = "img";
    private const string INPUT_TAG_UL = "ul";
    private const string INPUT_TAG_LI = "li";
    private const MarkupParser parser = {start_tag, end_tag, element_text, null, null};
    private Regex strip_spaces;
    private bool insert_new_line = false;
    private bool strip_left = false;
    private bool in_paragraph = false;
    private bool ignore_text = false;
    private Queue<Tag> tag_stack = new Queue<Tag>();
    private unowned Gtk.TextTag tag_bold;
    private unowned Gtk.TextTag tag_italic;
    private unowned Gtk.TextTag tag_h1;
    private unowned Gtk.TextTag tag_h2;
    private unowned Gtk.TextTag tag_h3;
    private unowned Gtk.TextTag tag_para;
    private unowned Gtk.TextTag tag_dl;
    private unowned Gtk.TextTag tag_dt;
    private unowned Gtk.TextTag tag_dd;
    private unowned Gtk.TextTag tag_ul;
    private unowned Gtk.TextTag tag_li;


    /**
     * Creates new Simple Document Buffer.
     *
     * @param tag_table    Custom text table.!
     */
    public RichTextBuffer.with_table(Gtk.TextTagTable tag_table) {
        Object(tag_table: tag_table);
    }

    /**
     * Creates new Simple Document Buffer.
     */
    public RichTextBuffer() {
        Object();
    }

    construct {
        try {
            strip_spaces = new Regex("(\n|\\s)+", 0);
        } catch (RegexError e) {
            error("Failed to compile strip space regex: %s", e.message);
        }

        tag_bold = create_tag(TEXT_TAG_BOLD, "weight", Pango.Weight.BOLD);
        tag_italic = create_tag(TEXT_TAG_ITALIC, "style", Pango.Style.ITALIC);
        tag_h1 = create_tag(TEXT_TAG_HEADING1, "scale", Pango.Scale.XX_LARGE, "weight", Pango.Weight.HEAVY);
        tag_h2 = create_tag(TEXT_TAG_HEADING2, "scale", Pango.Scale.X_LARGE, "weight", Pango.Weight.BOLD);
        tag_h3 = create_tag(TEXT_TAG_HEADING3, "scale", Pango.Scale.LARGE, "weight", Pango.Weight.BOLD);
        tag_para = create_tag(TEXT_TAG_PARAGRAPH);
        tag_dl = create_tag(TEXT_TAG_DEFINITION_LIST);
        tag_dt = create_tag(TEXT_TAG_DEFINED_TERM, "weight", Pango.Weight.BOLD);
        tag_dd = create_tag(TEXT_TAG_DEFINITION, "left-margin", 50);
        tag_ul = create_tag(TEXT_TAG_UNORDERED_LIST);
        tag_li = create_tag(TEXT_TAG_LIST_ITEM, "left-margin", 13, "indent", -13);
        _image_locator = default_image_locator;
    }

    /**
     * Emitted when image is about to be inserted.
     *
     * The default handler inserts image with path retrieved by image_locator.
     *
     * @param uri       image uri
     * @param width     image width
     * @param height    image height
     */
    public virtual signal void image_requested(string uri, int width, int height) {
        if (_image_locator != null) {
            insert_image_at_cursor(_image_locator(uri), width, height);
        }
    }

    public string default_image_locator(string uri) {
        return uri;
    }

    /**
     * Emitted when an unknown in-line tag is opened. You can use provided
     * information to create custom Gtk.TextTag and add it to tag stack via
     * append_tag_to_stack().
     *
     * @param name           tag name
     * @param attr_names     names of attributes
     * @param attr_values    values of attributes
     */
    public signal void unknown_tag_opened(string name, string[] attr_names, string[] attr_values);

    /**
     * Emitted when an unknown in-line tag is closed. You can use provided
     * information to close custom Gtk.TextTag via close_tag_from_stack().
     *
     * @param name    tag name
     */
    public signal void unknown_tag_closed(string name);

    /**
     * Loads document from file.
     *
     * @param doc_file    document file to load
     * @throws MarkupError on failure
     */
    public void load_from_file(File doc_file) throws MarkupError {
        clear();
        append_from_file(doc_file);
    }

    /**
     * Appends content of a document from file.
     *
     * @param doc_file    document file to load
     * @throws MarkupError on failure
     */
    public void append_from_file(File doc_file) throws MarkupError {
        string doc_text;
        try {
            doc_text = Drt.System.read_file(doc_file);
        } catch (GLib.Error e) {
            throw new MarkupError.INVALID_CONTENT("Unable to read file %s.", doc_file.get_path());
        }
        append(doc_text);
    }

    /**
     * Loads a document.
     *
     * @param doc_text    Content of a document to load.
     * @throws MarkupError on failure
     */
    public void load(string doc_text) throws MarkupError {
        clear();
        append(doc_text);
    }

    /**
     * Appends content of a document.
     *
     * @param doc_text    Content of a document to load.
     * @throws MarkupError on failure
     */
    public void append(string doc_text) throws MarkupError {
        var context = new MarkupParseContext(parser, 0, this, () => {});
        context.parse(doc_text, -1);
    }

    private string norm_whitespace(string text) {
        try {
            return strip_spaces.replace(text, -1, 0, " ");
        } catch (RegexError e) {
            warning("Unable to strip spaces, Regex failed: %s", e.message);
            return text;
        }
    }

    /**
     * Clears buffer and resets parser.
     */
    public void clear() {
        in_paragraph = strip_left = insert_new_line = false;
        tag_stack.clear();
        Gtk.TextIter start, end;
        get_bounds (out start, out end);
        @delete(ref start, ref end);
    }

    private void start_tag(
        MarkupParseContext context, string name, string[] attr_names, string[] attr_values) throws MarkupError {
        switch (name) {
        case INPUT_TAG_HEADING1:
        case INPUT_TAG_HEADING2:
        case INPUT_TAG_HEADING3:
        case INPUT_TAG_PARA:
        case INPUT_TAG_DL:
        case INPUT_TAG_UL:
            if (!in_paragraph) {
                if (insert_new_line) {
                    insert_new_line = false;
                    insert_at_cursor("\n", -1);
                }
                in_paragraph = true;
                strip_left = true;
                switch (name) {
                case INPUT_TAG_HEADING1:
                    append_tag_to_stack(name, tag_h1);
                    break;
                case INPUT_TAG_HEADING2:
                    append_tag_to_stack(name, tag_h2);
                    break;
                case INPUT_TAG_HEADING3:
                    append_tag_to_stack(name, tag_h3);
                    break;
                case INPUT_TAG_DL:
                    ignore_text = true;
                    append_tag_to_stack(name, tag_dl);
                    break;
                case INPUT_TAG_UL:
                    ignore_text = true;
                    append_tag_to_stack(name, tag_ul);
                    break;
                default:
                    append_tag_to_stack(name, tag_para);
                    break;
                }
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_LINE_BREAK:
            insert_at_cursor("\n", -1);
            strip_left = true;
            break;
        case INPUT_TAG_BOLD:
        case INPUT_TAG_STRONG:
            if (in_paragraph) {
                append_tag_to_stack(name, tag_bold);
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_ITALIC:
        case INPUT_TAG_EM:
            if (in_paragraph) {
                append_tag_to_stack(name, tag_italic);
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_LINK:
            if (in_paragraph) {
                int i;
                for (i = 0; i < attr_names.length; i++) {
                    if (attr_names[i] == LINK_TARGET) {
                        break;
                    }
                }
                if (i >= attr_values.length) {
                    throw new MarkupError.MISSING_ATTRIBUTE("Missing attribute '%s' for element '%s'.", LINK_TARGET, INPUT_TAG_LINK);
                }
                var uri = attr_values[i];
                append_tag_to_stack(name, create_link_tag(uri));
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_DT:
            if (in_paragraph) {
                append_tag_to_stack(name, tag_dt);
                ignore_text = false;
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_DD:
            if (in_paragraph) {
                append_tag_to_stack(name, tag_dd);
                ignore_text = false;
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_LI:
            if (in_paragraph) {
                append_tag_to_stack(name, tag_li);
                insert_at_cursor("• ", -1);
                ignore_text = false;
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        case INPUT_TAG_IMAGE:
            string? src = null;
            int width = -1;
            int height = -1;

            for (int j = 0; j < attr_names.length; j++) {
                switch (attr_names[j]) {
                case "src":
                    src = attr_values[j];
                    break;
                case "width":
                    width = int.parse(attr_values[j]);
                    break;
                case "height":
                    height = int.parse(attr_values[j]);
                    break;
                }
            }

            if (src != null) {
                image_requested(src, width, height);
            }
            break;
        default:
            if (in_paragraph) {
                unknown_tag_opened(name, attr_names, attr_values);
            } else {
                debug("Ignored start tag: %s", name);
            }
            break;
        }
    }

    /**
     * Appends tag to a stack at current position.
     *
     * @param name        tag name
     * @param text_tag    tag format
     */
    public void append_tag_to_stack(string name, Gtk.TextTag text_tag) {
        Gtk.TextIter iter;
        get_end_iter(out iter);
        var tag = new Tag(name, create_mark(null, iter, true), text_tag);
        tag_stack.push_tail((owned) tag);
    }

    private void end_tag(MarkupParseContext context, string name)
    throws MarkupError {
        if (in_paragraph) {
            switch (name) {
            case INPUT_TAG_HEADING1:
            case INPUT_TAG_HEADING2:
            case INPUT_TAG_HEADING3:
            case INPUT_TAG_PARA:
                insert_at_cursor("\n", -1);
                insert_new_line = true;
                in_paragraph = false;
                close_tag_from_stack(name);
                ignore_text = false;
                break;
            case INPUT_TAG_DL:
            case INPUT_TAG_UL:
                insert_new_line = true;
                in_paragraph = false;
                close_tag_from_stack(name);
                ignore_text = false;
                break;
            case INPUT_TAG_BOLD:
            case INPUT_TAG_STRONG:
            case INPUT_TAG_ITALIC:
            case INPUT_TAG_EM:
            case INPUT_TAG_LINK:
                close_tag_from_stack(name);
                break;
            case INPUT_TAG_DT:
            case INPUT_TAG_DD:
                close_tag_from_stack(name);
                insert_at_cursor("\n", -1);
                ignore_text = true;
                break;
            case INPUT_TAG_LI:
                close_tag_from_stack(name);
                insert_at_cursor("\n", -1);
                ignore_text = true;
                break;
            case INPUT_TAG_IMAGE:
            case INPUT_TAG_LINE_BREAK:
                break;
            default:
                unknown_tag_closed(name);
                break;
            }
        } else {
            debug("Ignored end tag: %s", name);
        }
    }

    /**
     * Closes tag from stack and applies its formating.
     *
     * @param name    tag name
     * @throws MarkupError when name doesn't match nme of the last opened tag.
     */
    public void close_tag_from_stack(string name) throws MarkupError {
        var tag = tag_stack.pop_tail();
        if (tag == null) {
            throw new MarkupError.PARSE("Attempt to close $(name), but not tag is open.");
        }
        if (tag.name != name) {
            tag_stack.push_tail((owned) tag);
            throw new MarkupError.PARSE(@"Expected tag $(tag.name), found $(name)");
        }
        Gtk.TextIter start, end;
        get_iter_at_mark(out start, tag.mark);
        get_end_iter(out end);
        apply_tag(tag.tag, start, end);
        delete_mark(tag.mark);
    }

    private void element_text(MarkupParseContext context, string text, size_t text_len) throws MarkupError {
        if (text == "") {
            return;
        }

        var result = norm_whitespace(text);
        if (result == " ") {
            return;
        }

        if (ignore_text || !in_paragraph) {
            warning("Ignored text: '%s'", text);
            return;
        }

        if (strip_left) {
            result = result.chug();
            strip_left = false;
        }

        if (result.has_suffix(" ")) {
            strip_left = true;
        }
        insert_at_cursor(result, -1);
    }


    private unowned RichTextLink create_link_tag(string uri) {
        var tag = new RichTextLink(uri);
        tag_table.add(tag);
        if (_link_color != null) {
            tag.foreground_rgba = _link_color;
        }
        weak RichTextLink weak_tag = tag;
        return weak_tag;
    }

    private void find_link_and_set_color(Gtk.TextTag tag) {
        if (tag is RichTextLink) {
            tag.foreground_rgba = _link_color;
        }
    }

    private Gdk.Pixbuf get_missing_image_pixbuf() {
        try {
            return Gtk.IconTheme.get_default().load_icon("image-missing", 64, 0);
        } catch (GLib.Error e) {
            Drt.fatal_error(e, "Failed to load missing image pixbuf.");
        }
    }

    /**
     * Inserts image at cursor
     *
     * @param path      path to image file (missing image icon will be shown if path is null)
     * @param width     image width (-1 to use original width)
     * @param height    image height (-1 to use original height)
     */
    public void insert_image_at_cursor(string? path, int width=-1, int height=-1) {
        Gdk.Pixbuf pixbuf;
        bool real_size = true;
        int real_width = -1;
        int real_height = -1;
        if (path == null) {
            pixbuf = get_missing_image_pixbuf();
        } else {
            try {
                pixbuf = new Gdk.Pixbuf.from_file_at_size(path, width, height);
                pixbuf.set_data<string?>(IMAGE_PATH, path);

                if ((height != -1 || width != -1)
                && Gdk.Pixbuf.get_file_info(path, out real_width, out real_height) != null) {
                    real_size = (height == -1 || height == real_height)
                && (width == -1 || width == real_width);
                }
                pixbuf.set_data<bool?>("has_real_size", real_size);
            } catch (GLib.Error e) {
                pixbuf = get_missing_image_pixbuf();
                warning("Unable to load image %s: %s", path, e.message);
            }
        }

        insert_pixbuf_at_cursor(pixbuf);
    }

    /**
     * Inserts pixbuf at cursor
     *
     * @param pixbuf    pixbuf to insert
     */
    public void insert_pixbuf_at_cursor(Gdk.Pixbuf pixbuf) {
        Gtk.TextIter iter;
        get_iter_at_mark(out iter, get_insert());
        insert_pixbuf(iter, pixbuf);
    }

    [Compact]
    private class Tag {
        public string name;
        public Gtk.TextMark mark;
        public unowned Gtk.TextTag tag;

        public Tag(string name, Gtk.TextMark mark, Gtk.TextTag tag) {
            this.name = name;
            this.mark = mark;
            this.tag = tag;
        }
    }
}

/**
 * A text tag for links that holds link's URI.
 */
public class RichTextLink: Gtk.TextTag {
    [Description(nick = "Link uri", blurb = "Target URI of the link.")]
    public string uri {get; set;}

    /**
     * Creates new link text tag.
     *
     * @param uri    Target URI of the link
     */
    public RichTextLink(string uri) {
        Object(underline: Pango.Underline.SINGLE, uri: uri);
    }
}

} // namespace Drtgtk

