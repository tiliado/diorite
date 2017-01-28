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

namespace Drt
{

public class JsonObjectTest: Diorite.TestCase
{
	
	private JsonObject load_object() throws GLib.Error
	{
		return JsonParser.load_object("""
			{
				"a": null,
				"b": true,
				"c": false,
				"d": -1234,
				"e": -12.34,
				"f": "",
				"g": "string",
				"h": [1, 2, 3],
				"i": {
					"a": null, "b": true, "c": false, "d": -1234, "e": -12.34, "f": "", "g": "string",
					"h": [1, 2, 3], "i": {"a": "A", "b": "B"}
				}
			}
			""");
	}
	
	public void test_set_remove_take() throws GLib.Error
	{
		var object = new JsonObject();
		var null_val = new JsonValue.@null();
		object["aa"] = null_val;
		expect_true(null_val.parent == object, "parent");
		expect_true(null_val == object["aa"], "member equals");
		object["bb"] = null_val;
		expect_critical_message("DioriteGlib", "*assertion '* == NULL' failed", "parent not null");
		
		var int_val = new JsonValue.@int(5);
		object["aa"] = int_val;
		expect_true(int_val == object["aa"], "member equals");
		expect_null(null_val.parent, "parent");
		expect_true(int_val.parent == object, "parent");
		expect_true(object.take("aa") == int_val, "parent");
		expect_null(int_val.parent, "parent");
		expect_null(object["aa"], "member null");
		
		object["aa"] = int_val;
		expect_true(object.remove("aa"), "remove");
		expect_null(int_val.parent, "parent");	
		expect_false(object.remove("aa"), "remove");
	}
	
