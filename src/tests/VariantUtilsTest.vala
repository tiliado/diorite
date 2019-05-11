/*
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Tests are under public domain because they might contain useful sample code.
 */

namespace Drt {

public class VariantUtilsTest: Drt.TestCase {
    public void test_equal() {
        var str1 = new Variant.string("abc");
        var str2 = new Variant.string("abc");
        var str3 = new Variant.string("efg");
        var num1 = new Variant.int64(1);
        var num2 = new Variant.int64(1);
        var num3 = new Variant.int32(1);

        expect_true(VariantUtils.equal(null, null), "null == null");
        expect_false(VariantUtils.equal(str1, null), "'abc' != null");
        expect_false(VariantUtils.equal(null, str1), "null != 'abc'");

        expect_true(VariantUtils.equal(str1, str1), "'abc' == 'abc'");
        expect_true(VariantUtils.equal(str1, str2), "'abc' == 'abc'");
        expect_true(VariantUtils.equal(str2, str1), "'abc' == 'abc'");
        expect_false(VariantUtils.equal(str1, str3), "'abc' != 'efg'");
        expect_false(VariantUtils.equal(str3, str1), "'efg' != 'abc'");

        expect_true(VariantUtils.equal(num1, num1), "(int64) 1 == (int64) 1");
        expect_true(VariantUtils.equal(num1, num2), "(int64) 1 == (int64) 1");
        expect_false(VariantUtils.equal(num1, num3), "(int64) 1 != (int32) 1");
    }

    public void test_to_strv() {
        var variant = new Variant.string("abc");
        string[] result = VariantUtils.to_strv(variant);
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_container (variant)' failed*", "not a container");
        expect_true(result == null, "not a container");

        var builder = new VariantBuilder(new VariantType("av"));
        variant = builder.end();
        string[] expected = {};
        result = VariantUtils.to_strv(variant);
        expect_array<string>(Utils.wrap_strv(expected), Utils.wrap_strv(result), TestCase.str_eq, "empty");

        builder = new VariantBuilder(new VariantType("amv"));
        builder.add("mv", new Variant.string("abc"));
        builder.add("mv", new Variant.string(""));
        builder.add("mv", null);
        builder.add("mv", new Variant.int32(1234));
        builder.add("mv", new Variant.boolean(false));
        builder.add("mv", new Variant.double(3.14));
        variant = builder.end();
        expected = {"abc", "", "", "1234", "false", "3.1400000000000001"};
        result = VariantUtils.to_strv(variant);
        expect_array<string>(Utils.wrap_strv(expected), Utils.wrap_strv(result), TestCase.str_eq, "not empty");
    }

    public void test_to_array() {
        var variant = new Variant.string("abc");
        Variant?[] result = VariantUtils.to_array(variant);
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_container (variant)' failed*", "not a container");
        expect_true(result == null, "not a container");

        var builder = new VariantBuilder(new VariantType("av"));
        variant = builder.end();
        result = VariantUtils.to_array(variant);
        expect_true(result != null && result.length == 0, "empty");

        builder = new VariantBuilder(new VariantType("amv"));
        builder.add("mv", new Variant.string("abc"));
        builder.add("mv", new Variant.string(""));
        builder.add("mv", null);
        builder.add("mv", new Variant.int32(1234));
        builder.add("mv", new Variant.boolean(false));
        builder.add("mv", new Variant.double(3.14));
        variant = builder.end();
        Variant?[] expected = {
            new Variant.string("abc"),
            new Variant.string(""),
            null,
            new Variant.int32(1234),
            new Variant.boolean(false),
            new Variant.double(3.14)
        };
        result = VariantUtils.to_array(variant);
        expect_array<Variant>(
            Utils.wrap_variantv(expected), Utils.wrap_variantv(result), TestCase.variant_eq, "not empty");
    }

