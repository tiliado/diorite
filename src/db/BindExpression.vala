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

namespace Dioritedb
{

/**
 * Parser of SQL bind expressions.
 * 
 * SQL bind expressions are lik SQL statements but the '?' placeholders are accompanied with data type
 * specifiers:
 * 
 * * `?v` GLib.Value
 * * `?b` boolean
 * * `?i` int
 * * `?l` int64
 * * `?f` double
 * * `?s` string
 * * `?B` Bytes
 * * `?A` ByteArray
 * 
 * This way, it is possible to use a single var arg function to bind all placeholders.
 */
public class BindExpression
{
	private SList<Value?> values;
	private StringBuilder sql;
	
	/**
	 * Create new bind expression parser
	 */
	public BindExpression()
	{
		reset();
	}
	
	/**
	 * Reset the parser to the initial state.
	 */
	public void reset()
	{
		values = null;
		if (sql == null)
			sql = new StringBuilder("");
		else
			sql.truncate();
	}
	
	/**
	 * Get parsed var args as a list of proper {@link GLib.Value} instances.
	 * 
	 * @return data as {@link GLib.Value} instances
	 */
	public unowned SList<Value?> get_values()
	{
		return values;
	}
	
	/**
	 * Get final SQL query
	 * 
	 * @return SQL query without data type specifiers
	 */
	public unowned string get_sql()
	{
		return sql.str;
	}
	
	/**
	 * Parse SQL bind expression
	 * 
	 * @param sql_str    a sql string
	 * @param ...        data corresponding to the placeholders in the sql string
	 * @throws DatabaseError if the expression contains invalid data type or is incomplete
	 */
	public void parse(string sql_str, ...) throws DatabaseError
	{
		parse_va(sql_str, va_list());
	}
	
	/**
	 * Parse SQL bind expression
	 * 
	 * @param sql_str    a sql string
	 * @param args       data corresponding to the placeholders in the sql string
	 * @throws DatabaseError if the expression contains invalid data type or is incomplete
	 */
	public void parse_va(string sql_str, va_list args) throws DatabaseError
	{
		var offset = 0;
		var len = sql_str.length;
		unowned uint8[] data = sql_str.data;
		int pos;
		for (pos = 0; pos < len; pos++)
		{
			uint8 c = data[pos];
			if (c == '?')
			{
				pos++;
				sql.append_len(Diorite.String.offset(sql_str, offset), pos - offset);
				if (pos >= len)
					throw new DatabaseError.MISUSE("Unexpected end of data at %d.", pos - 1);
				offset = pos + 1;
				Value? val = {};
				switch (data[pos])
				{
				case 'v':
					val = args.arg();
					break;
				case 'b':
					val.init(typeof(bool)).set_boolean(args.arg());
					break;
				case 'i':
					val.init(typeof(int)).set_int(args.arg());
					break;
				case 'l':
					val.init(typeof(int64)).set_int64(args.arg());
					break;
				case 'f':
					val.init(typeof(double)).set_double(args.arg());
					break;
				case 's':
					val.init(typeof(string)).set_string(args.arg());
					break;
				case 'B':
					val.init(typeof(GLib.Bytes)).set_boxed(args.arg<GLib.Bytes>());
					break;
				case 'A':
					val.init(typeof(GLib.ByteArray)).set_boxed(args.arg<GLib.ByteArray>());
					break;
				default:
					throw new DatabaseError.DATA_TYPE("Unknown data type specifier: '%c'.", data[pos]);
				}
				values.prepend(val);
			}
		}
		
		values.reverse();		
		if (pos > offset)
			sql.append_len(Diorite.String.offset(sql_str, offset), pos - offset);
	}
}

} // namespace Dioritedb
