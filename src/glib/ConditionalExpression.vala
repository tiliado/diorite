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

namespace Drt {

public errordomain ConditionalExpressionError {
    /**
     * Failed to parse extension
     */
    PARSE,
    /**
     * Invalid token found
     */
    SYNTAX,
    /**
     * Failed to evaluate expression
     */
    EVAL;
}

/**
 * Parser and evaluator of simple conditional expressions.
 *
 * Grammar:
 *
 *  result := expr [op expr]*
 *  op := "and" | "or"
 *  expr :=  ["(" ] bool [op bool]* [")"]
 *  bool := [not] call
 *  call :=  ident [parameters]
 *  ident := "\\w"
 *  parameters := "\\[.*?\\]"
 *
 * Example: "webkitgtk[2.15.3] and codec[mp3] and codec[h264] and mse"
 */

public class ConditionalExpression {
    [Description(nick = "Conditional expression", blurb = "A data string containing conditional expression.")]
    public string? data {get; private set;}
    [Description(nick = "Position", blurb = "Current position inside conditional expression string.")]
    public int pos {get; private set;}
    [Description(nick = "The position of the first error", blurb = "The position of the first error inside conditional expression string.")]
    public int error_pos {get; private set;}
    [Description(nick = "The text of the first error", blurb = "The description of the first error.")]
    public string? error_text {get; private set;}
    private ConditionalExpressionError? error_object;
    private int len;
    private Regex patterns;
    private int peeked_token_len;

    /**
     * Creates new simple conditional expression parser and evaluator.
     * It can be reused for more calls of {@link eval}.
     */
    public ConditionalExpression() {
        peeked_token_len = -1;
        len = 0;
        pos = 0;
        data = null;
        error_text = null;
        error_pos = -1;
        error_object = null;
        try {
            patterns = new Regex("(\\s+)|(\\bnot\\b)|(\\band\\b)|(\\bor\\b)|(\\w+)|(\\[.*?\\])|(\\()|(\\))");
        } catch (RegexError e) {
            error("Failed to compile regex patterns. %s", e.message);
        }
    }

    /**
     * Print the parser expression with the given position marked.
     *
     * @param start    The position to mark.
     * @param len      The size of the mark.
     * @return marked string
     */
    public string mark_pos(int start, int len=1) {
        var buf = new StringBuilder(data);
        buf.append_c('\n');
        for (var i = 0; i < pos; i++)
        buf.append_c('_');
        buf.append_c('^');
        while (len > 1) {
            buf.append_c('^');
            len--;
        }
        buf.append_c('\n');
        return buf.str;
    }

    /**
     * Evaluate expression
     *
     * @param expression    The conditional expression to parse and evaluate.
     * @return the result of the expression evaluation.
     * @throws ConditionalExpressionError on failure
     */
    public bool eval(string expression) throws ConditionalExpressionError {
        len = expression.length;
        data = expression;
        pos = 0;
        error_text = null;
        error_pos = -1;
        error_object = null;
        reset();
        var result = parse_block(Toks.EOF);
        if (is_error_set())
        throw error_object;
        else
        return result;
    }

    /**
     * Returns true if there has been an error.
     */
    public bool is_error_set() {
        return error_pos >= 0;
    }

    /**
     * Perform an identifier call
     *
     * @param pos       the position of the identifier
     * @param ident     the name of the identifier
     * @param parameters    the parameters
     * @return the result of the identifier call
     */
    protected virtual bool call(int pos, string ident, string? parameters) {
        if (parameters != null)
        set_eval_error(pos, "Parameteres are not supported.");
        return parameters == null && ident != "false";
    }

    /**
     * Reset the inner state before parsing and evaluation of a new expression.
     */
    protected virtual void reset() {
    }

    /**
     * Set parse error
     *
     * No identifier calls are evaluated when error is set.
     *
     * @param pos     the position of the error
     * @param text    the text of the error
     * @param ...     Printf parameters
     * @return `false` as a convenience
     */
    protected bool set_parse_error(int pos, string text, ...) {
        if (!is_error_set()) {
            var error_text = text.vprintf(va_list());
            set_error(new ConditionalExpressionError.PARSE("%d: %s", pos, error_text), pos, error_text);
        }
        return false;
    }

    /**
     * Set syntax error
     *
     * No identifier calls are evaluated when error is set.
     *
     * @param pos     the position of the error
     * @param text    the text of the error
     * @param ...     Printf parameters
     * @return `false` as a convenience
     */
    protected bool set_syntax_error(int pos, string text, ...) {
        if (!is_error_set()) {
            var error_text = text.vprintf(va_list());
            set_error(new ConditionalExpressionError.SYNTAX("%d: %s", pos, error_text), pos, error_text);
        }
        return false;
    }

