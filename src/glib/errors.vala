/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt
{

public errordomain Error
{
	INVALID_ARGUMENT,
	UNEXPECTED_RESULT,
	NOT_SUPPORTED,
	NOT_IMPLEMENTED,
	IOERROR,
	NOT_FOUND,
	ACCESS_DENIED;

	public extern static GLib.Quark quark();
}

public errordomain IOError
{
	CONN_FAILED,
	TIMEOUT,
	RW_FAILED,
	READ,
	WRITE,
	TOO_MANY_DATA,
	NOT_CONNECTED,
	OP_FAILED;

	public extern static GLib.Quark quark();
}


public string error_to_string(GLib.Error e) {
	unowned string raw_domain = e.domain.to_string();
	string domain = raw_domain.has_suffix("-quark") ? raw_domain.substring(0, raw_domain.length - 6) : raw_domain;
	string[] parts = domain.split_set("-_.");
	var pretty = new StringBuilder("");
	foreach (unowned string part in parts) {
		pretty.append(part.up(1)).append(part.substring(1));
	}
	pretty.append_printf("[%d]: ", e.code);
	pretty.append(e.message);
	if (!e.message.has_suffix(".")) {
		pretty.append_c('.');
	}
	return pretty.str;
}


public string error_vprintf(GLib.Error e, string format, va_list args) {
	string fmt;
	bool start = true;
	if (format.has_prefix("+")) {
		fmt = format.substring(1);
	} else if (format.has_suffix("+")) {
		fmt = format.substring(0, format.length - 1);
		start = false;
	} else {
		fmt = " " + format;
	}
	string text = fmt.vprintf(args);
	string error = error_to_string(e);
	return start ? text + error : error + text;
}


[PrintfFormat]
public string error_printf(GLib.Error e, string format, ...) {
	return error_vprintf(e, format, va_list());
}


public void print_error(GLib.Error e, string? text=null) {
	if (text != null) {
		stderr.puts(text);
		stderr.putc(' ');
	}
	stderr.puts(error_to_string(e));
	stderr.putc('\n');
}


[PrintfFormat]
public void printf_error(GLib.Error e, string format, ...) {
	stderr.puts(error_vprintf(e, format, va_list()));
	stderr.putc('\n');
}


public void warn_error(GLib.Error e, string? text=null) {
	unowned string empty = "";
	warning("%s%s%s", text ?? empty, text == null ? empty : " ", error_to_string(e));
}


[PrintfFormat]
public void warn_error_f(GLib.Error e, string format, ...) {
	warn_error(e, format.vprintf(va_list()));
}


public void debug_error(GLib.Error e, string? text=null) {
	unowned string empty = "";
	debug("%s%s%s", text ?? empty, text == null ? empty : " ", error_to_string(e));
}


[PrintfFormat]
public void debug_error_f(GLib.Error e, string format, ...) {
	debug_error(e, format.vprintf(va_list()));
}


public void info_error(GLib.Error e, string? text=null) {
	unowned string empty = "";
	message("%s%s%s", text ?? empty, text == null ? empty : " ", error_to_string(e));
}


[PrintfFormat]
public void info_error_f(GLib.Error e, string format, ...) {
	info_error(e, format.vprintf(va_list()));
}


public void critical_error(GLib.Error e, string? text=null) {
	unowned string empty = "";
	critical("%s%s%s", text ?? empty, text == null ? empty : " ", error_to_string(e));
}


[PrintfFormat]
public void critical_error_f(GLib.Error e, string format, ...) {
	critical_error(e, format.vprintf(va_list()));
}


[NoReturn]
public void fatal_error(GLib.Error e, string? text=null) {
	unowned string empty = "";
	error("%s%s%s", text ?? empty, text == null ? empty : " ", error_to_string(e));
}


[NoReturn]
[PrintfFormat]
public void fatal_error_f(GLib.Error e, string format, ...) {
	fatal_error(e, format.vprintf(va_list()));
}

} // namespace Drt
