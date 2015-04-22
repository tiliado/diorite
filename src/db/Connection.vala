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
	
	protected int throw_on_error(int result, string? sql=null) throws DatabaseError
	{
		return Dioritedb.convert_error(db, result, sql);
	}
}

} // namespace Dioritedb
