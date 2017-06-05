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

namespace Dioritedb
{

/**
 * Raw query class.
 * 
 * Used for queries with bound primitive types.
 */
public class RawQuery : Query
{
	/**
	 * Creates new RawQuery object.
	 * 
	 * @param connection    corresponding database connection
	 * @param sql           a SQL query, possibly with placeholders
	 */
	public RawQuery(Connection connection, string sql)
	{
		base(connection, sql);
	}
	
	/**
	 * Execute SQL query
	 * 
	 * @param cancellable    Cancellable object
	 * @return the result of the query
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public Result exec(Cancellable? cancellable=null) throws Error, DatabaseError
	{
		check_not_executed_and_set(true);
		var result = new Result(this);
		result.next(cancellable);
		return result;
	}
	
	/**
	 * Executes a select SQL query
	 * 
	 * Typical usage:
	 * 
	 * {{{
	 * Result result = query.exec_select();
	 * while (result.next())
	 * {
	 *        // process data
	 * }
	 * }}}
	 * 
	 * @param cancellable    Cancellable object
	 * @return the result of the query
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public Result select(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		check_not_executed_and_set(true);
		return new Result(this);
	}
	
	/**
	 * Bind value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when provided data type is not supported or operation fails
	 */
	public new RawQuery bind(int index, GLib.Value? value) throws DatabaseError
	{
		base.bind(index, value);
		return this;
	}
	
	/**
	 * Bind null value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_null(int index) throws DatabaseError
	{
		base.bind_null(index);
		return this;
	}
	
	/**
	 * Bind boolean value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_bool(int index, bool value) throws DatabaseError
	{
		base.bind_bool(index, value);
		return this;
	}
	
	/**
	 * Bind integer value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_int(int index, int value) throws DatabaseError
	{
		base.bind_int(index, value);
		return this;
	}
	
	/**
	 * Bind 64bit integer value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_int64(int index, int64 value) throws DatabaseError
	{
		base.bind_int64(index, value);
		return this;
	}
	
	/**
	 * Bind string value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_string(int index, string? value) throws DatabaseError
	{
		base.bind_string(index, value);
		return this;
	}
	
	/**
	 * Bind double value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_double(int index, double value) throws DatabaseError
	{
		base.bind_double(index, value);
		return this;
	}
	
	/**
	 * Bind binary data value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_blob(int index, uint8[] value) throws DatabaseError
	{
		base.bind_blob(index, value);
		return this;
	}
	
	/**
	 * Bind {@link GLib.Bytes} value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_bytes(int index, GLib.Bytes? value) throws DatabaseError
	{
		base.bind_bytes(index, value);
		return this;
	}
	
	/**
	 * Bind {@link GLib.ByteArray} value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public new RawQuery bind_byte_array(int index, GLib.ByteArray? value) throws DatabaseError
	{
		base.bind_byte_array(index, value);
		return this;
	}
}

} // namespace Dioritedb
