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

[Flags]
public enum ApiFlags {
	PRIVATE,
	READABLE,
	WRITABLE,
	SUBSCRIBE;
}

public delegate Variant? ApiHandler(GLib.Object source, ApiParams? params) throws GLib.Error;

public class ApiMethod : ApiCallable {
	public ApiParam[]? params {get; protected set;}
	private ApiHandler handler;
	
	public ApiMethod(string path, ApiFlags flags, ApiParam[]? params, owned ApiHandler handler,
	string? description) {
		this.path = path;
		this.flags = flags;
		this.params = params;
		this.handler = (owned) handler;
		this.description = description;
	}
	
	public override void run(GLib.Object conn, Variant? data, out Variant? response) throws GLib.Error {
		if (params == null || params.length == 0) {
			response = handler(conn, null);
			return;
		}
		
		if (data == null) {
			throw new ApiError.INVALID_PARAMS(
				"Method '%s' requires %d parameters but no parameters have been provided.",
				path, params.length);
		}
		
		Variant?[] handler_params;
		var params_type = ApiChannel.get_params_type(data);
		var data_type = data.get_type();
		if (params_type == "tuple") {
			if (!data_type.is_container() || data_type.is_subtype_of(VariantType.DICTIONARY)) {
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' call expected a tuple of parameters, but type of '%s' received.",
					path, data.get_type_string());
			}
			if (data.n_children() != params.length) {
				throw new ApiError.INVALID_PARAMS(
					"Method '%s' requires %d parameters but %d parameters have been provided.",
					path, params.length, (int) data.n_children());
			}
					
			handler_params = new Variant?[params.length];
			for (var i = 0; i < params.length; i++) {
				var param = params[i];
				var child = unbox_variant(data.get_child_value(i));
				handler_params[i] = param.get_value(path, child);
			}
		} else {
			if (data.get_type_string() != "(a{smv})") {
				MessageListener.check_type_string(data, "a{smv}");
			}
			var dict = data.get_type_string() == "(a{smv})" ? data.get_child_value(0) : data;
			handler_params = new Variant?[params.length];
			for (var i = 0; i < params.length; i++) {
				var param = params[i];
				Variant? entry = dict.lookup_value(param.name, null);
				if (entry == null && param.required) {
					throw new ApiError.INVALID_PARAMS(
						"Method '%s' requires the '%s' parameter of type '%s', but it has been omitted.",
						path, param.name, param.type_string);
				}
				
				if (entry == null) {
					entry = param.default_value;
				}
				handler_params[i] = param.get_value(path, entry == null ? null : unbox_variant(entry));
			}
		}
		response = handler(conn, new ApiParams(this, handler_params));
	}
}

} // namespace Drt
