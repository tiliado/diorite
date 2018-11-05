/*
 * Copyright 2014-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

public errordomain RpcError {
    UNKNOWN,
    REMOTE_ERROR,
    UNSUPPORTED,
    IOERROR,
    INVALID_RESPONSE,
    INVALID_REQUEST,
    INVALID_ARGUMENTS,
    NOT_READY;

    public extern static GLib.Quark quark();
}

public errordomain ApiError {
    UNKNOWN,
    INVALID_REQUEST,
    INVALID_PARAMS,
    PRIVATE_FLAG,
    READABLE_FLAG,
    WRITABLE_FLAG,
    SUBSCRIBE_FLAG,
    API_TOKEN_REQUIRED;

    public extern static GLib.Quark quark();
}

[Flags]
public enum RpcFlags {
    PRIVATE,
    READABLE,
    WRITABLE,
    SUBSCRIBE;
}

public delegate void RpcHandler(RpcRequest request) throws GLib.Error;

namespace Rpc {
    public const string TYPE_STRING_ANY = "#ANY#";
    public const string RESPONSE_OK = "OK";
    public const string RESPONSE_ERROR = "ERROR";

    public void check_type_string(Variant? data, string? type_string) throws GLib.Error {
        if (type_string != null && type_string == TYPE_STRING_ANY) {
            return;
        }
        if (data == null && type_string != null) {
            throw new RpcError.INVALID_ARGUMENTS("Invalid data type null, expected '%s'.", type_string);
        }
        if (data != null) {
            unowned string data_type_string = data.get_type_string();
            if (type_string == null) {
                throw new RpcError.INVALID_ARGUMENTS(
                    "Invalid data type '%s', expected null.", data_type_string);
            }
            if (!data.check_format_string(type_string, false)) {
                throw new RpcError.INVALID_ARGUMENTS(
                    "Invalid data type '%s', expected '%s'.", data_type_string, type_string);
            }
        }
    }

    public string get_params_type(GLib.Variant? params) throws RpcError {
        if (params == null ) {
            return "tuple";
        }
        var type = params.get_type();
        if (type.is_tuple()) {
            return "tuple";
        }
        if (type.is_array()) {

            return type.is_subtype_of(VariantType.DICTIONARY) ? "dict" : "tuple";
        }
        throw new RpcError.UNSUPPORTED("Param type %s is not supported.", params.get_type_string());
    }

    private string create_path(string name) {
        var dir_path = Path.build_filename(Environment.get_user_cache_dir(), "lds");
        try {
            File.new_for_path(dir_path).make_directory_with_parents();
        } catch (GLib.Error e) {
            if (!(e is GLib.IOError.EXISTS)) {
                critical("Failed to create directory '%s'. %s", dir_path, e.message);
            }
        }
        return Path.build_filename(dir_path, name);
    }
}

} // namespace Drt
