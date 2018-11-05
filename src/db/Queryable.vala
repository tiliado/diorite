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

/**
 * SQLite queryable object
 */
public interface Queryable: GLib.Object {
    /**
     * Execute a sql query on database conection
     *
     * @param sql            SQL query
     * @param cancellable    Cancellable object
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public abstract void exec(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError;

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
    public abstract Query query(string sql, Cancellable? cancellable=null) throws GLib.Error, DatabaseError;


    /**
     * Get ORM objects
     *
     * @param cancellable    Cancellable object
     * @return new ORM query object
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public abstract ObjectQuery<T> get_objects<T>(Cancellable? cancellable=null) throws GLib.Error, DatabaseError;

    /**
     * Get a single ORM object
     *
     * @param pk             value of primary key
     * @param cancellable    Cancellable object
     * @return new ORM object
     * @throws GLib.IOError when the operation is cancelled
     * @throws DatabaseError when operation fails
     */
    public abstract T get_object<T>(GLib.Value pk, Cancellable? cancellable=null) throws GLib.Error, DatabaseError;

    public abstract unowned string? get_last_error_message();
}

} // namespace Drtdb
