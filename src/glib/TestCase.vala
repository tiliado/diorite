/*
 * Copyright 2014-2019 Jiří Janoušek <janousek.jiri@gmail.com>
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

[CCode(has_target=false)]
public delegate bool EqualData(void* data1, void* data2, out string? reason);


public errordomain TestError {
    FAIL,
    NOT_IMPLEMENTED;
}


public delegate void TestCallback() throws GLib.Error;


/**
 * Base class for test cases.
 */
public abstract class TestCase : GLib.Object {
    public static bool str_eq(void* data1, void* data2, out string? reason) {
        unowned string str1 = (string) data1;
        unowned string str2 = (string) data2;
        if (str_equal(str1, str2)) {
            reason = null;
            return true;
        }
        reason = "\"%s\" != \"%s\"".printf(str1, str2);
        return false;
    }

    public static bool variant_eq(void* data1, void* data2, out string? reason) {
        reason = null;
        unowned Variant? var1 = (Variant?) data1;
        unowned Variant? var2 = (Variant?) data2;
        if (VariantUtils.equal(var1, var2)) {
            reason = null;
            return true;
        }
        reason = "\"%s\" != \"%s\"".printf(VariantUtils.print(var1), VariantUtils.print(var2));
        return false;
    }

    public static bool int_eq(void* data1, void* data2, out string? reason) {
        int val1 = *((int*)data1);
        int val2 = *((int*)data2);
        if (val1 == val2) {
            reason = null;
            return true;
        }
        reason = "%d != %d".printf(val1, val2);
        return false;
    }

    public static bool double_eq(void* data1, void* data2, out string? reason) {
        double val1 = *((double*)data1);
        double val2 = *((double*)data2);
        if (val1 == val2) {
            reason = null;
            return true;
        }
        reason = "%f != %f".printf(val1, val2);
        return false;
    }

    public static bool bool_eq(void* data1, void* data2, out string? reason) {
        bool val1 = *((bool*)data1);
        bool val2 = *((bool*)data2);
        if (val1 == val2) {
            reason = null;
            return true;
        }
        reason = "%s != %s".printf(val1.to_string(), val2.to_string());
        return false;
    }

    public int passed = 0;
    public int failed = 0;
    private Gee.List<LogMessage>? log_messages = null;
    private bool first_result = true;
    private File? tmp_dir = null;

    construct {
        if (GLib.Test.verbose()) {
            stdout.puts("----------------------------8<----------------------------\n");
        }
    }

    /**
     * Set up environment before each test of this test case.
     */
    public virtual void set_up() {
        first_result = true;
        Test.log_set_fatal_handler(log_fatal_func);
        log_messages = new Gee.LinkedList<LogMessage>();
        GLib.Log.set_default_handler(log_handler);
    }

