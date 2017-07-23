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

namespace Drtdb
{

/**
 * Result of database query
 */
public class Result : GLib.Object
{
	public Connection connection {get; private set;}
	public int n_columns {get; private set; default = -1;}
	public int counter {get; private set; default = 0;}
	private Sqlite.Statement statement;
	private HashTable<unowned string, int> column_indexes;
	private (unowned string)[]? column_names;
	
	/**
	 * Creates new database query result wrapper
	 * 
	 * @param connection    database conection
	 * @param statement     prepared SQLite statement to execute
	 */
	public Result(Connection connection, owned Sqlite.Statement statement)
	{
		this.connection = connection;
		this.statement = (owned) statement;
		column_indexes = new HashTable<unowned string, int>(str_hash, str_equal);
		column_names = null;
	}
	
	/**
	 * Proceed to the next record
	 * 
	 * @param cancellable    Cancellable object
	 * @return `true` if there is a next record, `false` if query data has been exhausted
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public bool next(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		var done = throw_on_error(statement.step()) == Sqlite.DONE;
		if (!done)
		{
			counter++;
			n_columns = statement.data_count();
		}
		else
		{
			n_columns = -1;
		}
		column_indexes.remove_all();
		column_names = null;
		return !done;
	}
	
	/**
	 * Return column index by name
	 * 
	 * @param name    column name
	 * @return the index of the column if it exists, `-1` otherwise 
	 */
	public int get_column_index(string name)
	{
		map_column_names();
		int index;
		if (column_indexes.lookup_extended(name, null, out index))
			return index;
		return -1;
	}
	
	/**
	 * Get column name by index
	 * 
	 * @param index the index of a column
	 * @return the name of the column if index is valid, `null` otherwise
	 */
	public unowned string? get_column_name(int index)
	{
		map_column_names();
		if (index < 0 || index >= n_columns)
			return null;
		return column_names[index];
	}
	
	/**
	 * Fetch value from current database record
	 * 
	 * @param index    column index
	 * @param type     value data type
	 * @return the requested value
	 * @throws DatabaseError if data type is not supported or index is invalid
	 */
	public GLib.Value? fetch_value_of_type(int index, Type type) throws DatabaseError
	{
		if (fetch_is_null(index))
			return null;
		
		if (type == typeof(void*) || !is_type_supported(type))
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		var value = GLib.Value(type);
		if (type == typeof(bool))
			value.set_boolean(fetch_bool(index));
		else if (type == typeof(int))
			value.set_int(fetch_int(index));
		else if (type == typeof(int64))
			value.set_int64(fetch_int64(index));
		else if (type == typeof(string))
			value.set_string(fetch_string(index));
		else if (type == typeof(double))
			value.set_double(fetch_double(index));
		else if (type == typeof(float))
			 value.set_float((float) fetch_double(index));
		else if (type == typeof(GLib.Bytes))
			value.set_boxed(fetch_bytes(index));
		else if (type == typeof(GLib.ByteArray))
			value.set_boxed(fetch_byte_array(index));
		else
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		return value;
	}
	
	/**
	 * Fetch null value from current database record
	 * 
	 * @param index    column index
	 * @return true if value is null
	 * @throws DatabaseError if index is invalid
	 */
	public bool fetch_is_null(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_type(index) == Sqlite.NULL;
	}
	
	/**
	 * Fetch integer value from current database record
	 * 
	 * @param index    column index
	 * @return the integer value
	 * @throws DatabaseError if index is invalid
	 */
	public int fetch_int(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_int(index);
	}
	
	/**
	 * Fetch 64bit integer value from current database record
	 * 
	 * @param index    column index
	 * @return the 64bit integer value
	 * @throws DatabaseError if index is invalid
	 */
	public int64 fetch_int64(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_int64(index);
	}
	
	/**
	 * Fetch boolean value from current database record
	 * 
	 * @param index    column index
	 * @return the boolean value
	 * @throws DatabaseError if index is invalid
	 */
	public bool fetch_bool(int index) throws DatabaseError
	{
		return fetch_int(index) != 0;
	}
	
	/**
	 * Fetch double value from current database record
	 * 
	 * @param index    column index
	 * @return the double value
	 * @throws DatabaseError if index is invalid
	 */
	public double fetch_double(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_double(index);
	}
	
	/**
	 * Fetch string value from current database record
	 * 
	 * @param index    column index
	 * @return the string value
	 * @throws DatabaseError if index is invalid
	 */
	public unowned string? fetch_string(int index) throws DatabaseError
	{
		check_index(index);
		unowned string? result = statement.column_text(index);
		var n_bytes =  statement.column_bytes(index);
		if (result != null)
		{
			var result_len = result.length;
			if (result_len != n_bytes)
				warning("Fetch string: Result may be truncated. Original blob size was %d, but string size is %d.",
					n_bytes, result_len);
		}
		return result;
	}
	
	/**
	 * Fetch binary blob value from current database record
	 * 
	 * @param index    column index
	 * @return the binary blob value
	 * @throws DatabaseError if index is invalid
	 */
	public uint8[]? fetch_blob(int index) throws DatabaseError
	{
		check_index(index);
		unowned uint8[]? blob = (uint8[]?) statement.column_blob(index);
		blob.length =  statement.column_bytes(index);
		if (blob == null || blob.length == 0)
			return null;
		
		return blob; // dup array
	}
	
	/**
	 * Fetch GLib.Bytes value from current database record
	 * 
	 * @param index    column index
	 * @return the binary blob as GLib.Bytes value
	 * @throws DatabaseError if index is invalid
	 */
	public GLib.Bytes? fetch_bytes(int index) throws DatabaseError
	{
		var blob = fetch_blob(index);
		return blob != null ? new GLib.Bytes.take((owned) blob) : null;
	}
	
	/**
	 * Fetch GLib.ByteArray value from current database record
	 * 
	 * @param index    column index
	 * @return the binary blob as GLib.ByteArray value
	 * @throws DatabaseError if index is invalid
	 */
	public GLib.ByteArray? fetch_byte_array(int index) throws DatabaseError
	{
		var blob = fetch_blob(index);
		return blob != null ? new GLib.ByteArray.take((owned) blob) : null;
	}
	
	/**
	 * Check whether index is valid
	 * 
	 * @param index    column index
	 * @throws DatabaseError if index is invalid
	 */
	protected void check_index(int index) throws DatabaseError
	{
		if (n_columns == 0)
			throw new DatabaseError.RANGE("Result doesn't have any columns. |%s|", statement.sql());
		if (index < 0 || index >= n_columns)
			throw new DatabaseError.RANGE(
				"Index %d is not in range 0..%d. |%s|", index, n_columns - 1, statement.sql());
	}
	
	/**
	 * Throw an error on SQLite failure.
	 */
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		if (Drtdb.is_sql_error(result))
			throw convert_sqlite_error(result, connection.get_last_error_message(), sql, statement);
		return result;
	}
	
	/**
	 * Map column names to indexes and vice versa.
	 */
	private void map_column_names()
	{
		/*
		 * name -> index mapping is created because SQLite doesn't offer API to get column index for name.
		 * index -> name mapping is created because SQLite invalidates the previously returned column name
		 *     if sqlite3_column_name() is called again for the same column index.
		 * 
		 * http://sqlite.org/c3ref/column_name.html
		 */
		if (column_names == null || column_indexes.length == 0)
		{
			column_names = new string?[n_columns];
			for (var index = 0; index < n_columns; index++)
			{
				unowned string name = statement.column_name(index);
				column_indexes[name] = index;
				column_names[index] = name;
			}
		}
	}
}

} // namespace Drtdb
