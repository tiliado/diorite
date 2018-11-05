/*
 * Copyright 2016-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt {

/**
 * Class containing parameters of a method call.
 *
 * Parameters are returned in same order as in parameters specification in method declaration.
 */
public class RpcRequest {
    public RpcConnection connection {get; private set;}
    public RpcMethod method {get; private set;}
    private Variant?[] data;
    private int counter = 0;
    private uint uid;
    bool response_sent = false;

    public RpcRequest(RpcConnection connection, uint uid, RpcMethod method, Variant?[] data) {
        this.connection = connection;
        this.method = method;
        this.data = data;
        this.uid = uid;
    }

    ~RpcRequest() {
        if (!response_sent) {
            fail(new RpcError.INVALID_RESPONSE("No response have been sent."));
        }
    }

    /**
     * Returns index of the current parameter under cursor.
     *
     * @return Index of a parameter.
     */
    public int get_current_index() {
        return counter;
    }

    /**
     * Returns number of parameters available
     *
     * @return Number of a parameter.
     */
    public int get_length() {
        return data.length;
    }

    /**
     * Reset parameter index back to 1.
     */
    public void reset() {
        counter = 0;
    }

    /**
     * Return string value and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return string value or null.
     */
    public string? pop_string() {
        var variant = next(typeof(StringParam));
        return variant == null ? null : variant.get_string();;
    }

    /**
     * Return boolean value and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return boolean value.
     */
    public bool pop_bool() {
        return next(typeof(BoolParam)).get_boolean();
    }

    /**
     * Return double value and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return double value.
     */
    public double pop_double() {
        return next(typeof(DoubleParam)).get_double();
    }

    /**
     * Return int value and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return int value.
     */
    public int pop_int() {
        return (int) next(typeof(IntParam)).get_int32();
    }

    /**
     * Return Variant value and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return Variant value.
     */
    public Variant? pop_variant() {
        return next(typeof(VariantParam));
    }

    /**
     * Return VariantIterator of a Variant array and advance cursor.
     *
     * Aborts on invalid type or out of bounds access.
     *
     * @return VariantIter iterator of the variant array.
     */
    public VariantIter? pop_variant_array() {
        var value = next(typeof(VarArrayParam));
        return value == null ? null : value.iterator();
    }

    /**
     * Return string[] value and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return string[] value. May be empty, but not null.
     */
    public string[] pop_strv() {
        var variant = next(typeof(StringArrayParam));
        return variant == null ? new string[] {} : variant.dup_strv();
    }

    /**
     * Return list of string values and advance cursor.
     *
     * Aborts on invalid type or out of bounds access.
     *
     * @return list of string values. May be empty.
     */
    public SList<string>pop_str_list() {
        SList<string> list = null;
        var array = next(typeof(StringArrayParam));
        var iter = array.iterator();
        unowned string str = null;
        while (iter.next("s", &str))
        list.prepend(str);
        list.reverse();
        return list;
    }

    /**
     * Return dictionary and advance cursor.
     *
     * Aborts on invalid time or out of bounds access.
     *
     * @return a dictionary. May be empty but not null.
     */
    public HashTable<string, Variant?> pop_dict() {
        return variant_to_hashtable(next(typeof(DictParam)));
    }

    private Variant? next(Type param_type) {
        var index = counter++;
        if (index >= data.length) {
            error(
                "Method '%s' receives only %d arguments. Access to index %d denied.",
                method.path, data.length, index);
        }
        var param =  method.params[index];
        if (Type.from_instance(param) != param_type) {
            error(
                "The parameter %d of method '%s' is of type '%s' but %s value requested.",
                index, method.path, Type.from_instance(param).name(), param_type.name());
        }
        return unbox_variant(data[index]);
    }

    /**
     * Send response back to the caller.
     *
     * @param data    Response data.
     */
    public void respond(Variant? data) {
        if (!response_sent) {
            connection.respond(uid, data);
            response_sent = true;
        }
    }

    /**
     * Send error back to the caller.
     *
     * @param e    Error.
     */
    public void fail(GLib.Error e) {
        if (!response_sent) {
            connection.fail(uid, e);
            response_sent = true;
        }
    }
}

} // namespace Drt
