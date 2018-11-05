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

/**
 * Check whether data type is supported
 *
 * @param type    the type to check
 * @return `true` if the given type is supported, `false` otherwise
 */
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

/**
 * Create a list of property specifications of a given ObjectClass
 *
 * @param class_spec    object class to retrieve property specifications from
 * @param properties    properties to retrieve specification for or `null` to use all properties
 * @return array of requested property specifications
 */
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

/**
 * Convert SQLite error code to DatabaseError
 *
 * SQLite error codes: [[http://www.sqlite.org/rescode.html]]
 *
 * Parameters `message`, `sql` and `stm` are optional but add more information
 * to the resulting error message.
 *
 * @param errno      sqlite error code
 * @param message    error message
 * @param sql        executed sql query
 * @param stm        sqlite statement
 * @return corresponding {@link DatabaseError}
 */
private DatabaseError convert_sqlite_error(int errno, string? message, string? sql=null,
	Sqlite.Statement? stm = null)
{
	var msg = "SQLite Error %d: %s. |%s|".printf(
		errno,
		message ?? "(unknown message)",
		sql ?? (stm != null ? stm.sql() : null));
	return new DatabaseError.GENERAL(msg);
}


/**
 * Check whether sqlite result code is an error code
 *
 * @param result_code    sqlite result code
 * @return `true` if the code corresponds to an error, `false` otherwise
 */
private inline bool is_sql_error(int result_code)
{
	switch (result_code)
	{
		case Sqlite.OK:
		case Sqlite.ROW:
		case Sqlite.DONE:
			return false;
		default:
			return true;
	}
}

/**
 * Throw {@link GLib.IOError} if an operation has been cancelled.
 *
 * Typical usage:
 *
 * {{{
 * throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
 * }}}
 *
 * @param cancellable    Cancellation object.
 * @param method         Called method
 * @param file           Source code file
 * @param line           Source code line
 */
private void throw_if_cancelled(Cancellable? cancellable, string? method=null, string? file=null, int line=0)
	throws IOError
{
    if (cancellable != null && cancellable.is_cancelled())
        throw new IOError.CANCELLED("Operation was cancelled in %s (%s:%d).", method, file, line);
}

/**
 * Escape SQL identifier
 *
 * @param sql_id    SQL id to escape
 * @return escaped id
 */
private inline string escape_sql_id(string sql_id)
{
	return sql_id.replace("\"", "\"\"");
}

} // namespace Drtdb
