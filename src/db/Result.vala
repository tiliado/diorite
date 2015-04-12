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
	
	public Result(Query query)
	{
		this.query = query;
		this.statement = query.statement;
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
		return !done;
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
}

} // namespace Dioritedb
