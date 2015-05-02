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

public class Result : GLib.Object
{
	public Query query {get; private set;}
	public int n_columns {get; private set; default = -1;}
	public int counter {get; private set; default = 0;}
	private unowned Sqlite.Statement statement;
	private HashTable<unowned string, int> column_indexes;
	private (unowned string)[]? column_names;
	
	public Result(Query query)
	{
		this.query = query;
		this.statement = query.statement;
		column_indexes = new HashTable<unowned string, int>(str_hash, str_equal);
		column_names = null;
	}
	
	public bool next(Cancellable? cancellable=null) throws Error, DatabaseError
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
	
	public int get_column_index(string name)
	{
		map_column_names();
		int index;
		if (column_indexes.lookup_extended(name, null, out index))
			return index;
		return -1;
	}
	
	public unowned string? get_column_name(int index)
	{
		map_column_names();
		if (index < 0 || index >= n_columns)
			return null;
		return column_names[index];
	}
	
	public T? create_object<T>(string[]? properties = null) throws DatabaseError
	{
		var type = typeof(T);
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		var properties_list = create_param_spec_list((ObjectClass) type.class_ref(), properties);
		return create_object_pspec<T>(properties_list);
	}
	
	public T? create_object_pspec<T>((unowned ParamSpec)[] properties) throws DatabaseError
	{
		var type = typeof(T);
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		Parameter[] parameters = {};
		foreach (var property in properties)
		{
			
			var index = get_column_index(property.name);
			if (index < 0)
				throw new DatabaseError.NAME("There is no column named '%s'.", property.name);
				
			var value = fetch_value_of_type(index, property.value_type);
			if (value == null)
				value = GLib.Value(property.value_type);
			parameters += GLib.Parameter(){name = property.name, value = value};
		}
		
		return (T) GLib.Object.newv(type, parameters);
	}
	
	public void fill_object(GLib.Object object, string[]? properties = null) throws DatabaseError
	{
		var type = object.get_type();
		var properties_list = create_param_spec_list((ObjectClass) type.class_ref(), properties);
		foreach (var property in properties_list)
		{
			var index = get_column_index(property.name);
			if (index < 0)
				throw new DatabaseError.NAME("There is no column named '%s'.", property.name);
			
			var value = fetch_value_of_type(index, property.value_type);
			if (value == null)
				value = GLib.Value(property.value_type);
				
			if ((property.flags & ParamFlags.WRITABLE) != 0
			&& (property.flags & ParamFlags.CONSTRUCT_ONLY) == 0)
			{
				object.set_property(property.name, value);
			}
				
			else if ((property.flags & ParamFlags.READABLE) != 0)
			{
				var current_value = GLib.Value(property.value_type);
				object.get_property(property.name, ref current_value);
				if (!Diorite.Value.equal(current_value, value))
					throw new DatabaseError.MISMATCH("Read-only value of property '%s' doesn't match database data.", property.name);
			}
		}
	}
	
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
	
	public bool fetch_is_null(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_type(index) == Sqlite.NULL;
	}
	
	public int fetch_int(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_int(index);
	}
	
	public int64 fetch_int64(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_int64(index);
	}
	
	public bool fetch_bool(int index) throws DatabaseError
	{
		return fetch_int(index) != 0;
	}
	
	public double fetch_double(int index) throws DatabaseError
	{
		check_index(index);
		return statement.column_double(index);
	}
	
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
	
	public uint8[]? fetch_blob(int index) throws DatabaseError
	{
		check_index(index);
		unowned uint8[]? blob = (uint8[]?) statement.column_blob(index);
		blob.length =  statement.column_bytes(index);
		if (blob == null || blob.length == 0)
			return null;
		
		return blob; // dup array
	}
	
	public GLib.Bytes? fetch_bytes(int index) throws DatabaseError
	{
		var blob = fetch_blob(index);
		return blob != null ? new GLib.Bytes.take((owned) blob) : null;
	}
	
	public GLib.ByteArray? fetch_byte_array(int index) throws DatabaseError
	{
		var blob = fetch_blob(index);
		return blob != null ? new GLib.ByteArray.take((owned) blob) : null;
	}
	
	protected void check_index(int index) throws DatabaseError
	{
		if (n_columns == 0)
			throw new DatabaseError.RANGE("Result doesn't have any columns. |%s|", statement.sql());
		if (index < 0 || index >= n_columns)
			throw new DatabaseError.RANGE(
				"Index %d is not in range 0..%d. |%s|", index, n_columns - 1, statement.sql());
	}
	
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		return Dioritedb.convert_error(query.connection.db, result, sql, statement);
	}
	
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

} // namespace Dioritedb
