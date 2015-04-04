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

public class Database: GLib.Object
{
	
	public File db_file {get; construct;}
	
	private bool _opened = false;
	public bool opened
	{
		get
		{
			lock (_opened)
			{
				return _opened;
			}
		}
		private set
		{
			lock (_opened)
			{
				_opened = value;
			}
		}
	}
	
	private Connection? master_connection = null;
	
	public Database (File db_file)
	{
		GLib.Object(db_file: db_file);
	}
	
	public virtual void open(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		return_if_fail(!opened);
		
		var db_dir = db_file.get_parent();
        if (!db_dir.query_exists(cancellable))
			db_dir.make_directory_with_parents(cancellable);
			
		if (db_file.query_exists(cancellable) && db_file.query_file_type(0, cancellable) != FileType.REGULAR)
			throw new DatabaseError.IOERROR("'%s' exists, but is not a file.", db_file.get_path());
		
		master_connection = new Connection(this, cancellable);
		opened = true;
	}
	
	public virtual void close(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		return_if_fail(opened);
		master_connection = null;
		opened = false;
	}
	
	public virtual Connection get_master_connection(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		if (master_connection == null)
			master_connection = open_connection(cancellable);
		return master_connection;
	}
	
	public void exec(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		get_master_connection(cancellable).exec(sql, cancellable);
	}
	
	private Connection open_connection(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		throw_if_not_opened();
		return new Connection(this, cancellable);
	}
	
	private void throw_if_not_opened() throws DatabaseError
	{
		if (!opened)
			throw new DatabaseError.DATABASE_NOT_OPENED("Database '%s' is not opened.", db_file.get_path());
	}
}

} // namespace Dioritedb
