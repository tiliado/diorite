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

namespace Drtdb
{

/**
 * Cursor to browse set of ORM objects
 */
public class ObjectCursor<T>
{
	public uint counter {get; private set; default=0;}
	private OrmManager orm;
	private Cancellable? cancellable;
	private Result result;
	
	/**
	 * Creates new ObjectCursor
	 * 
	 * @param orm            ORM manager
	 * @param result         the result of ORM query
	 * @param cancellable    Cancelable object
	 */
	public ObjectCursor(OrmManager orm, Result result, Cancellable? cancellable=null)
	{
		this.orm = orm;
		this.result = result;
		this.cancellable = cancellable;
	}
	
	/**
	 * Return iterator.
	 * 
	 * @return `this` object
	 */
	public ObjectCursor<T> iterator()
	{
		return this;
	}
	
	/**
	 * Advance the cursor
	 * 
	 * @return `true` if there is still data
	 */
	public bool next() throws Error, DatabaseError
	{
		 if (result.next())
		 {
			 counter++;
			 return true;
		 }
		 return false;
	}
	
	/**
	 * Get object under cursor
	 * 
	 * @return current object
	 */
	public T get() throws Error, DatabaseError
	{
		return orm.create_object<T>(result);
	}
}

} // namespace Drtdb
