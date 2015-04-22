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

public class RawQuery : Query
{
	public RawQuery(Connection connection, string sql) throws DatabaseError
	{
		DatabaseError caught_error;
		base.out_error(connection, sql, out caught_error);
		if (caught_error != null)
			throw caught_error;
	}
	
	public Result exec(Cancellable? cancellable=null) throws Error, DatabaseError
	{
		check_not_executed_and_set(true);
		var result = new Result(this);
		result.next(cancellable);
		return result;
	}
	
	/**
	 * Usage:
	 * 
	 * {{{
	 * Result result = query.exec_select();
	 * while (result.next())
	 * {
	 *        // process data
	 * }
	 * }}}
	 */
	public Result exec_select(Cancellable? cancellable=null) throws Error, DatabaseError
	{
		check_not_executed_and_set(true);
		return new Result(this);
	}
	
	public new RawQuery bind(int index, GLib.Value? value) throws DatabaseError
	{
		base.bind(index, value);
		return this;
	}
	
	public new RawQuery bind_null(int index) throws DatabaseError
	{
		base.bind_null(index);
		return this;
	}
	
	public new RawQuery bind_bool(int index, bool value) throws DatabaseError
	{
		base.bind_bool(index, value);
		return this;
	}
	
	public new RawQuery bind_int(int index, int value) throws DatabaseError
	{
		base.bind_int(index, value);
		return this;
	}
	
	public new RawQuery bind_int64(int index, int64 value) throws DatabaseError
	{
		base.bind_int64(index, value);
		return this;
	}
	
	public new RawQuery bind_string(int index, string? value) throws DatabaseError
	{
		base.bind_string(index, value);
		return this;
	}
	
	public new RawQuery bind_double(int index, double value) throws DatabaseError
	{
		base.bind_double(index, value);
		return this;
	}
	
	public new RawQuery bind_blob(int index, uint8[] value) throws DatabaseError
	{
		base.bind_blob(index, value);
		return this;
	}
	
	public new RawQuery bind_bytes(int index, GLib.Bytes? value) throws DatabaseError
	{
		base.bind_bytes(index, value);
		return this;
	}
	
	public new RawQuery bind_byte_array(int index, GLib.ByteArray? value) throws DatabaseError
	{
		base.bind_byte_array(index, value);
		return this;
	}
}

} // namespace Dioritedb
