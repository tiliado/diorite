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
 * Object Relationship Mapping
 */
public class OrmManager : GLib.Object {
    private HashTable<Type, ObjectSpec> object_specs;

    /**
     * Create new OrmManager object.
     */
    public OrmManager() {
        object_specs = new HashTable<Type, ObjectSpec>(Drt.Types.type_hash, Drt.Types.type_equal);
    }

    /**
     * Add ORM object specification
     *
     * @param spec    ORM object specification
     */
    public void add_object_spec(ObjectSpec spec) {
        lock (object_specs) {
            object_specs[spec.object_type] = spec;
        }
    }

    /**
     * Retrieve ORM object specification for given type
     *
     * @param type    {@link GLib.Object} type
     * @return ORM object spec or `null` if it is not found
     */
    public ObjectSpec? get_object_spec(Type type) {
        lock (object_specs) {
            return object_specs[type];
        }
    }

    /**
     * Create ORM object from database record
     *
     * @param result    The corresponding database record.
     * @return object containing database data according to corresponding {@link ObjectSpec}
     * @throws DatabaseError if data type `T` is not supported or {@link ObjectSpec} is not found
     * @see OrmManager.add_object_spec
     */
    public T? create_object<T>(Result result) throws DatabaseError {
        var type = typeof(T);
        if (!type.is_object())
        throw new DatabaseError.DATA_TYPE("Data type %s is not supported.", type.name());

        var object_spec = get_object_spec(type);
        if (object_spec == null)
        throw new DatabaseError.DATA_TYPE("ObjectSpec for %s has not been found.", type.name());

        Value[] parameters = {};
        string[] names = {};
        foreach (var property in object_spec.properties) {
            var index = result.get_column_index(property.name);
            if (index < 0)
            throw new DatabaseError.NAME("There is no column named '%s'.", property.name);

            var value = result.fetch_value_of_type(index, property.value_type);
            if (value == null)
            value = GLib.Value(property.value_type);
            names += property.name;
            parameters += value;
        }
        return (T) GLib.Object.new_with_properties (type, names, parameters);
    }

    /**
     * Fill ORM object from database data
     *
     * @param object    the object to fill with database data
     * @param result    The corresponding database record.
     * @throws DatabaseError if corresponding {@link ObjectSpec} is not found
     */
    public void fill_object(GLib.Object object, Result result) throws DatabaseError {
        var type = object.get_type();
        var object_spec = get_object_spec(type);
        if (object_spec == null)
        throw new DatabaseError.DATA_TYPE("ObjectSpec for %s has not been found.", type.name());

        foreach (var property in object_spec.properties) {
            var index = result.get_column_index(property.name);
            if (index < 0)
            throw new DatabaseError.NAME("There is no column named '%s'.", property.name);

            var value = result.fetch_value_of_type(index, property.value_type);
            if (value == null)
            value = GLib.Value(property.value_type);

            if ((property.flags & ParamFlags.WRITABLE) != 0
            && (property.flags & ParamFlags.CONSTRUCT_ONLY) == 0) {
                object.set_property(property.name, value);
            } else if ((property.flags & ParamFlags.READABLE) != 0) {
                var current_value = GLib.Value(property.value_type);
                object.get_property(property.name, ref current_value);
                if (!Drt.Value.equal(current_value, value))
                throw new DatabaseError.MISMATCH("Read-only value of property '%s' doesn't match database data.", property.name);
            }
        }
    }
}

} // namespace Drtdb
