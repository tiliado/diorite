/*
 * Copyright 2015-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

private extern const int SQLITE_TRANSIENT;

namespace Drtdb
{

/**
 * Database query object
 */
public class Query : GLib.Object
{
	public Connection connection {get; private set;}
	private Sqlite.Statement? statement = null;
	protected int n_parameters = 0;
	
	/**
	 * Create new database query wrapper
	 * 
	 * @param connection      corresponding database connection
	 * @param statement       corresponding sql query
	 */
	public Query(Connection connection, owned Sqlite.Statement statement)
	{
		GLib.Object();
		this.connection = connection;
		this.statement = (owned) statement;
		this.n_parameters = this.statement.bind_parameter_count();
	}
	
	/**
	 * Execute SQL query
	 * 
	 * @param cancellable    Cancellable object
	 * @return the result of the query
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public Result exec(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		var result = get_result();
		result.next(cancellable);
		return result;
	}
	
	/**
	 * Executes a select SQL query
	 * 
	 * Typical usage:
	 * 
	 * {{{
	 * Result result = query.select();
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
		return get_result();
	}
	
	/**
	 * Get result of the query
	 * 
	 * The query is not executed until {@link Result.next} is called.
	 * It is more convenient to call {@link exec} or {@link select} instead.
	 * 
	 * @return result wrapper
	 * @throws DatabaseError if the query has already been executed
	 */
	public Result get_result() throws DatabaseError
	{
		check_not_executed();
		var result = new Result(connection, (owned) statement);
		statement = null;
		return result;
	}
	
	/**
	 * Bind values to query
	 * 
	 * @param index     the index of the first value placeholder in the SQL query
	 * @param values    the values to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when provided data type is not supported or operation fails
	 */
	public Query bind_values(int index, SList<Value?> values) throws DatabaseError
	{
		var len = values.length();
		for (var i = 0; i < len; i++)
		{
			bind(index + i, values.data);
			values = values.next;
		}
		return this;
	}
	
	/**
	 * Bind value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when provided data type is not supported or operation fails
	 */
	public Query bind(int index, GLib.Value? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		var type = value.type();
		if (type == typeof(bool))
			return bind_bool(index, value.get_boolean());
		if (type == typeof(int))
			return bind_int(index, value.get_int());
		if (type == typeof(int64))
			return bind_int64(index, value.get_int64());
		if (type == typeof(string))
			return bind_string(index, value.get_string());
		if (type == typeof(double))
			return bind_double(index, value.get_double());
		if (type == typeof(float))
			return bind_double(index, (double) value.get_float());
		if (type == typeof(GLib.Bytes))
			return bind_bytes(index, (GLib.Bytes) value.get_boxed());
		if (type == typeof(GLib.ByteArray))
			return bind_byte_array(index, (GLib.ByteArray) value.get_boxed());
		if (type == typeof(void*))
		{
			if (value.get_pointer() == null)
				return bind_null(index);
			throw new DatabaseError.DATA_TYPE("Data type %s is supported only with a null pointer.", type.name());
		}

		throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
	}
	
	/**
	 * Bind null value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public Query bind_null(int index) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_null(index));
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
	public Query bind_bool(int index, bool value) throws DatabaseError
	{
		return bind_int(index, value ? 1 : 0);
	}
	
	/**
	 * Bind integer value to query
	 * 
	 * @param index    the index of the value placeholder in the SQL query
	 * @param value    the value to bind
	 * @return `this` query object for easier chaining
	 * @throws DatabaseError when operation fails
	 */
	public Query bind_int(int index, int value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_int(index, value));
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
	public Query bind_int64(int index, int64 value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_int64(index, value));
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
	public Query bind_string(int index, string? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_text(index, value));
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
	public Query bind_double(int index, double value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_double(index, value));
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
	public Query bind_blob(int index, uint8[] value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		/* SQLITE_TRANSIENT is necessary to support query.bind(new uint8[]{1, 2, 3, 4}); */
		throw_on_error(statement.bind_blob(index, value, value.length, (DestroyNotify) SQLITE_TRANSIENT));
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
	public Query bind_bytes(int index, GLib.Bytes? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_blob(index, value.get_data(), (int) value.get_size(), null));
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
	public Query bind_byte_array(int index, GLib.ByteArray? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_blob(index, value.data, (int) value.len, null));
		return this;
	}
	
	/**
	 * Throw error if the query has already been executed.
	 */
	protected void check_not_executed() throws DatabaseError
	{
		if (statement == null)
			throw new DatabaseError.MISUSE("Query has been already executed. |%s|", statement.sql());
	}
	
	/**
	 * Throw error if the index is out of bounds.
	 */
	protected int check_index(int index) throws DatabaseError
	{
		if (n_parameters == 0)
			throw new DatabaseError.RANGE("Query doesn't have parameters. |%s|", statement.sql());
		if (index <= 0 || index > n_parameters)
			throw new DatabaseError.RANGE(
				"Index %d is not in range 1..%d. |%s|", index, n_parameters, statement.sql());
		return index;
	}
	
	/**
	 * Throw error if statement fails.
	 */
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		if (Drtdb.is_sql_error(result))
			throw convert_sqlite_error(result, connection.get_last_error_message(), sql);
		return result;
	}
}

} // namespace Drtdb
