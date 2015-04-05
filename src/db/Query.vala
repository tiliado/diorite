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

public class Query : GLib.Object
{
	public Connection connection {get; private set;}
	private Sqlite.Statement statement = null;
	
	public Query(Connection connection, string sql) throws DatabaseError
	{
		this.connection = connection;
		throw_on_error(connection.db.prepare_v2(sql, sql.length, out statement), sql);
	}
	
	public void exec(Cancellable? cancellable=null) throws Error, DatabaseError
	{
		do
		{
			throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		}
		while (throw_on_error(statement.step()) != Sqlite.DONE);
	}
	
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		return Dioritedb.convert_error(connection.db, result, sql, statement);
	}
}

} // namespace Dioritedb
