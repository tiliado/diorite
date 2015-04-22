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

private extern const int SQLITE_TRANSIENT;

namespace Dioritedb
{

public abstract class Query : GLib.Object
{
	public Connection connection {get; private set;}
	internal Sqlite.Statement statement = null;
	protected int n_parameters = 0;
	protected bool executed = false;
	
	public Query(Connection connection, string sql) throws DatabaseError
	{
		init(connection, sql);
	}
	
	protected Query.out_error(Connection connection, string sql, out DatabaseError? error)
	{
		error = null;
		try
		{
			init(connection, sql);
		}
		catch (DatabaseError e)
		{
			error = e;
		}
	}
	
	private void init(Connection connection, string sql) throws DatabaseError
	{
		this.connection = connection;
		throw_on_error(connection.db.prepare_v2(sql, sql.length, out statement), sql);
		n_parameters = statement.bind_parameter_count();
	}
	
	public void reset(bool clear_bindings=false) throws Error, DatabaseError
	{
		throw_on_error(statement.reset());
		if (clear_bindings)
			throw_on_error(statement.clear_bindings());
		
		lock (executed)
		{
			executed = false;
		}
	}
	
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
	
	public Query bind_null(int index) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_null(index));
		return this;
	}
	
	public Query bind_bool(int index, bool value) throws DatabaseError
	{
		return bind_int(index, value ? 1 : 0);
	}
	
	public Query bind_int(int index, int value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_int(index, value));
		return this;
	}
	
	public Query bind_int64(int index, int64 value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_int64(index, value));
		return this;
	}
	
	public Query bind_string(int index, string? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_text(index, value));
		return this;
	}
	
	public Query bind_double(int index, double value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_double(index, value));
		return this;
	}
	
	public Query bind_blob(int index, uint8[] value) throws DatabaseError
	{
		check_index(index);
		check_not_executed();
		/* SQLITE_TRANSIENT is necessary to support query.bind(new uint8[]{1, 2, 3, 4}); */
		throw_on_error(statement.bind_blob(index, value, value.length, (DestroyNotify) SQLITE_TRANSIENT));
		return this;
	}
	
	public Query bind_bytes(int index, GLib.Bytes? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_blob(index, value.get_data(), (int) value.get_size(), null));
		return this;
	}
	
	public Query bind_byte_array(int index, GLib.ByteArray? value) throws DatabaseError
	{
		if (value == null)
			return bind_null(index);
		
		check_index(index);
		check_not_executed();
		throw_on_error(statement.bind_blob(index, value.data, (int) value.len, null));
		return this;
	}
	
	protected void check_not_executed() throws DatabaseError
	{
		lock (executed)
		{
			if (executed)
				throw new DatabaseError.MISUSE("Query has been already executed. |%s|", statement.sql());
		}
	}
	
	protected void check_not_executed_and_set(bool executed) throws DatabaseError
	{
		lock (this.executed)
		{
			if (this.executed)
				throw new DatabaseError.MISUSE("Query has been already executed. |%s|", statement.sql());
			this.executed = executed;
		}
	}
	
	protected int check_index(int index) throws DatabaseError
	{
		if (n_parameters == 0)
			throw new DatabaseError.RANGE("Query doesn't have parameters. |%s|", statement.sql());
		if (index <= 0 || index > n_parameters)
			throw new DatabaseError.RANGE(
				"Index %d is not in range 1..%d. |%s|", index, n_parameters, statement.sql());
		return index;
	}
	
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		return Dioritedb.convert_error(connection.db, result, sql, statement);
	}
}

} // namespace Dioritedb