    public void test_to_hash_table() {
        Variant[] not_dictionaries = new Variant[4];
        // It's a string.
        not_dictionaries[0] = new Variant.string("abc");
        // It's an array.
        not_dictionaries[1] = new VariantBuilder(new VariantType("amv")).end();
        // Doesn't have a string key.
        not_dictionaries[2] = new VariantBuilder(new VariantType("a{is}")).end();
        // It's tuple
        not_dictionaries[3] = new Variant("(ss)", "abc", "def");
        HashTable<string, Variant?> result;

        foreach (unowned Variant variant in not_dictionaries) {
            result = VariantUtils.to_hash_table(variant);
            expect_critical_message(
                "DioriteGlib", "*assertion 'g_variant_is_of_type (variant, *)' failed*", "not a dictionary");
            expect_true(result == null, "not a dictionary");
        }

        // Dictionary of type "a{smv}" is accepted
        var builder = new VariantBuilder(new VariantType("a{smv}"));
        builder.add("{smv}", "a", new Variant.string("abc"));
        builder.add("{smv}", "b", new Variant.string(""));
        builder.add("{smv}", "c", null);
        builder.add("{smv}", "d", new Variant.int32(1234));
        builder.add("{smv}", "e", new Variant.boolean(true));
        builder.add("{smv}", "f", new Variant.double(3.14));
        Variant dict = builder.end();
        result = VariantUtils.to_hash_table(dict);
        if (expect_true(result != null, "result not null")) {
            expect_variant_equal(new Variant.string("abc"), result["a"], "key a");
            expect_variant_equal(new Variant.string(""), result["b"], "key b");
            expect_variant_equal(null, result["c"], "key c");
            expect_variant_equal(new Variant.int32(1234), result["d"], "key d");
            expect_variant_equal(new Variant.boolean(true), result["e"], "key e");
            expect_variant_equal(new Variant.double(3.14), result["f"], "key f");
            expect_variant_equal(null, result["g"], "key g");
            expect_int_equal(6, (int) result.length, "dict size");
        }

        // Dictionary of type "a{sv}" is also accepted
        builder = new VariantBuilder(new VariantType("a{sv}"));
        builder.add("{sv}", "a", new Variant.string("abc"));
        builder.add("{sv}", "d", new Variant.int32(1234));
        dict = builder.end();
        result = VariantUtils.to_hash_table(dict);
        if (expect_true(result != null, "result not null")) {
            expect_variant_equal(new Variant.string("abc"), result["a"], "key a");
            expect_variant_equal(new Variant.int32(1234), result["d"], "key d");
            expect_int_equal(2, (int) result.length, "dict size");
        }

        // Dictionary of type "a{ss}" is also accepted
        builder = new VariantBuilder(new VariantType("a{ss}"));
        builder.add("{ss}", "a", "abc");
        builder.add("{ss}", "d", "");
        dict = builder.end();
        result = VariantUtils.to_hash_table(dict);
        if (expect_true(result != null, "result not null")) {
            expect_variant_equal(new Variant.string("abc"), result["a"], "key a");
            expect_variant_equal(new Variant.string(""), result["d"], "key d");
            expect_int_equal(2, (int) result.length, "dict size");
        }

        // Empty dictionary
        builder = new VariantBuilder(new VariantType("a{ss}"));
        dict = builder.end();
        result = VariantUtils.to_hash_table(dict);
        if (expect_true(result != null, "result not null")) {
            expect_int_equal(0, (int) result.length, "dict size");
        }

    }

