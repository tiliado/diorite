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

public class ObjectQuery<T> : Query
{
	private (unowned ParamSpec)[] properties;
	
	public ObjectQuery(Connection connection, string sql, (unowned ParamSpec)[] properties) throws Error, DatabaseError
	{
		DatabaseError caught_error;
		base.out_error(connection, sql, out caught_error);
		if (caught_error != null)
			throw caught_error;
		this.properties = properties;
	}
	
	public T get_one(Cancellable? cancellable=null) throws Error, DatabaseError
	{
		check_not_executed_and_set(true);
		var result = new Result(this);
		if (!result.next(cancellable))
			throw new DatabaseError.DOES_NOT_EXIST("No data has been returned for object query.");
		var object = result.create_object_pspec<T>(properties);
		if (result.next(cancellable))
			throw new DatabaseError.TOO_MANY_RESULTS("More than one object have been returned for object query.");
		return object;
	}
	
	public ObjectCursor<T> get_cursor(Cancellable? cancellable=null) throws Error, DatabaseError
	{
		check_not_executed_and_set(true); 
		return new ObjectCursor<T>(new Result(this), properties, cancellable);
	}
	
	public ObjectCursor<T> iterator() throws Error, DatabaseError
	{
		return get_cursor();
	}
	
	public new ObjectQuery<T> bind(int index, GLib.Value? value) throws DatabaseError
	{
		base.bind(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_null(int index) throws DatabaseError
	{
		base.bind_null(index);
		return this;
	}
	
	public new ObjectQuery<T> bind_bool(int index, bool value) throws DatabaseError
	{
		base.bind_bool(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_int(int index, int value) throws DatabaseError
	{
		base.bind_int(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_int64(int index, int64 value) throws DatabaseError
	{
		base.bind_int64(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_string(int index, string? value) throws DatabaseError
	{
		base.bind_string(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_double(int index, double value) throws DatabaseError
	{
		base.bind_double(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_blob(int index, uint8[] value) throws DatabaseError
	{
		base.bind_blob(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_bytes(int index, GLib.Bytes? value) throws DatabaseError
	{
		base.bind_bytes(index, value);
		return this;
	}
	
	public new ObjectQuery<T> bind_byte_array(int index, GLib.ByteArray? value) throws DatabaseError
	{
		base.bind_byte_array(index, value);
		return this;
	}
}

} // namespace Dioritedb
