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

public class ObjectSpec
{
	public Type object_type {get; private set;}
	public unowned ParamSpec primary_key {get; private set;}
	public (unowned ParamSpec)[] properties {get; private set;}
	
	public ObjectSpec(Type type, string primary_key, string[]? properties=null) throws DatabaseError
	{
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		var class_spec = (ObjectClass) type.class_ref();
		var primary_pspec = class_spec.find_property(primary_key);
		if (primary_pspec == null)
			throw new DatabaseError.NAME("There is no property named '%s'.", primary_key);
		this.with_pspecs(type, primary_pspec, create_param_spec_list(class_spec, properties));
	}
	
	public ObjectSpec.with_pspecs(Type type, ParamSpec primary_key, (unowned ParamSpec)[] properties) throws DatabaseError
	{
		if (!type.is_object())
			throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());
		this.object_type = type;
		this.properties = properties;
		this.primary_key = primary_key;
	}
}

} // namespace Dioritedb
