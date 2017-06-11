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
 * ObjectQuery class
 * 
 * Used for ORM queries.
 */
public class ObjectQuery<T> : GLib.Object
{
	// Query to retrieve objects.
	private Query query;
	private OrmManager orm;
	
	/**
	 * Creates new ObjectQuery object.
	 * 
	 * @param orm      ORM manager
	 * @param query    the corresponding {@link Query} to retrieve object data
	 */
	public ObjectQuery(OrmManager orm, Query query)
	{
		this.orm = orm;
		this.query = query;
	}
	
	/**
	 * Retrieve a single object.
	 * 
	 * @param cancellable    Cancellable object
	 * @return db record as a requested object
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails, e.g. no object or more then one object are found
	 */
	public T get_one(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		var result = query.get_result();
		if (!result.next(cancellable))
			throw new DatabaseError.DOES_NOT_EXIST("No data has been returned for object query.");
		var object = orm.create_object<T>(result);
		var initable = object as GLib.Initable;
		if (initable != null)
			initable.init(cancellable);
		if (result.next(cancellable))
			throw new DatabaseError.TOO_MANY_RESULTS("More than one object have been returned for object query.");
		return object;
	}
	
	/**
	 * Get cursor to browse resulting set of objects.
	 * 
	 * @param cancellable    Cancellable object
	 * @return data set cursor
	 * @throws GLib.IOError when the operation is cancelled
	 * @throws DatabaseError when operation fails
	 */
	public ObjectCursor<T> get_cursor(Cancellable? cancellable=null) throws GLib.Error, DatabaseError
	{
		return new ObjectCursor<T>(orm, query.get_result(), cancellable);
	}
}

} // namespace Dioritedb