    /**
     * Set evaluation error
     *
     * No identifier calls are evaluated when error is set.
     *
     * @param pos     the position of the error
     * @param text    the text of the error
     * @param ...     Printf parameters
     * @return `false` as a convenience
     */
    protected bool set_eval_error(int pos, string text, ...) {
        if (!is_error_set()) {
            var error_text = text.vprintf(va_list());
            set_error(new ConditionalExpressionError.EVAL("%d: %s", pos, error_text), pos, error_text);
        }
        return false;
    }

    private void set_error(ConditionalExpressionError err, int pos, string text) {
        error_object = err;
        error_pos = pos;
        error_text = text;
    }

    private bool wrong_token(int pos, Toks found, string? expected) {
        switch (found) {
        case Toks.NONE:
            set_parse_error(pos, "Unknown token. %s expected.", expected);
            break;
        case Toks.EOF:
            set_parse_error(pos, "Unexpected end of data. %s expected.", expected);
            break;
        default:
            set_syntax_error(pos, "Unexpected token %s. %s expected.", found.to_str(), expected);
            break;
        }
        return false;
    }

    private bool next(out Toks tok, out string? val, out int position) {
        if (peek(out tok, out val, out position))
        return skip();
        else
        return false;
    }

    private bool skip() {
        if (peeked_token_len >= 0) {
            pos += peeked_token_len;
            peeked_token_len = -1;
            return true;
        }
        return next(null, null, null);
    }

    private bool peek(out Toks tok, out string? val, out int position) {
        val = null;
        position = pos;
        peeked_token_len = -1;
        while (pos < len) {
            tok = Toks.NONE;
            MatchInfo mi;
            try {
                if (patterns.match_full(data, len, pos, RegexMatchFlags.ANCHORED, out mi)) {
                    for (var i = 1; i < Toks.EOF; i++) {
                        var result = mi.fetch(i);
                        if (result != null && result[0] != 0) {
                            tok = (Toks) i;
                            val = (owned) result;
                            if (tok != Toks.SPACE) {
                                peeked_token_len = val.length;
                                return true;
                            }
                            pos += val.length;
                            position = pos;
                            break;
                        }
                    }
                }
            } catch (RegexError e) {
                critical("Regex error: %s", e.message);
            }
            if (tok != Toks.SPACE)
            return false;
        }
        tok = Toks.EOF;
        return false;
    }

    private bool parse_block(Toks end_tok) {
        var result = parse_expr(Toks.EOF);
        Toks tok = Toks.NONE;
        string? val;
        int pos;
        next(out tok, out val, out pos);
        if (tok == end_tok)
        return result;
        else
        return wrong_token(pos, tok, end_tok.to_str() + " token");
    }

    private bool parse_expr(Toks bind) {
        Toks tok = Toks.NONE;
        string? val;
        var lvalue = false;
        int pos;
        next(out tok, out val, out pos);
        switch (tok) {
        default:
            return wrong_token(pos, tok, "One of IDENT, NOT or LPAREN tokens");
        case Toks.NOT:
            lvalue = parse_not();
            break;
        case Toks.IDENT:
            lvalue = parse_ident(pos, val);
            break;
        case Toks.LPAREN:
            lvalue = parse_block(Toks.RPAREN);
            break;
        }

        while (true) {
            peek(out tok, out val, null);
            if (tok > bind)
            return lvalue;

            switch (tok) {
            default:
                return lvalue;
            case Toks.AND:
                skip();
                lvalue = parse_and(lvalue);
                break;
            case Toks.OR:
                skip();
                lvalue = parse_or(lvalue);
                break;
            }
        }
    }

    private bool parse_ident(int pos, string ident) {
        Toks tok = Toks.NONE;
        string? parameters;
        if (peek(out tok, out parameters, null) && tok == Toks.CALL) {
            skip();
            var len = parameters.length;
            if (len > 2)
            parameters = parameters.substring(1, len - 2);
            else
            parameters = null;
            return parse_call(pos, ident, parameters);
        }
        return parse_call(pos, ident, null);
    }

    private bool parse_call(int pos, string ident, string? parameters) {
        if (is_error_set())
        return false;
        return call(pos, ident, parameters);
    }

    private bool parse_and(bool lvalue) {
        var rvalue = parse_expr(Toks.AND);
        return lvalue && rvalue;
    }

    private bool parse_or(bool lvalue) {
        var rvalue = parse_expr(Toks.OR);
        return lvalue || rvalue;
    }

    private bool parse_not() {
        return !parse_expr(Toks.NOT);
    }

    private enum Toks {
        NONE,
        SPACE,
        NOT,
        AND,
        OR,
        IDENT,
        CALL,
        LPAREN,
        RPAREN,
        EOF;

        public string to_str() {
            return to_string().substring(Toks.NONE.to_string().length - 4);
        }
    }
}

} // namespace Drt