	public void test_get() throws GLib.Error
	{
		var object = load_object();
		unowned JsonNode? node;
		string[] results = {
			"null",  // null
			"bool",    // true
			"bool",   // false
			"int",   // -1234
			"double",  // -12.34
			"string",  // ""
			"string",  // "string"
			"array",  // array
			"object",  // object
			"nothing",   // nothing
		};
		for (uint i = 0; i < results.length; i++)
		{
			var key = " ";
			key.data[0] = (uint8)('a' + i);
			node = object.get(key);
			switch (results[i])
			{
			case "null":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_null(), "object['%s'] is %s", key, results[i]);
				break;
			case "bool":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_bool(), "object['%s'] is %s", key, results[i]);
				break;
			case "int":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_int(), "object['%s'] is %s", key, results[i]);
				break;
			case "double":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_double(), "object['%s'] is %s", key, results[i]);
				break;
			case "string":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_string(), "object['%s'] is %s", key, results[i]);
				break;
			case "array":
				if (expect_type_of<JsonArray>(node, "object['%s']", key))
					expect_true(node.is_array(), "object['%s'] is %s", key, results[i]);
				break;
			case "object":
				if (expect_type_of<JsonObject>(node, "object['%s']", key))
					expect_true(node.is_object(), "object['%s'] is %s", key, results[i]);
				break;
			case "nothing":
				expect_null(node, "object['%s']", key);
				break;
			default:
				expectation_failed("Unknown type '%s'", results[i]);
				break;
			}
		}
	}
	
	public void test_dotget() throws GLib.Error
	{
		var object = load_object();
		unowned JsonNode? node;
		uint i;
		string key;
		string[] results = {
			"null",  // null
			"bool",    // true
			"bool",   // false
			"int",   // -1234
			"double",  // -12.34
			"string",  // ""
			"string",  // "string"
			"array",  // array
			"object",  // object
			"nothing",   // nothing
		};
		key = " ";
		for (i = 0; i < results.length; i++)
		{
			key.data[0] = (uint8)('a' + i);
			node = object.dotget(key);
			switch (results[i])
			{
			case "null":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_null(), "object['%s'] is %s", key, results[i]);
				break;
			case "bool":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_bool(), "object['%s'] is %s", key, results[i]);
				break;
			case "int":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_int(), "object['%s'] is %s", key, results[i]);
				break;
			case "double":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_double(), "object['%s'] is %s", key, results[i]);
				break;
			case "string":
				if (expect_type_of<JsonValue>(node, "object['%s']", key))
					expect_true(node.is_string(), "object['%s'] is %s", key, results[i]);
				break;
			case "array":
				if (expect_type_of<JsonArray>(node, "object['%s']", key))
					expect_true(node.is_array(), "object['%s'] is %s", key, results[i]);
				break;
			case "object":
				if (expect_type_of<JsonObject>(node, "object['%s']", key))
					expect_true(node.is_object(), "object['%s'] is %s", key, results[i]);
				break;
			case "nothing":
				expect_null(node, "object['%s']", key);
				break;
			default:
				expectation_failed("Unknown type '%s'", results[i]);
				break;
			}
		}
		
		for (i = 0; i < results.length; i++)
		{
			key = "i.%c".printf((char)('a' + i));
			node = object.dotget(key);
			switch (results[i])
			{
			case "null":
				if (expect_type_of<JsonValue>(node, "object[%s]", key))
					expect_true(node.is_null(), "object[%s] is %s", key, results[i]);
				break;
			case "bool":
				if (expect_type_of<JsonValue>(node, "object[%s]", key))
					expect_true(node.is_bool(), "object[%s] is %s", key, results[i]);
				break;
			case "int":
				if (expect_type_of<JsonValue>(node, "object[%s]", key))
					expect_true(node.is_int(), "object[%s] is %s", key, results[i]);
				break;
			case "double":
				if (expect_type_of<JsonValue>(node, "object[%s]", key))
					expect_true(node.is_double(), "object[%s] is %s", key, results[i]);
				break;
			case "string":
				if (expect_type_of<JsonValue>(node, "object[%s]", key))
					expect_true(node.is_string(), "object[%s] is %s", key, results[i]);
				break;
			case "array":
				if (expect_type_of<JsonArray>(node, "object[%s]", key))
					expect_true(node.is_array(), "object[%s] is %s", i, results[i]);
				break;
			case "object":
				if (expect_type_of<JsonObject>(node, "object[%s]", key))
					expect_true(node.is_object(), "object[%s] is %s", key, results[i]);
				break;
			case "nothing":
				expect_null(node, "object[%s]", key);
				break;
			default:
				expectation_failed("Unknown type '%s'", results[i]);
				break;
			}
		}
		
		string[,] results2 = {
			{"", ""},
			{".", "*assertion*!= 0*failed*"},
			{"i.", ""},
			{"i..", "*assertion*!= 0*failed*"},
			{"1", ""},
		};
		for (i = 0; i < results2.length[0]; i++)
		{
			unowned string ukey = results2[i, 0];
			expect_null(object.dotget(ukey), "invalid key '%s'", ukey);
			unowned string msg = results2[i, 1];
			if (msg[0] != '\0')
				expect_critical_message("DioriteGlib", msg, "critical msg for '%s'", ukey);
		}
	}
	
	public void test_get_bool() throws GLib.Error
	{
		var object = load_object();
		bool val = true;
		GLib.Value[,] results = {
			{false, false},  // null
			{true, true},    // true
			{true, false},   // false
			{false, true},   // -1234
			{false, false},  // -12.34
			{false, false},  // ""
			{false, false},  // "string"
			{false, false},  // array
			{false, false},  // object
			{false, false},   // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length[0]; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0] == object.get_bool(key, out val), "get_bool('%s')", key);
			expect(results[i, 1] == val, "['%s'] == %s", key, results[i, 1].get_boolean().to_string());
		}
	}
	
	public void test_dotget_bool() throws GLib.Error
	{
		var object = load_object();
		string key;
		unowned string ukey;
		bool val = true;
		uint i;
		GLib.Value[,] results = {
			{false, false},  // null
			{true, true},    // true
			{true, false},   // false
			{false, true},   // -1234
			{false, false},  // -12.34
			{false, false},  // ""
			{false, false},  // "string"
			{false, false},  // array
			{false, false},  // object
			{false, false},  // nothing
		};
		key = " ";
		for (i = 0; i < results.length[0]; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0] == object.dotget_bool(key, out val), "get_bool('%s')", key);
			expect(results[i, 1] == val, "['%u'] == %s", i, results[i, 1].get_boolean().to_string());
		}
		for (i = 0; i < results.length[0]; i++)
		{
			key = "i.%c".printf((char)('a' + i));
			expect(results[i, 0] == object.dotget_bool(key, out val), "get_bool('%s')", key);
			expect(results[i, 1] == val, "['%s'] == %s", key, results[i, 1].get_boolean().to_string());
		}
		
		GLib.Value[,] results2 = {
			{"", false, "", false},
			{".", false, "*assertion*!= 0*failed*", false},
			{"i.", false, "", false},
			{"i..", false, "*assertion*!= 0*failed*", false},
			{"1", false, "", false},
		};
		for (i = 0; i < results2.length[0]; i++)
		{
			ukey = results2[i, 0].get_string();
			expect(results2[i, 1] == object.dotget_bool(ukey, out val), "invalid key '%s'", ukey);
			unowned string msg = results2[i, 2].get_string();
			if (msg[0] != '\0')
				expect_critical_message("DioriteGlib", msg, "critical msg for '%s'", ukey);
			expect(results2[i, 3] == val, "['%s'] == %s", ukey, results2[i, 3].get_boolean().to_string());
		}
	}
	
	public void test_get_bool_or() throws GLib.Error
	{
		var object = load_object();
		bool[] results = {
			false,  // null
			true,   // true
			false,  // false
			false,  // -1234
			false,  // -12.34
			false,  // ""
			false,  // "string"
			false,  // array
			false,  // object
			false,  // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i] == object.get_bool_or(key, false), "get_bool_or('%s')", key);
		}
	}
	
	public void test_get_int() throws GLib.Error
	{
		var object = load_object();
		int val = -1;
		GLib.Value[,] results = {
			{false, 0},     // null
			{false, 1},     // true
			{false, 0},     // false
			{true, -1234},  // -1234
			{false, 0},     // -12.34
			{false, 0},     // ""
			{false, 0},     // "string"
			{false, 0},     // array
			{false, 0},     // object
			{false, 0},     // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length[0]; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0] == object.get_int(key, out val), "get_int('%s')", key);
			var exp_val = results[i, 1].get_int();
			expect_int_equals(exp_val, val, "[%u] == %d", i, exp_val);
		}
	}
	
	public void test_dotget_int() throws GLib.Error
	{
		var object = load_object();
		string key;
		unowned string ukey;
		int val = -1;
		uint i;
		GLib.Value[,] results = {
			{false, 0},     // null
			{false, 1},     // true
			{false, 0},     // false
			{true, -1234},  // -1234
			{false, 0},     // -12.34
			{false, 0},     // ""
			{false, 0},     // "string"
			{false, 0},     // array
			{false, 0},     // object
			{false, 0},     // nothing
		};
		for (i = 0; i < results.length[0]; i++)
		{
			key = " ";
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0] == object.dotget_int(key, out val), "dotget_int('%s')", key);
			var exp_val = results[i, 1].get_int();
			expect_int_equals(exp_val, val, "[%u] == %d", i, exp_val);
		}
		for (i = 0; i < results.length[0]; i++)
		{
			key = "i.%c".printf((char)('a' + i));
			expect(results[i, 0] == object.dotget_int(key, out val), "dotget_int('%s')", key);
			var exp_val = results[i, 1].get_int();
			expect_int_equals(exp_val, val, "[%s] == %d", key, exp_val);
		}
		
		GLib.Value[,] results2 = {
			{"", false, "", 0},
			{".", false, "*assertion*!= 0*failed*", 0},
			{"i.", false, "", 0},
			{"i..", false, "*assertion*!= 0*failed*", 0},
			{"a", false, "", 0},
		};
		for (i = 0; i < results2.length[0]; i++)
		{
			ukey = results2[i, 0].get_string();
			expect(results2[i, 1] == object.dotget_int(ukey, out val), "invalid key '%s'", ukey);
			unowned string msg = results2[i, 2].get_string();
			if (msg[0] != '\0')
				expect_critical_message("DioriteGlib", msg, "critical msg for '%s'", ukey);
			var exp_val = results2[i, 3].get_int();
			expect_int_equals(exp_val, val, "['%s'] == %d", ukey, exp_val);
		}
	}
	
	public void test_get_int_or() throws GLib.Error
	{
		var object = load_object();
		int[] results = {
			-7,     // null
			-7,     // true
			-7,     // false
			-1234,  // -1234
			-7,     // -12.34
			-7,     // ""
			-7,     // "string"
			-7,     // array
			-7,     // object
			-7,     // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect_int_equals(results[i], object.get_int_or(key, -7), "get_int_or('%s')", key);
		}
	}
	
	public void test_get_double() throws GLib.Error
	{
		var object = load_object();
		double val = -1.0;
		GLib.Value[,] results = {
			{false, 0.0},    // null
			{false, 0.0},    // true
			{false, 0.0},    // false
			{false, 0.0},    // -1234
			{true, -12.34},  // -12.34
			{false, 0.0},    // ""
			{false, 0.0},    // "string"
			{false, 0.0},    // array
			{false, 0.0},    // object
			{false, 0.0},    // nothing
		};
		for (uint i = 0; i < results.length[0]; i++)
		{
			var key = " ";
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0] == object.get_double(key, out val), "get_double('%s')", key);
			var exp_val = results[i, 1].get_double();
			expect_double_equals(exp_val, val, "['%s'] == %f", key, exp_val);
		}
	}
	
	public void test_dotget_double() throws GLib.Error
	{
		var object = load_object();
		string key;
		unowned string ukey;
		double val = -1;
		uint i;
		GLib.Value[,] results = {
			{false, 0.0},    // null
			{false, 0.0},    // true
			{false, 0.0},    // false
			{false, 0.0},    // -1234
			{true, -12.34},  // -12.34
			{false, 0.0},    // ""
			{false, 0.0},    // "string"
			{false, 0.0},    // array
			{false, 0.0},    // object
			{false, 0.0},    // nothing
		};
		key = " ";
		for (i = 0; i < results.length[0]; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0] == object.dotget_double(key, out val), "dotget_double('%s')", key);
			var exp_val = results[i, 1].get_double();
			expect_double_equals(exp_val, val, "['%s'] == %f", key, exp_val);
		}
		for (i = 0; i < results.length[0]; i++)
		{
			key = "i.%c".printf((char)('a' + i));
			expect(results[i, 0] == object.dotget_double(key, out val), "dotget_double('%s')", key);
			var exp_val = results[i, 1].get_double();
			expect_double_equals(exp_val, val, "['%s'] == %f", key, exp_val);
		}
		
		GLib.Value[,] results2 = {
			{"", false, "", 0.0},
			{".", false, "*assertion*!= 0*failed*", 0.0},
			{"i.", false, "", 0.0},
			{"i..", false, "*assertion*!= 0*failed*", 0.0},
			{"1", false, "", 0.0},
		};
		for (i = 0; i < results2.length[0]; i++)
		{
			ukey = results2[i, 0].get_string();
			expect(results2[i, 1] == object.dotget_double(ukey, out val), "invalid key '%s'", ukey);
			unowned string msg = results2[i, 2].get_string();
			if (msg[0] != '\0')
				expect_critical_message("DioriteGlib", msg, "critical msg for '%s'", ukey);
			var exp_val = results2[i, 3].get_double();
			expect_double_equals(exp_val, val, "['%s'] == %f", ukey, exp_val);
		}
	}
	
	public void test_get_double_or() throws GLib.Error
	{
		var object = load_object();
		double[] results = {
			-5.6,    // null
			-5.6,    // true
			-5.6,    // false
			-5.6,    // -1234
			-12.34,  // -12.34
			-5.6,    // ""
			-5.6,    // "string"
			-5.6,    // array
			-5.6,    // object
			-5.6,    // nothing
		};
		for (uint i = 0; i < results.length; i++)
		{
			var key = " ";
			key.data[0] = (uint8)('a' + i);
			expect_double_equals(results[i], object.get_double_or(key, -5.6), "get_double_or('%s')", key);
		}
	}
	
	public void test_get_string() throws GLib.Error
	{
		var object = load_object();
		string? val = null;
		GLib.Value?[,] results = {
			{false, null},     // null
			{false, null},     // true
			{false, null},     // false
			{false, null},     // -1234
			{false, null},     // -12.34
			{true, ""},        // ""
			{true, "string"},  // "string"
			{false, null},     // array
			{false, null},     // object
			{false, null},     // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length[0]; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0].get_boolean() == object.get_string(key, out val), "get_string('%s')", key);
			unowned string? exp_val = results[i, 1] == null ? null : results[i, 1].get_string();
			expect_str_equals(exp_val, val, "['%s'] == '%s'", key, exp_val);
		}
	}
	
	public void test_dotget_string() throws GLib.Error
	{
		var object = load_object();
		string key;
		unowned string ukey;
		string? val = null;
		uint i;
		GLib.Value?[,] results = {
			{false, null},     // null
			{false, null},     // true
			{false, null},     // false
			{false, null},     // -1234
			{false, null},     // -12.34
			{true, ""},        // ""
			{true, "string"},  // "string"
			{false, null},     // array
			{false, null},     // object
			{false, null},     // nothing
		};
		key = " ";
		for (i = 0; i < results.length[0]; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i, 0].get_boolean() == object.dotget_string(key, out val), "dotget_string('%s')", key);
			var exp_val = results[i, 1] != null ? results[i, 1].get_string() : null;
			expect_str_equals(exp_val, val, "['%s'] == '%s'", key, exp_val);
		}
		for (i = 0; i < results.length[0]; i++)
		{
			key = "i.%c".printf((char)('a' + i));
			expect(results[i, 0].get_boolean() == object.dotget_string(key, out val), "dotget_string('%s')", key);
			var exp_val = results[i, 1] != null ? results[i, 1].get_string() : null;
			expect_str_equals(exp_val, val, "['%s'] == '%s'", key, exp_val);
		}
		
		GLib.Value[,] results2 = {
			{"", false, ""},
			{".", false, "*assertion*!= 0*failed*"},
			{"i.", false, ""},
			{"i..", false, "*assertion*!= 0*failed*"},
			{"1", false, ""},
		};
		for (i = 0; i < results2.length[0]; i++)
		{
			ukey = results2[i, 0].get_string();
			expect(results2[i, 1] == object.dotget_string(ukey, out val), "invalid key '%s'", ukey);
			unowned string msg = results2[i, 2].get_string();
			if (msg[0] != '\0')
				expect_critical_message("DioriteGlib", msg, "critical msg for '%s'", ukey);
			expect_null(val, "['%s'] == null", ukey);
		}
	}
	
	public void test_get_string_or() throws GLib.Error
	{
		var object = load_object();
		string[] results = {
			"abc",     // "abc"
			"abc",     // true
			"abc",     // false
			"abc",     // -1234
			"abc",     // -12.34
			"",        // ""
			"string",  // "string"
			"abc",     // array
			"abc",     // object
			"abc",     // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect_str_equals(results[i], object.get_string_or(key, "abc"), "get_string_or('%s')", key);
		}
	}
	
	public void test_get_null() throws GLib.Error
	{
		var object = load_object();
		bool[] results = {
			true,   // null
			false,  // true
			false,  // false
			false,  // -1234
			false,  // -12.34
			false,  // ""
			false,  // "string"
			false,  // array
			false,  // object
			false,  // nothing
		};
		var key = " ";
		for (uint i = 0; i < results.length; i++)
		{
			key.data[0] = (uint8)('a' + i);
			expect(results[i] == object.get_null(key), "get_null('%s')", key);
		}
	}
	
	public void test_get_array() throws GLib.Error
	{
		var object = load_object();
		var key = " ";
		for (uint i = 0; i < 10; i++)
		{
			key.data[0] = (uint8)('a' + i);
			if (i != 7)
				expect_null(object.get_array(key), "get_array('%s')", key);
			else
				expect_not_null(object.get_array(key), "get_array('%s')", key);
		}
	}
	
	public void test_get_object() throws GLib.Error
	{
		var object = load_object();
		var key = " ";
		for (uint i = 0; i < 10; i++)
		{
			key.data[0] = (uint8)('a' + i);
			if (i != 8)
				expect_null(object.get_object(key), "get_object('%s')", key);
			else
				expect_not_null(object.get_object(key), "get_object('%s')", key);
		}
	}
	
	public void test_to_string() throws GLib.Error
	{
		var object = load_object();
		const string one_line_json = (
			"{\"a\": null, \"b\": true, \"c\": false, \"d\": -1234, \"e\": -12.34, \"f\": \"\", "
			+ "\"g\": \"string\", \"h\": [1, 2, 3], \"i\": {\"a\": null, \"b\": true, \"c\": false, "
			+ "\"d\": -1234, \"e\": -12.34, \"f\": \"\", \"g\": \"string\", \"h\": [1, 2, 3], "
			+ "\"i\": {\"a\": \"A\", \"b\": \"B\"}}}");
		const string compact_json = (
			"{\"a\":null,\"b\":true,\"c\":false,\"d\":-1234,\"e\":-12.34,\"f\":\"\","
			+ "\"g\":\"string\",\"h\":[1,2,3],\"i\":{\"a\":null,\"b\":true,\"c\":false,"
			+ "\"d\":-1234,\"e\":-12.34,\"f\":\"\",\"g\":\"string\",\"h\":[1,2,3],"
			+ "\"i\":{\"a\":\"A\",\"b\":\"B\"}}}");
		const string pretty_json = """{
    "a": null,
    "b": true,
    "c": false,
    "d": -1234,
    "e": -12.34,
    "f": "",
    "g": "string",
    "h": [
        1,
        2,
        3
    ],
    "i": {
        "a": null,
        "b": true,
        "c": false,
        "d": -1234,
        "e": -12.34,
        "f": "",
        "g": "string",
        "h": [
            1,
            2,
            3
        ],
        "i": {
            "a": "A",
            "b": "B"
        }
    }
}
""";
		expect_str_equals(one_line_json, object.to_string(), "one line json");
		expect_str_equals(one_line_json, object.dump(null, false, 0), "one line json");
		expect_str_equals(compact_json, object.dump(null, true, 0), "compact json");
		expect_str_equals(compact_json, object.to_compact_string(), "compact json");
		expect_str_equals(pretty_json, object.to_pretty_string(), "pretty json");
		expect_str_equals(pretty_json, object.dump("    ", false, 0), "pretty json");
		var buf = new StringBuilder();
		object.dump_to_buffer(buf, "    ", false, 0);
		expect_str_equals(pretty_json, buf.str, "pretty json");
	}
}

} // namespace Drt