    public unowned File get_tmp_dir() {
        if (tmp_dir == null) {
            File dir = File.new_for_path("../build/tests/tmp").get_child(this.get_type().name());
            try {
                System.purge_directory_content(dir, true);
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.NOT_FOUND)) {
                    critical("Failed to purge dir %s: %s", dir.get_path(), e.message);
                }
            }
            try {
                dir.make_directory_with_parents();
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.EXISTS)) {
                    critical("Failed to create dir %s: %s", dir.get_path(), e.message);
                }
            }
            tmp_dir = dir;
        }
        return tmp_dir;
    }

    /**
     * Clean up environment after each test of this test case.
     */
    public virtual void tear_down() {
        if (tmp_dir != null) {
            try {
                System.purge_directory_content(tmp_dir, true);
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.NOT_FOUND)) {
                    critical("Failed to purge dir %s: %s", tmp_dir.get_path(), e.message);
                }
            }
            tmp_dir = null;
        }
        check_log_messages();
        log_messages = null;
    }

    /**
     * Assertion
     *
     * Test is terminated when assertion fails.
     *
     * @param expression    expression expected to be true
     */
    [Diagnostics]
    protected void assert(bool expression, string comment) throws TestError {
        if (!process(expression, comment)) {
            abort_test();
        }
    }

    /**
     * Assertion failed
     *
     * Test is terminated.
     *
     */
    [Diagnostics]
    protected void assert_not_reached(string comment) throws TestError {
        process(false, comment);
        abort_test();
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expression    expression expected to be true
     */
    [Diagnostics]
    protected bool expect(bool expression, string comment) {
        return process(expression, comment);
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expression    expression expected to be true
     */
    [Diagnostics]
    protected bool expect_true(bool expression, string comment) {
        return process(expression, comment);
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expression    expression expected to be false
     */
    [Diagnostics]
    protected bool expect_false(bool expression, string comment) {
        return process(!expression, comment);
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_int_equal(int expected, int value, string comment) {
        return process(expected == value, "%s: %d == %d".printf(comment, expected, value));
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_uint_equal(uint expected, uint value, string comment) {
        return process(expected == value, "%s: %u == %u".printf(comment, expected, value));
    }

    /**
     * Assertion
     *
     * Test is terminated when the assertionfails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected void assert_uint_equal(uint expected, uint value, string comment) throws TestError {
        if (!process(expected == value, "%s: %u == %u".printf(comment, expected, value))) {
            abort_test();
        }
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_int64_equal(int64 expected, int64 value, string comment) {
        return process(expected == value, "%s: %s == %s".printf(
            comment, expected.to_string(), value.to_string()));
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_double_equal(double expected, double value, string comment) {
        return process(expected == value, "%s: %s == %s".printf(
            comment, expected.to_string(), value.to_string()));
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_str_equal(string? expected, string? value, string comment) {
        bool result = process(expected == value, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("\t '%s' == '%s' failed.\n", expected, value);
        }
        return result;
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_variant_equal(Variant? expected, Variant? value, string comment) {
        return process(VariantUtils.equal(expected, value), "%s: %s == %s".printf(
            comment, VariantUtils.print(expected), VariantUtils.print(value)));
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_type_equal(Type expected, Type value, string comment) {
        bool result = process(expected == value, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("\t %s == %s failed.\n", expected.name(), value.name());
        }
        return result;
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_str_not_equal(string? expected, string? value, string comment) {
        bool result = process(expected != value, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("\t '%s' != '%s' failed.\n", expected, value);
        }
        return result;
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_blob_equal(uint8[]? expected, uint8[]? value, string comment) {
        return process_bytes_equal(
            expected != null ? new Bytes.static(expected): null,
            value != null ? new Bytes.static(value): null,
            comment);
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_bytes_equal(GLib.Bytes? expected, GLib.Bytes? value, string comment) {
        return process_bytes_equal(expected, value, comment);
    }


    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param value       real value
     */
    [Diagnostics]
    protected bool expect_byte_array_equal(GLib.ByteArray? expected, GLib.ByteArray? value, string comment) {
        return process_bytes_equal(
            expected != null ? new Bytes.static(expected.data): null,
            value != null ? new Bytes.static(value.data): null,
            comment);
    }

    private bool process_bytes_equal(GLib.Bytes? expected, GLib.Bytes? value, string comment) {
        bool result = process(
            (expected == null && value == null)
        || (expected != null && value != null && expected.compare(value) == 0),
            comment);
        if (!result && !Test.quiet()) {
            string? expected_hex = null, value_hex = null;
            if (expected != null) {
                Blobs.hexadecimal_from_blob(expected.get_data(), out expected_hex);
            }
            if (value != null) {
                Blobs.hexadecimal_from_blob(value.get_data(), out value_hex);
            }
            stdout.printf("\t '%s' == '%s' failed.\n", expected_hex, value_hex);
        }
        return result;
    }

    /**
     * Expectation
     *
     * Test is not terminated when expectation fails.
     *
     * @param expected    expected value
     * @param actual      real value
     * @param comment     comment related to this check
     */
    [Diagnostics]
    protected bool expect_value_equal(GLib.Value? expected, GLib.Value? actual, string comment) {
        return process_value_equal(expected, actual, comment);
    }

    /**
     * Assertion
     *
     * Test is terminated when assertion fails.
     *
     * @param expected    expected value
     * @param actual      real value
     * @param comment     comment related to this check
     */
    [Diagnostics]
    protected void assert_value_equal(GLib.Value? expected, GLib.Value? actual, string comment) throws TestError {
        if (!process_value_equal(expected, actual, comment)) {
            abort_test();
        }
    }

    private bool process_value_equal(GLib.Value? expected, GLib.Value? actual, string comment) {
        string description;
        bool result = process(Value.equal_verbose(expected, actual, out description), comment);
        if (!result && !Test.quiet()) {
            stdout.printf("\t %s\n", description);
        }
        return result;
    }

    /**
     * Expectation failed
     *
     * Test is not terminated.
     */
    [Diagnostics]
    protected bool expectation_failed(string comment) {
        return process(false, comment);
    }

    [Diagnostics]
    protected void fail(string comment) throws TestError {
        process(false, comment);
        abort_test();
    }

    [Diagnostics]
    [PrintfFormat]
    protected void message(string format, ...) {
        if (!Test.quiet()) {
            stdout.vprintf(format, va_list());
            stdout.putc('\n');
        }
    }

    private bool process(bool expression, string comment) {
        print_result(expression, comment);
        if (expression) {
            passed++;
        } else {
            failed++;
            Test.fail();
        }
        return expression;
    }

    private void print_result(bool result, string comment) {
        if (!Test.quiet()) {
            if (comment != "" && (Test.verbose() || !result)) {
                if (first_result) {
                    stdout.putc('\n');
                    first_result = false;
                }
                stdout.puts(comment);
            }
            if (!result) {
                stdout.puts(" FAIL\n");
            } else if (Test.verbose()) {
                stdout.puts(" PASS\n");
            }
        }
    }

    private void abort_test() throws TestError {
        throw new TestError.FAIL("Test failed");
    }

    protected void not_imlemented() throws TestError {
        throw new TestError.NOT_IMPLEMENTED("Test not implemented.");
    }

    public void exception(GLib.Error e) {
        if (e is TestError.NOT_IMPLEMENTED) {
            if (!Test.quiet()) {
                stdout.puts("Test not implemented. ");
            }
            Test.fail();
        } else if (!(e is TestError.FAIL)) {
            expectation_failed(@"Uncaught exception: $(e.domain) $(e.code) $(e.message)");
        }
    }

    [Diagnostics]
    protected bool expect_no_error(TestCallback func, string comment) {
        string? err = null;
        try {
            func();
        } catch (GLib.Error e) {
            err = "\tUnexpected error: %s %d %s\n".printf(e.domain.to_string(), e.code, e.message);
        }
        bool result = process(err == null, comment);
        if (!result && !Test.quiet()) {
            stdout.puts(err);
        }
        return result;
    }

    [Diagnostics]
    protected bool expect_error(TestCallback func, string message_pattern, string comment) {
        bool result = false;
        string? err = null;
        try {
            func();
        } catch (GLib.Error e) {
            result = PatternSpec.match_simple(message_pattern, e.message);
            err = e.message;
        }
        process(result, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("An exception was expected: %s\n", message_pattern);
            if (err != null) {
                stdout.printf("Other exception has been thrown: %s\n", err);
            }
        }
        return result;
    }

    [Diagnostics]
    protected bool expect_error_match(GLib.Error e, string message_pattern, string comment) {
        bool result = PatternSpec.match_simple(message_pattern, e.message);
        process(result, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("An exception was expected: %s\n", message_pattern);
            stdout.printf("Other exception has been thrown: %s\n", error_to_string(e));
        }
        return result;
    }

    [Diagnostics]
    protected void unexpected_error(GLib.Error e, string comment) {
        process(false, comment);
        if (!Test.quiet()) {
            stdout.printf("Unexpected exception has been thrown: %s\n", error_to_string(e));
        }
    }

    [Diagnostics]
    protected bool expect_type(Type expected_type, void* object, string comment) {
        return expect_type_internal(expected_type, object, comment);
    }

    [Diagnostics]
    protected bool expect_type_of<T>(void* object, string comment) {
        return expect_type_internal(typeof(T), object, comment);
    }

    protected bool expect_type_internal(Type expected_type, void* object, string comment) {
        string? type_found = null;
        bool result = false;
        if (object != null) {
            Type object_type = Type.from_instance(object);
            type_found = object_type.name();
            result = (object_type == expected_type || object_type.is_a(expected_type));
        }
        process(result, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("A type %s expected but %s found.\n", expected_type.name(), type_found);
        }
        return result;
    }

    [Diagnostics]
    protected bool expect_enum<T>(T expected, T found, string comment) {
        Type expected_type = typeof(T);
        unowned string enum_name = expected_type.name();
        bool result = false;
        string? err = null;
        unowned EnumClass enum_class = expected_type.is_enum() ? (EnumClass) expected_type.class_ref() : null;
        if (enum_class == null) {
            err = enum_name + "is not an enumeration.\n";
        } else {
            int expected_index = int.from_pointer(expected);
            unowned EnumValue? expected_member = enum_class.get_value(expected_index);
            if (expected_member == null) {
                err = "The value expected (%d) is not a member of the %s enumeration.\n".printf(
                    expected_index, enum_name);
            } else {
                int found_index = int.from_pointer(found);
                unowned EnumValue? member_found = enum_class.get_value(found_index);
                if (member_found == null) {
                    err = "The value found (%d) is not a member of the %s enumeration.\n".printf(
                        found_index, enum_name);
                } else if (found_index != expected_index) {
                    err = "Expected the enum value %s (%d) but the value %s (%d) found.\n".printf(
                        expected_member.value_name, expected_index, member_found.value_name, found_index);
                } else {
                    result = true;
                }
            }
        }
        process(result, comment);
        if (!result && err != null && !Test.quiet()) {
            stdout.puts(err);
        }
        return result;
    }

    [Diagnostics]
    protected bool expect_null<T>(T? val, string comment) {
        return process(val == null, "assertion val is null failed; " + comment);
    }

    [Diagnostics]
    protected bool expect_not_null<T>(T? val, string comment) {
        return process(val != null, "assertion val is not null failed; " + comment);
    }

    public void summary() {
        if (!Test.quiet()) {
            stdout.printf(("[%s] %d run, %d passed, %d failed"),
                failed > 0 ? "FAIL" : (passed > 0 ? "PASS" : "N/A"), passed + failed, passed, failed);
            if (GLib.Test.verbose()) {
                stdout.puts("\n----------------------------8<----------------------------\n");
            } else {
                stdout.puts(" ");
            }
        }
    }

    [Diagnostics]
    protected bool expect_str_match(string pattern, string data, string comment) {
        return process_str_match(true, pattern, data, comment);
    }

    [Diagnostics]
    protected bool expect_str_not_match(string pattern, string data, string comment) {
        return process_str_match(false, pattern, data, comment);
    }

    [Diagnostics]
    protected void assert_str_match(string pattern, string data, string comment) throws TestError {
        if (!process_str_match(true, pattern, data, comment)) {
            abort_test();
        }
    }

    [Diagnostics]
    protected void assert_str_not_match(string pattern, string data, string comment) throws TestError {
        if (!process_str_match(false, pattern, data, comment)) {
            abort_test();
        }
    }

    private bool process_str_match(bool expected, string pattern, string data, string comment) {
        bool result = process(PatternSpec.match_simple(pattern, data) == expected, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("\tPattern %s should%s match string '%s'.\n", pattern, expected ? "" : " not", data);
        }
        return result;
    }

    [Diagnostics]
    protected void assert_array<T>(Array<T> expected, Array<T> found, EqualData eq, string comment)
    throws TestError {
        if (!process_array(expected, found, eq, comment)) {
            abort_test();
        }
    }

    [Diagnostics]
    protected bool expect_array<T>(Array<T> expected, Array<T> found, EqualData eq, string comment) {
        return process_array<T>(expected, found, eq, comment);
    }

    protected bool process_array<T>(Array<T> expected, Array<T> found, EqualData eq, string comment) {
        uint limit = uint.max(expected.length, found.length);
        bool result = true;
        string? reason = null;
        if (expected.length != found.length) {
            if (result) {
                print_result(false, comment);
            }
            result = false;
            if (!Test.quiet()) {
                stdout.printf("\tLength mismatch: %u != %u\n", expected.length, found.length);
            }
        }
        for (var i = 0; i < limit; i++) {
            if (i >= expected.length) {
                if (result) {
                    print_result(false, comment);
                }
                result = false;
                if (!Test.quiet()) {
                    stdout.printf("\tExtra element (%d)\n", i);
                }
            } else if (i >= found.length) {
                if (result) {
                    print_result(false, comment);
                }
                result = false;
                if (!Test.quiet()) {
                    stdout.printf("\tMissing element (%d)\n", i);
                }
            } else if (!eq(expected.data[i], found.data[i], out reason)) {
                if (result) {
                    print_result(false, comment);
                }
                result = false;
                if (!Test.quiet()) {
                    stdout.printf("\tElement mismatch (%d): %s\n", i, reason);
                }
            }
        }

        if (result) {
            print_result(result, comment);
            passed++;
        } else {
            failed++;
            Test.fail();
        }
        return result;
    }

    public virtual bool log_fatal_func(string? log_domain, LogLevelFlags log_levels, string message) {
        return false;
    }

    private void log_handler(string? domain, LogLevelFlags level, string text) {
        log_messages.add(new LogMessage(domain, level, text));
    }

    [Diagnostics]
    protected bool expect_critical_message(string? domain, string text_pattern, string comment) {
        return expect_log_message_internal(domain, LogLevelFlags.LEVEL_CRITICAL, text_pattern, comment);
    }

    [Diagnostics]
    protected bool expect_warning_message(string? domain, string text_pattern, string comment) {
        return expect_log_message_internal(domain, LogLevelFlags.LEVEL_WARNING, text_pattern, comment);
    }

    [Diagnostics]
    protected bool expect_log_message(string? domain, LogLevelFlags level, string text_pattern, string comment) {
        return expect_log_message_internal(domain, level, text_pattern, comment);
    }

    private bool expect_log_message_internal(
        string? domain, LogLevelFlags level, string text_pattern, string comment
    ) {
        bool result = false;
        if (log_messages != null) {
            Gee.Iterator<LogMessage> iter = log_messages.iterator();
            while (iter.next()) {
                LogMessage msg = iter.get();
                if ((msg.level & level) == 0 || msg.domain != domain) {
                    continue;
                }
                if (PatternSpec.match_simple(text_pattern, msg.text)) {
                    result = true;
                    iter.remove();
                }
                break;
            }
        }
        process(result, comment);
        if (!result && !Test.quiet()) {
            stdout.printf("\t Expected log message '%s' '%s' not found.\n", domain, text_pattern);
        }
        return result;
    }

    private void check_log_messages() {
        foreach (LogMessage msg in log_messages) {
            if ((msg.level & LogLevelFlags.LEVEL_ERROR) != 0) {
                expectation_failed(@"Uncaught error log message: $(msg.domain) $(msg.text)");
            } else if ((msg.level & LogLevelFlags.LEVEL_WARNING) != 0) {
                expectation_failed(@"Uncaught warning log message: $(msg.domain) $(msg.text)");
            } else if ((msg.level & LogLevelFlags.LEVEL_CRITICAL) != 0) {
                expectation_failed(@"Uncaught critical log message: $(msg.domain) $(msg.text)");
            }
        }
    }

    private class LogMessage {
        public string? domain;
        public LogLevelFlags level;
        public string text;

        public LogMessage(string? domain, LogLevelFlags level, string text) {
            this.text = text;
            this.level = level;
            this.domain = domain;
        }
    }
}

} // namespace Drt