    public void test_from_hash_table() {
        // Empty dictionary
        var table = new HashTable<string, Variant?>(str_hash, str_equal);
        Variant dict = VariantUtils.from_hash_table(table);
        if (expect_true(dict != null, "dict not null")) {
            expect_int_equal(0, (int) dict.n_children(), "dict size");
        }

        // Non-empty dictionary
        table = new HashTable<string, Variant?>(str_hash, str_equal);
        table["a"] = new Variant.string("abc");
        table["b"] = new Variant.string("");
        table["c"] = null;
        table["d"] = new Variant.int32(1234);
        table["e"] = new Variant.boolean(true);
        table["f"] = new Variant.double(3.14);
        var builder = new VariantBuilder(new VariantType("a{smv}"));
        builder.add("{smv}", "a", new Variant.string("abc"));
        builder.add("{smv}", "b", new Variant.string(""));
        builder.add("{smv}", "c", null);
        builder.add("{smv}", "d", new Variant.int32(1234));
        builder.add("{smv}", "e", new Variant.boolean(true));
        builder.add("{smv}", "f", new Variant.double(3.14));
        Variant expected = builder.end();
        dict = VariantUtils.from_hash_table(table);
        if (expect_true(dict != null, "dict not null")) {
            // Note: keys are sorted in VariantUtils.from_hash_table for the both variants to be compared easily.
            expect_variant_equal(expected, dict, "Dictionaries equal");
            expect_int_equal(6, (int) dict.n_children(), "dict size");
        }
    }

    private Variant?[] create_sample_variants() {
        return {
            null,
            new Variant("mv", null),
            new Variant.string("abc"),
            new Variant.string(""),
            new Variant("ms", "abc"),
            new Variant("mv", new Variant.string("abc")),
            new Variant.boolean(true),
            new Variant.boolean(false),
            new Variant("mv", new Variant.boolean(true)),
            new Variant.double(3.14),
            new Variant.double(-3.14),
            new Variant("mv", new Variant.double(-3.14)),
            new Variant.int64(1234),
            new Variant.int64(-1234),
            new Variant("mv", new Variant.int64(-1234)),
            new Variant.int32(1234),
            new Variant.int32(-1234),
            new Variant("mv", new Variant.int32(-1234)),
            new Variant.uint64(1234),
            new Variant("mv", new Variant.uint64(1234)),
            new Variant.uint32(1234),
            new Variant("mv", new Variant.uint32(1234)),
            new VariantBuilder(new VariantType("a{smv}")).end(),
            new VariantBuilder(new VariantType("amv")).end(),
            new Variant("(ss)", "abc", "def")
        };
    }

    public void test_get_string() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        string?[] expected_values = {
            null,
            null,
            "abc",
            "",
            "abc",
            "abc",
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        };

        for (var i = 0; i < results.length; i++) {
            string? actual_value = null;
            bool result = VariantUtils.get_string(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a string");
            } else {
                expect_false(result, @"[$i] isn't a string");
            }
            expect_str_equal(expected_values[i], actual_value, @"[$i]");
        }
    }

    public void test_get_maybe_string() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            true,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        string?[] expected_values = {
            null,
            null,
            "abc",
            "",
            "abc",
            "abc",
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        };

