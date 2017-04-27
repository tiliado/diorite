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

namespace Drt
{

public errordomain RequirementError
{
    /** Failed to parse extension */
    PARSE,
    /** Invalid token found */
    SYNTAX,
    /** Failed to evaluate expression */
    EVAL;
}

/**
 * Parser and evaluator of a list of requirements.
 * 
 * A requirement consist of a name and optional parameters in square brackets.
 * Requirements are separated with whitespace or a semicolon. 
 * Example: "webkitgtk[2.15.3] codec[mp3] codec[h264] feature[mse]" 
 */ 
 
public class RequirementParser
{
    /** Expresion */
    public string? data  {get; private set;}
    /** Actial position */
    public int pos {get; private set;}
    /** Position of the first error */
    public int error_pos {get; private set;}
    /** Description of the first error */
    public string? error_text {get; private set;}
    private RequirementError? error_object;
    private int len;
    private Regex patterns;
    private int peeked_token_len;
    
    /**
     * Creates new requirements parser and evaluator.
     * It can be reused for more calls of {@link eval}. 
     */
    public RequirementParser()
    {
        peeked_token_len = -1;
        len = 0;
        pos = 0;
        data = null;
        error_text = null;
        error_pos = -1;
        error_object = null;
        try
        {
            patterns = new Regex("(\\s+)|(;)|(\\w+)|(\\[.*?\\])");
        }
        catch (RegexError e)
        {
            error("Failed to compile regex patterns. %s", e.message);
        }
    }
    
    /**
     * Print the parser expression with the given position marked.
     * 
     * @param pos    The position to mark.
     * @param len    The size of the mark.
     * @return marked string 
     */
    public string mark_pos(int start, int len=1)
    {
        var buf = new StringBuilder(data);
        buf.append_c('\n');
        for (var i = 0; i < pos; i++)
            buf.append_c('_');
        buf.append_c('^');
        while (len > 1)
        {
            buf.append_c('^');
            len--;
        }
        buf.append_c('\n');
        return buf.str;
    }
    
    /**
     * Evaluate a list of requirements
     * 
     * @param requirements    The list of requirements  to parse and evaluate.
     * @return the result of the expression evaluation.
     * @throws ConditionalExpressionError on failure
     */
    public bool eval(string requirements, out string? failed_requirements) throws RequirementError
    {
        failed_requirements = null;
        len = requirements.length;
        data = requirements;
        pos = 0;
        error_text = null;
        error_pos = -1;
        error_object = null;
        reset();
        var result = parse_all(ref failed_requirements);
        if (is_error_set())
            throw error_object;
        else
            return result;
    }
    
    /**
     * Returns true if there has been an error.
     */
    public bool is_error_set()
    {
        return error_pos >= 0;
    }
    
    /**
     * Perform an identifier call
     * 
     * @param pos       the position of the identifier
     * @param ident     the name of the identifier
     * @param params    the parameters
     * @return the result of the identifier call
     */
    protected virtual bool call(int pos, string ident, string? params)
    {
        if (params != null)
            set_eval_error(pos, "Parameteres are not supported.");
        return params == null && ident != "false";
    }
    
    /**
     * Reset the inner state before parsing and evaluation of a new expression.
     */
    protected virtual void reset()
    {
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
    protected bool set_parse_error(int pos, string text, ...)
    {
        if (!is_error_set())
        {
            var error_text = text.vprintf(va_list());
            set_error(new RequirementError.PARSE("%d: %s", pos, error_text), pos, error_text);
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
    protected bool set_syntax_error(int pos, string text, ...)
    {
        if (!is_error_set())
        {
            var error_text = text.vprintf(va_list());
            set_error(new RequirementError.SYNTAX("%d: %s", pos, error_text), pos, error_text);
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
    protected bool set_eval_error(int pos, string text, ...)
    {
        if (!is_error_set())
        {
            var error_text = text.vprintf(va_list());
            set_error(new RequirementError.EVAL("%d: %s", pos, error_text), pos, error_text);
        }
        return false;
    }
    
    private void set_error(RequirementError err, int pos, string text)
    {
        error_object = err;
        error_pos = pos;
        error_text = text;
    }
    
    private bool wrong_token(int pos, Toks found, string? expected)
    {
        switch (found)
        {
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
    
    private bool next(out Toks tok, out string? val, out int position)
    {
        if (peek(out tok, out val, out position))
            return skip();
        else
            return false;
    }
    
    private bool skip()
    {
        if (peeked_token_len >= 0)
        {
            pos += peeked_token_len;
            peeked_token_len = -1;
            return true;
        }
        return next(null, null, null);
    }
    
    private bool peek(out Toks tok, out string? val, out int position)
    {
        val = null;
        position = pos;
        peeked_token_len = -1;
        while (pos < len)
        {
            tok = Toks.NONE;
            MatchInfo mi;
            try
            {
                if (patterns.match_full(data, len, pos, RegexMatchFlags.ANCHORED, out mi))
                {
                    for (var i = 1; i < Toks.EOF; i++)
                    {
                        var result = mi.fetch(i);
                        if (result != null && result[0] != 0)
                        {
                            tok = (Toks) i;
                            val = (owned) result;
                            if (tok != Toks.SPACE)
                            {
                                peeked_token_len = val.length;
                                return true;
                            }
                            pos += val.length;
                            position = pos;
                            break;
                        }
                    }
                }
            }
            catch (RegexError e)
            {
                critical("Regex error: %s", e.message);
            }
            if (tok != Toks.SPACE)
                return false;
        }
        tok = Toks.EOF;
        return false;
    }
    
    private bool parse_all(ref string? failed_requirements)
    {
        Toks tok = Toks.NONE;
        string? val;
        int pos;
        var result = true;
        while (next(out tok, out val, out pos))
        {
			switch (tok)
			{
			case Toks.SPACE:
			case Toks.SEMICOLON:
				continue;
			case Toks.IDENT:
				result = parse_rule(pos, val, ref failed_requirements) && result;
				break;
			default:
				wrong_token(pos, tok, "One of SPACE, SEMICOLON, IDENT tokens");
				break;
			}
		}
        if (tok == Toks.EOF)
            return result;
        else
            return wrong_token(pos, tok, "EOF token");
    }
    
    private bool parse_rule(int pos, string ident, ref string? failed_requirements)
    {
        Toks tok = Toks.NONE;
        string? params;
        if (peek(out tok, out params, null) && tok == Toks.PARAMS)
        {
            skip();
            var len = params.length;
            if (len > 2)
				params = params.substring(1, len - 2);
			else
				params = null;
            return parse_call(pos, ident, params, ref failed_requirements);
        }
        return parse_call(pos, ident, null, ref failed_requirements);
    }
    
    private bool parse_call(int pos, string ident, string? params, ref string? failed_requirements)
    {
        if (is_error_set())
            return false;
          
        var result = call(pos, ident, params);
        if (!result)
        {
			if (failed_requirements == null)
				failed_requirements = "";
			else
				failed_requirements += " ";
			failed_requirements += "%s[%s]".printf(ident, params ?? "");
		}
		return result;
    }
    
    private enum Toks
    {
        NONE,
        SPACE,
        SEMICOLON,
        IDENT,
        PARAMS,
        EOF;
        
        public string to_str()
        {
            return to_string().substring(Toks.NONE.to_string().length - 4);
        }
    }
}

} // namespace Drt
