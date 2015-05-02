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

public errordomain DatabaseError
{
	UNKNOWN,
	IOERROR,
	DATABASE_NOT_OPENED,
	GENERAL,
	RANGE,
	DATA_TYPE,
	NAME,
	MISMATCH,
	MISUSE,
	DOES_NOT_EXIST,
	TOO_MANY_RESULTS;
}

public bool is_type_supported(Type? type)
{
	return (
		type == null
		|| type == typeof(bool)
		|| type == typeof(int)
		|| type == typeof(int64)
		|| type == typeof(string)
		|| type == typeof(double)
		|| type == typeof(float)
		|| type == typeof(GLib.Bytes)
		|| type == typeof(GLib.ByteArray)
		|| type == typeof(void*)
	);
}

private (unowned ParamSpec)[] create_param_spec_list(ObjectClass class_spec, string[]? properties = null)
		throws DatabaseError
{
	(unowned ParamSpec)[] properties_list;
	if (properties == null || properties.length == 0)
	{
		properties_list = class_spec.list_properties();
	}
	else
	{
		properties_list = new (unowned ParamSpec)[properties.length];
		for (var i = 0; i < properties.length; i++)
		{
			properties_list[i] = class_spec.find_property(properties[i]);
			if (properties_list[i] == null)
				throw new DatabaseError.NAME("There is no property named '%s'.", properties[i]);
		}
	}
	return properties_list;
}

// http://www.sqlite.org/rescode.html
private static int convert_error(Sqlite.Database? db, int result, string? sql=null,
	Sqlite.Statement? stm = null) throws DatabaseError
{
	switch (result)
	{
		case Sqlite.OK:
		case Sqlite.ROW:
		case Sqlite.DONE:
			return result;
		
	}
	var msg = "SQLite Error %d: %s. |%s|".printf(
		result,
		db != null ? db.errmsg() : "(unknown database)",
		sql ?? (stm != null ? stm.sql() : null));
	throw new DatabaseError.GENERAL(msg);
}

/**
 * Usage:
 * 
 * {{{
 * throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
 * }}}
 */
public void throw_if_cancelled(Cancellable? cancellable, string? method=null, string? file=null, int line=0)
	throws IOError
{
    if (cancellable != null && cancellable.is_cancelled())
        throw new IOError.CANCELLED("Operation was cancelled in %s (%s:%d).", method, file, line);
}


private inline string escape_sql_id(string sql)
{
	return sql.replace("\"", "\"\"");
}

} // namespace Dioritedb
