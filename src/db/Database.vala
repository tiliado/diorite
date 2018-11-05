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

namespace Drtdb {

[CCode(cname="sqlite3_errstr")]
private extern unowned string sqlite3_errstr(int errcode);

/**
 * SQLite database object
 */
public class Database: GLib.Object, Queryable {

    public File db_file {get; construct;}
    public OrmManager orm {get; construct;}

    private bool _opened = false;
    public bool opened {
        get {
            lock (_opened) {
                return _opened;
            }
        }
        private set {
            lock (_opened) {
                _opened = value;
            }
        }
    }

    private Connection? master_connection = null;

    /**
     * Creates new database object
     *
     * @param db_file    corresponding database file
     * @param orm        Object Relationship Mapping manager
     */
    public Database (File db_file, OrmManager? orm=null) {
        GLib.Object(db_file: db_file, orm: orm ?? new OrmManager());
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
    public virtual void open(Cancellable? cancellable=null) throws GLib.Error, DatabaseError {
        throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
        return_if_fail(!opened);

        var db_dir = db_file.get_parent();
        if (!db_dir.query_exists(cancellable))
        db_dir.make_directory_with_parents(cancellable);

        if (db_file.query_exists(cancellable) && db_file.query_file_type(0, cancellable) != FileType.REGULAR)
        throw new DatabaseError.IOERROR("'%s' exists, but is not a file.", db_file.get_path());

        master_connection = open_connection_internal(cancellable, true);
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
    public virtual void close(Cancellable? cancellable=null) throws GLib.Error, DatabaseError {
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
    public void exec(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError {
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
    public Query query(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError {
        return get_master_connection().query(sql, cancellable);
    }

    /**
     * Create new raw data query with values
     *
     * After query is created, primitive data types can still be bound prior execution.
     *
     * @param cancellable    Cancellable object
     * @param sql            SQL query with {@link BindExpression} syntax
     * @param ...            Values to be bound
     * @return new query object for further modifications prior execution
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public Query query_with_values(Cancellable? cancellable, string sql, ...)
    throws GLib.Error, DatabaseError {
        return get_master_connection().query_with_values_va(cancellable, sql, va_list());
    }

    /**
     * Create new raw data query with values
     *
     * After query is created, primitive data types can still be bound prior execution.
     *
     * @param cancellable    Cancellable object
     * @param sql            SQL query with {@link BindExpression} syntax
     * @param args           Values to be bound
     * @return new query object for further modifications prior execution
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public Query query_with_values_va(Cancellable? cancellable, string sql, va_list args)
    throws GLib.Error, DatabaseError {
        return get_master_connection().query_with_values_va(cancellable, sql, args);
    }

    /**
     * Get ORM objects
     *
     * @param cancellable    Cancellable object
     * @return new ORM query object
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public ObjectQuery<T> get_objects<T>(Cancellable? cancellable=null) throws GLib.Error, DatabaseError {
        return get_master_connection().get_objects<T>(cancellable);
    }

    /**
     * Create new ORM query
     *
     * @param sql_filter     SQL conditions for filtering of objects (with {@link BindExpression})
     * @param cancellable    Cancellable object
     * @param ...            Data to bind to the query placeholders
     * @return new ORM query object
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public ObjectQuery<T> query_objects<T>(Cancellable? cancellable, string? sql_filter, ...)
    throws GLib.Error, DatabaseError {
        return get_master_connection().query_objects_va<T>(cancellable, sql_filter, va_list());
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
    throws GLib.Error, DatabaseError {
        return get_master_connection().get_object<T>(pk, cancellable);
    }

    /**
     * Return last error message
     *
     * @return the last error message
     */
    public unowned string? get_last_error_message() {
        try {
            return get_master_connection().get_last_error_message();
        } catch (DatabaseError e) {
            return null;
        }
    }

    /**
     * Get master database connection
     *
     * @throws DatabaseError when database is closed
     * @return master database connection
     */
    private Connection get_master_connection() throws DatabaseError {
        throw_if_not_opened();
        return master_connection;
    }

    /**
     * Open new database connection
     * @param cancellable    Cancellable object
     * @return new database connection
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public Connection open_connection(Cancellable? cancellable=null) throws GLib.Error, DatabaseError {
        return open_connection_internal(cancellable, false);
    }

    /**
     * Open new database connection
     * @param cancellable    Cancellable object
     * @param master         If the master connection is to be opened
     * @return new database connection
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    protected Connection open_connection_internal(Cancellable? cancellable, bool master) throws GLib.Error, DatabaseError {
        throw_if_cancelled(cancellable, GLib.Log.METHOD, GLib.Log.FILE, GLib.Log.LINE);
        if (!master)
        throw_if_not_opened();

        Sqlite.Database db;
        var result = Sqlite.Database.open_v2(
            db_file.get_path(), out db, Sqlite.OPEN_READWRITE|Sqlite.OPEN_CREATE, null);
        if (Drtdb.is_sql_error(result))
        throw convert_sqlite_error(result, db != null ? db.errmsg() : sqlite3_errstr(result));
        return new Connection((owned) db, orm);
    }

    /**
     * Throw an error if database is closed
     *
     * @throws DatabaseError if database is closed
     */
    private inline void throw_if_not_opened() throws DatabaseError {
        if (!opened)
        throw new DatabaseError.DATABASE_NOT_OPENED("Database '%s' is not opened.", db_file.get_path());
    }
}

} // namespace Drtdb
