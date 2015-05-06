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

public class Connection: GLib.Object
{
	public unowned Database database {get; private set;}
	internal Sqlite.Database db;
	
	public Connection(Database database, Cancellable? cancellable=null) throws Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		this.database = database;
		throw_on_error(Sqlite.Database.open_v2(
			database.db_file.get_path(), out db, Sqlite.OPEN_READWRITE|Sqlite.OPEN_CREATE, null));
	}
	
	public void exec(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		throw_on_error(db.exec(sql, null, null), sql);
	}
	
	public RawQuery query(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		return new RawQuery(this, sql);
	}
	
	public ObjectQuery<T> query_objects<T>(string? sql_filter=null, Cancellable? cancellable=null)
		throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		var type = typeof(T);
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		var object_spec = database.get_object_spec(type);
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
		
		if (sql_filter != null && sql_filter[0] != '\0')
			sql.append(sql_filter);
		
		return new ObjectQuery<T>(this, sql.str);
	}
	
	public T get_object<T>(GLib.Value pk, Cancellable? cancellable=null)
		throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		var type = typeof(T);
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		
		var object_spec = database.get_object_spec(type);
		if (object_spec == null)
			throw new DatabaseError.DATA_TYPE("ObjectSpec for %s has not been found.", type.name());
		
		/* Full qualified column name with table name are used because SQLite treat non-existent
		 * column names in quotes as string literals otherwise. */
		var table_escaped = escape_sql_id(object_spec.table_name);
		var column_escaped = escape_sql_id(object_spec.primary_key.name);
		return query_objects<T>(
			"WHERE \"%s\".\"%s\" == ?1".printf(table_escaped, column_escaped), cancellable)
			.bind(1, pk).get_one(cancellable);
	}
	
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		return Dioritedb.convert_error(db, result, sql);
	}
}

} // namespace Dioritedb
