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

namespace Dioritedb
{

/**
 * SQLite Database Connection wrapper
 */
public class Connection: GLib.Object, Queryable
{
	public OrmManager orm {get; private set;}
	private Sqlite.Database db;
	
	/**
	 * Create new SQLite database connection wrapper
	 * 
	 * @param db     SQLite database connection
	 * @param orm    ORM Manager for object queries. An empty one is created if it is not provided.
	 */
	public Connection(owned Sqlite.Database db, OrmManager? orm)
	{
		this.orm = orm ?? new OrmManager();
		this.db = (owned) db;
	}
	
	/**
	 * Execute a sql query on database conection
	 * 
	 * @param sql            SQL query
	 * @param cancellable    Cancellable object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public void exec(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		throw_on_error(db.exec(sql, null, null), sql);
	}
	
	/**
	 * Create new raw data query
	 * 
	 * After query is created, primitive data types can be bound prior execution.
	 * 
	 * @param sql            SQL query
	 * @param cancellable    Cancellable object
	 * @return new query object for further modifications prior execution
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public Query query(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		Sqlite.Statement statement;
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		throw_on_error(db.prepare_v2(sql, sql.length, out statement), sql);
		return new Query(this, (owned) statement);
	}
	
	/**
	 * Create new raw data query with values
	 * 
	 * After query is created, primitive data types can still be bound prior execution.
	 * 
	 * @param cancellable    Cancellable object
	 * @param sql            SQL query with {@link BindExpression} syntax
	 * @param ...            Values to be bound
	 * @return new query object for further modifications prior execution
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public Query query_with_values(Cancellable? cancellable, string sql, ...)
		throws GLib.Error, DatabaseError
	{
		return query_with_values_va(cancellable, sql, va_list());
	}
	
	/**
	 * Create new raw data query with values
	 * 
	 * After query is created, primitive data types can still be bound prior execution.
	 * 
	 * @param cancellable    Cancellable object
	 * @param sql            SQL query with {@link BindExpression} syntax
	 * @param args           Values to be bound
	 * @return new query object for further modifications prior execution
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public Query query_with_values_va(Cancellable? cancellable, string sql, va_list args)
		throws GLib.Error, DatabaseError
	{
		var bind_expr = new BindExpression();
		bind_expr.parse_va(sql, args);
		unowned string sql_query = bind_expr.get_sql();
		Sqlite.Statement statement;
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		throw_on_error(db.prepare_v2(sql_query, sql_query.length, out statement), sql_query);
		return new Query(this, (owned) statement).bind_values(1, bind_expr.get_values());
	}
	
	/**
	 * Return last error message
	 * 
	 * @return the last error message
	 */
	public unowned string? get_last_error_message()
	{
		return db != null ? db.errmsg() : null;
	}
	
	/**
	 * Get ORM objects
	 * 
	 * @param cancellable    Cancellable object
	 * @return new ORM query object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public ObjectQuery<T> get_objects<T>(Cancellable? cancellable=null)
		throws GLib.Error, DatabaseError
	{
		return query_objects<T>(cancellable, null);
	}
	
	/**
	 * Create new ORM query
	 * 
	 * @param cancellable    Cancellable object
	 * @param filter         SQL conditions for filtering of objects (with {@link BindExpression})
	 * @param ...            Data to bind to the query placeholders
	 * @return new ORM query object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public ObjectQuery<T> query_objects<T>(Cancellable? cancellable, string? filter, ...)
		throws GLib.Error, DatabaseError
	{
		return query_objects_va<T>(cancellable, filter, va_list());
	}
	
	/**
	 * Create new ORM query
	 * 
	 * @param filter         SQL conditions for filtering of objects (with {@link BindExpression})
	 * @param cancellable    Cancellable object
	 * @param args           Data to bind to the query placeholders
	 * @return new ORM query object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public ObjectQuery<T> query_objects_va<T>(Cancellable? cancellable, string? filter, va_list args)
		throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		var type = typeof(T);
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		var object_spec = orm.get_object_spec(type);
		if (object_spec == null)
			throw new DatabaseError.DATA_TYPE("ObjectSpec for %s has not been found.", type.name());
		unowned (unowned ParamSpec)[] param_specs = object_spec.properties;
		var sql = new StringBuilder("SELECT");
		var table_name_escaped = escape_sql_id(object_spec.table_name);
		for (var i = 0; i <  param_specs.length; i++)
		{
			var param = param_specs[i];
			if (param.value_type == typeof(void*) || !is_type_supported(param.value_type))
				throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", param.value_type.name());
			
			if (i != 0)
				sql.append_c(',');
			/*
			 * 1. AS clause is used because SQLite doesn't guarantee column names in result set otherwise
			 * 2. Full qualified column names with table name are used because SQLite treat non-existent
			 *    column names in quotes as string literals otherwise.
			 */
			sql.append_printf(
				" \"%1$s\".\"%2$s\" AS \"%2$s\"", table_name_escaped, escape_sql_id(param.name));
		}
		sql.append_printf(" FROM \"%s\" ", table_name_escaped);
		
		BindExpression? bind_expr = (filter != null && filter != "") ? new BindExpression() : null;
		if (bind_expr != null)
		{
		bind_expr.parse_va(filter, args);
			sql.append(bind_expr.get_sql());
		}
		var query = this.query(sql.str, cancellable);
		if (bind_expr != null)
			query.bind_values(1, bind_expr.get_values());
		return new ObjectQuery<T>(orm, query);
	}
	
	/**
	 * Get a single ORM object
	 * 
	 * @param pk             value of primary key
	 * @param cancellable    Cancellable object
	 * @return new ORM object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public T get_object<T>(GLib.Value pk, Cancellable? cancellable=null)
		throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		var type = typeof(T);
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		var object_spec = orm.get_object_spec(type);
		if (object_spec == null)
			throw new DatabaseError.DATA_TYPE("ObjectSpec for %s has not been found.", type.name());
		
		/* Full qualified column name with table name are used because SQLite treat non-existent
		 * column names in quotes as string literals otherwise. */
		var table_escaped = escape_sql_id(object_spec.table_name);
		var column_escaped = escape_sql_id(object_spec.primary_key.name);
		var query = query_objects<T>(
			cancellable, "WHERE \"%s\".\"%s\" == ?v".printf(table_escaped, column_escaped), pk);
		return query.get_one(cancellable);
	}
	
	/**
	 * Throw error on SQLite failure.
	 */
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		if (Dioritedb.is_sql_error(result))
			throw convert_sqlite_error(result, get_last_error_message(), sql);
		return result;
	}
}

} // namespace Dioritedb
