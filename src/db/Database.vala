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
 * SQLite database object
 */
public class Database: GLib.Object, Queryable
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
	private HashTable<Type, ObjectSpec> object_specs;
	
	/**
	 * Creates new database object
	 * 
	 * @param db_file    corresponding database file
	 */
	public Database (File db_file)
	{
		GLib.Object(db_file: db_file);
		object_specs = new HashTable<Type, ObjectSpec>(Diorite.Types.type_hash, Diorite.Types.type_equal);
	}
	
	/**
	 * Open database.
	 * 
	 * Once database is opened, master connection can be used and new database connections can be created.
	 * 
	 * If database file does not exist, new empty database file is created.
	 * 
	 * @param cancellable    Cancellable object.
	 * @throws GLib.Error when operation is cancelled.
	 * @throws DatabaseError when database cannot be opened.
	 */
	public virtual void open(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		return_if_fail(!opened);
		
		var db_dir = db_file.get_parent();
        if (!db_dir.query_exists(cancellable))
			db_dir.make_directory_with_parents(cancellable);
			
		if (db_file.query_exists(cancellable) && db_file.query_file_type(0, cancellable) != FileType.REGULAR)
			throw new DatabaseError.IOERROR("'%s' exists, but is not a file.", db_file.get_path());
		
		master_connection = open_connection(cancellable, true);
		opened = true;
	}
	
	/**
	 * Close database
	 * 
	 * Once database is closed, master connection is also closed and new database connections cannot be created.
	 * @param cancellable    Cancellable object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public virtual void close(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		return_if_fail(opened);
		master_connection = null;
		opened = false;
	}
	
	/**
	 * Execute a sql query on master database conection
	 * 
	 * @param sql            SQL query
	 * @param cancellable    Cancellable object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public void exec(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		get_master_connection().exec(sql, cancellable);
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
	public RawQuery query(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		return get_master_connection().query(sql, cancellable);
	}
	
	/**
	 * Create new ORM query
	 * 
	 * @param sql_filter     SQL condidions for filtering of objects
	 * @param cancellable    Cancellable object
	 * @return new ORM query object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public ObjectQuery<T> query_objects<T>(string? sql_filter=null, Cancellable? cancellable=null) 
		throws GLib.Error, DatabaseError
	{
		return get_master_connection().query_objects<T>(sql_filter, cancellable);
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
		return get_master_connection().get_object<T>(pk, cancellable);
	}
	
	/**
	 * Add ORM object specification
	 * 
	 * @param spec    ORM object specification
	 */
	public void add_object_spec(ObjectSpec spec)
	{
		lock (object_specs)
		{
			object_specs[spec.object_type] = spec;
		}
	}
	
	/**
	 * Retrieve ORM object specification for given type
	 * 
	 * @param type    {@link GLib.Object} type
	 * @return ORM object spec or `null` if it is not found
	 */
	public ObjectSpec? get_object_spec(Type type)
	{
		lock (object_specs)
		{
			return object_specs[type];
		}
	}
	
	/**
	 * Get master database connection
	 * 
	 * @throws DatabaseError when database is closed
	 * @return master database connection
	 */
	private Connection get_master_connection() throws DatabaseError
	{
		throw_if_not_opened();
		return master_connection;
	}
	
	/**
	 * Open new database connection
	 * @param cancellable    Cancellable object
	 * @param master         If the master connection is to be opened
	 * @return new database connection
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	private Connection open_connection(Cancellable? cancellable=null, bool master=false) throws GLib.Error, DatabaseError
	{
		throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
		if (!master)
			throw_if_not_opened();
		return new Connection(this, cancellable);
	}
	
	/**
	 * Throw an error if database is closed
	 * 
	 * @throws DatabaseError if database is closed
	 */
	private inline void throw_if_not_opened() throws DatabaseError
	{
		if (!opened)
			throw new DatabaseError.DATABASE_NOT_OPENED("Database '%s' is not opened.", db_file.get_path());
	}
}

} // namespace Dioritedb