        for (var i = 0; i < results.length; i++) {
            string? actual_value = null;
            bool result = VariantUtils.get_maybe_string(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a string");
            } else {
                expect_false(result, @"[$i] isn't a string");
            }
            expect_str_equal(expected_values[i], actual_value, @"[$i]");
        }
    }

    public void test_get_bool() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        bool[] expected_values = {
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        for (var i = 0; i < results.length; i++) {
            bool actual_value = false;
            bool result = VariantUtils.get_bool(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a bool");
            } else {
                expect_false(result, @"[$i] isn't a bool");
            }
            expect_true(expected_values[i] == actual_value, @"[$i] value");
        }
    }

    public void test_get_double() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        double[] expected_values = {
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            3.14,
            -3.14,
            -3.14,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0
        };

        for (var i = 0; i < results.length; i++) {
            double actual_value = -1.0;
            bool result = VariantUtils.get_double(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a double");
            } else {
                expect_false(result, @"[$i] isn't a double");
            }
            expect_double_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_get_int64() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        int64[] expected_values = {
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            1234,
            -1234,
            -1234,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        };

        for (var i = 0; i < results.length; i++) {
            int64 actual_value = -1;
            bool result = VariantUtils.get_int64(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a double");
            } else {
                expect_false(result, @"[$i] isn't a double");
            }
            expect_int64_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_get_int() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        int[] expected_values = {
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            1234,
            -1234,
            -1234,
            1234,
            -1234,
            -1234,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        };

        for (var i = 0; i < results.length; i++) {
            int actual_value = -1;
            bool result = VariantUtils.get_int(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a double");
            } else {
                expect_false(result, @"[$i] isn't a double");
            }
            expect_int_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_get_uint() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            false,
            false,
            false
        };

        uint[] expected_values = {
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            1234,
            1234,
            1234,
            1234,
            0,
            0,
            0
        };

        for (var i = 0; i < results.length; i++) {
            uint actual_value = 1;
            bool result = VariantUtils.get_uint(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a double");
            } else {
                expect_false(result, @"[$i] isn't a double");
            }
            expect_uint_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_get_number() {
        Variant?[] variants = create_sample_variants();
        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        double[] expected_values = {
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            3.14,
            -3.14,
            -3.14,
            1234.0,
            -1234.0,
            -1234.0,
            1234.0,
            -1234.0,
            -1234.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0
        };

        for (var i = 0; i < results.length; i++) {
            double actual_value = -1.0;
            bool result = VariantUtils.get_number(variants[i], out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a double");
            } else {
                expect_false(result, @"[$i] isn't a double");
            }
            expect_double_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    private Variant[] create_sample_dictionaries() {
        var builder = new VariantBuilder(new VariantType("a{smv}"));
        builder.add("{smv}", "1", null);
        builder.add("{smv}", "2", new Variant("mv", null));
        builder.add("{smv}", "3", new Variant.string("abc"));
        builder.add("{smv}", "4", new Variant.string(""));
        builder.add("{smv}", "5", new Variant("ms", "abc"));
        builder.add("{smv}", "6", new Variant("mv", new Variant.string("abc")));
        builder.add("{smv}", "7", new Variant.boolean(true));
        builder.add("{smv}", "8", new Variant.boolean(false));
        builder.add("{smv}", "9", new Variant("mv", new Variant.boolean(true)));
        builder.add("{smv}", "10", new Variant.double(3.14));
        builder.add("{smv}", "11", new Variant.double(-3.14));
        builder.add("{smv}", "12", new Variant("mv", new Variant.double(-3.14)));
        builder.add("{smv}", "13", new Variant.int64(1234));
        builder.add("{smv}", "14", new Variant.int64(-1234));
        builder.add("{smv}", "15", new Variant("mv", new Variant.int64(-1234)));
        builder.add("{smv}", "16", new Variant.int32(1234));
        builder.add("{smv}", "17", new Variant.int32(-1234));
        builder.add("{smv}", "18", new Variant("mv", new Variant.int32(-1234)));
        builder.add("{smv}", "19", new Variant.uint64(1234));
        builder.add("{smv}", "20", new Variant("mv", new Variant.uint64(1234)));
        builder.add("{smv}", "21", new Variant.uint32(1234));
        builder.add("{smv}", "22", new Variant("mv", new Variant.uint32(1234)));
        builder.add("{smv}", "23", new VariantBuilder(new VariantType("a{smv}")).end());
        builder.add("{smv}", "24", new VariantBuilder(new VariantType("amv")).end());
        builder.add("{smv}", "25", new Variant("(ss)", "abc", "def"));
        return {
            builder.end(),
            new VariantBuilder(new VariantType("a{imv}")).end(),
            new VariantBuilder(new VariantType("amv")).end()
        };
    }

    public void test_get_string_item() {
        Variant[] dictionaries = create_sample_dictionaries();
        Variant dict = dictionaries[0];

        string? actual_value = null;
        expect_false(VariantUtils.get_string_item(dictionaries[1], "a", out actual_value), "a{imv} not supported");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "a{imv} not supported");
        expect_false(VariantUtils.get_string_item(dictionaries[2], "a", out actual_value), "amv isn't a dict");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "amv isn't a dict");

        bool[] results = {
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };
        string?[] expected_values = {
            null,
            null,
            null,
            "abc",
            "",
            "abc",
            "abc",
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        };

        for (var i = 0; i < results.length; i++) {
            actual_value = null;
            bool result = VariantUtils.get_string_item(dict, i.to_string(), out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a string");
            } else {
                expect_false(result, @"[$i] isn't a string");
            }
            expect_str_equal(expected_values[i], actual_value, @"[$i]");
        }
    }

    public void test_get_maybe_string_item() {
        Variant[] dictionaries = create_sample_dictionaries();
        Variant dict = dictionaries[0];

        string? actual_value = null;
        expect_false(VariantUtils.get_maybe_string_item(dictionaries[1], "a", out actual_value), "a{imv} not supported");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "a{imv} not supported");
        expect_false(VariantUtils.get_maybe_string_item(dictionaries[2], "a", out actual_value), "amv isn't a dict");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "amv isn't a dict");

        bool[] results = {
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };
        string?[] expected_values = {
            null,
            null,
            null,
            "abc",
            "",
            "abc",
            "abc",
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
        };

        for (var i = 0; i < results.length; i++) {
            actual_value = null;
            bool result = VariantUtils.get_maybe_string_item(dict, i.to_string(), out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a string");
            } else {
                expect_false(result, @"[$i] isn't a string");
            }
            expect_str_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_get_bool_item() {
        Variant[] dictionaries = create_sample_dictionaries();
        Variant dict = dictionaries[0];

        bool actual_value = true;
        expect_false(VariantUtils.get_bool_item(dictionaries[1], "a", out actual_value), "a{imv} not supported");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "a{imv} not supported");
        expect_false(VariantUtils.get_bool_item(dictionaries[2], "a", out actual_value), "amv isn't a dict");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "amv isn't a dict");

        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };
        bool[] expected_values = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };

        for (var i = 0; i < results.length; i++) {
            actual_value = true;
            bool result = VariantUtils.get_bool_item(dict, i.to_string(), out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a bool");
            } else {
                expect_false(result, @"[$i] isn't a bool");
            }
            expect_true(expected_values[i] == actual_value, @"[$i] value");
        }
    }

    public void test_get_double_item() {
        Variant[] dictionaries = create_sample_dictionaries();
        Variant dict = dictionaries[0];

        double actual_value = 0.0;
        expect_false(VariantUtils.get_double_item(dictionaries[1], "a", out actual_value), "a{imv} not supported");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "a{imv} not supported");
        expect_false(VariantUtils.get_double_item(dictionaries[2], "a", out actual_value), "amv isn't a dict");
        expect_critical_message(
            "DioriteGlib", "*assertion 'g_variant_is_of_type (dict, *)' failed*", "amv isn't a dict");

        bool[] results = {
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
        };
        double[] expected_values = {
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            3.14,
            -3.14,
            -3.14,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0
        };

        for (var i = 0; i < results.length; i++) {
            actual_value = -1.0;
            bool result = VariantUtils.get_double_item(dict, i.to_string(), out actual_value);
            if (results[i]) {
                expect_true(result, @"[$i] is a double");
            } else {
                expect_false(result, @"[$i] isn't a double");
            }
            expect_double_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_unbox() {
        Variant?[] variants = {
            null,
            new Variant.string("abc"),
            new Variant("ms", "abc"),
            new Variant("mv", null),
            new Variant("mv", new Variant.string("abc")),
            new Variant("v", new Variant.string("abc")),
            new Variant("v", new Variant("mv", new Variant.string("abc"))),
            new Variant("v", new Variant("mv", new Variant("v", new Variant.string("abc")))),
            new Variant("v", new Variant("mv", new Variant("v", new Variant("mv", null)))),
            new VariantBuilder(new VariantType("a{smv}")).end(),
            new Variant("mv", new VariantBuilder(new VariantType("a{smv}")).end()),
            new Variant("(ss)", "abc", "def"),
            new Variant("mv", new Variant("(ss)", "abc", "def"))
        };
        var abc = new Variant.string("abc");
        Variant dict = new VariantBuilder(new VariantType("a{smv}")).end();
        var tuple = new Variant("(ss)", "abc", "def");
        Variant?[] unboxed_variants = {
            null,
            abc,
            abc,
            null,
            abc,
            abc,
            abc,
            abc,
            null,
            dict,
            dict,
            tuple,
            tuple
        };

        for (var i = 0; i < variants.length; i++) {
            Variant? unboxed = VariantUtils.unbox(variants[i]);
            expect_variant_equal(unboxed_variants[i], unboxed, @"[$i] value");
        }
    }

    public void test_parse_typed_value() {
        (unowned string)[] input_values = {
            ":", ":abc", "ss:abc",
            "", "s:abc", "s:",
            "b:", "b:abc", "b:true", "b:false",
            "i:", "i:abc", "i:1234", "i:-1234",
            "d:", "d:abc", "d:123", "d:-123", "d:3.14", "d:-3.14"
        };
        Variant?[] expected_values = {
            null, null, null,
            new Variant.string(""), new Variant.string("abc"), new Variant.string(""),
            null, null, new Variant.boolean(true), new Variant.boolean(false),
            null, null, new Variant.int64(1234), new Variant.int64(-1234),
            null, null, new Variant.double(123.0), new Variant.double(-123.0),
            new Variant.double(3.14), new Variant.double(-3.14)
        };
        for (var i = 0; i < input_values.length; i++) {
            Variant? actual_value = VariantUtils.parse_typed_value(input_values[i]);
            expect_variant_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_to_string() {
        Variant?[] input_values = {
            null, new Variant("ms", null),
            new Variant.string(""), new Variant.string("abc"),
            new Variant.boolean(true), new Variant.boolean(false),
            new Variant.int64(1234), new Variant.int64(-1234),
            new Variant.double(123.0), new Variant.double(-123.0),
            new Variant.double(3.14), new Variant.double(-3.14)
        };
        (unowned string)[] expected_values = {
            "", "nothing",
            "''", "'abc'",
            "true", "false",
            "1234", "-1234",
            "123.0", "-123.0",
            "3.1400000000000001", "-3.1400000000000001"
        };
        for (var i = 0; i < input_values.length; i++) {
            string? actual_value = VariantUtils.to_string(input_values[i]);
            expect_str_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_print() {
        Variant?[] input_values = {
            null, new Variant("ms", null),
            new Variant.string(""), new Variant.string("abc"),
            new Variant.boolean(true), new Variant.boolean(false),
            new Variant.int64(1234), new Variant.int64(-1234),
            new Variant.double(123.0), new Variant.double(-123.0),
            new Variant.double(3.14), new Variant.double(-3.14)
        };
        (unowned string?)[] expected_values = {
            null, "nothing",
            "''", "'abc'",
            "true", "false",
            "1234", "-1234",
            "123.0", "-123.0",
            "3.1400000000000001", "-3.1400000000000001"
        };
        (unowned string?)[] expected_values_typed = {
            null, "@ms nothing",
            "''", "'abc'",
            "true", "false",
            "int64 1234", "int64 -1234",
            "123.0", "-123.0",
            "3.1400000000000001", "-3.1400000000000001"
        };
        for (var i = 0; i < input_values.length; i++) {
            string? actual_value = VariantUtils.print(input_values[i], true);
            expect_str_equal(expected_values_typed[i], actual_value, @"[$i] value");
            actual_value = VariantUtils.print(input_values[i], false);
            expect_str_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }

    public void test_from_string_if_not_null() {
        (unowned string?)[] input_values = {
            null, "", "abc"
        };
        Variant?[] expected_values = {
            null, new Variant.string(""), new Variant.string("abc")
        };
        for (var i = 0; i < input_values.length; i++) {
            Variant? actual_value = VariantUtils.from_string_if_not_null(input_values[i]);
            expect_variant_equal(expected_values[i], actual_value, @"[$i] value");
        }
    }
}

} // namespace Drt
