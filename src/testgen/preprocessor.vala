/*
 * Copyright 2011-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Diorite
{

public enum CheckType
{
	NONE,
	EXPECT,
	ASSERT,
	EXPECT_ARRAY,
	ASSERT_ARRAY;
	
	public static CheckType parse(string name)
	{
		switch (name)
		{
		case "Diorite.TestCase.assert_array":
			return ASSERT_ARRAY;
		case "Diorite.TestCase.expect_array":
			return EXPECT_ARRAY;
		case "Diorite.TestCase.assert":
			return ASSERT;
		case "Diorite.TestCase.expect":
			return EXPECT;
		default:
			return NONE;
		}
	}
}

public class TestSpec
{
	private static const string LOOP_START = "start";
	private static const string LOOP_END = "end";
	private static const string LOOP_STEP = "step";
	private static const string TIMEOUT = "timeout";
	private string directory;
	private string[] tests;
	private string[] adaptors;
	private uint[] hashes;
	private StringBuilder definitions;
	private FileStream? stream = null;
	
	public TestSpec(string directory)
	{
		this.directory = directory;
		tests = {};
		adaptors = {};
		hashes = {};
		definitions = new StringBuilder();
		var filename = "tests.spec";
		var stream_path = Path.build_filename(directory, Path.get_basename(filename));
		stdout.printf(" (generated) -> %s\n", stream_path);
		stream = FileStream.open(stream_path, "w");
		if (stream == null)
			Vala.Report.error(null, "Cannot open file '%s' for writing".printf(stream_path));
	}
	
	public void visit(Vala.Method node)
	{
		if( stream == null)
			return;
		
		if (node.binding == Vala.MemberBinding.INSTANCE
		&& !node.has_result
		&& node.name.has_prefix("test_"))
		{
			var full_name = node.get_full_name();
			foreach (unowned string test in tests)
			{
				if (test == full_name)
					return;
			}
			
			int loop_start = 0;
			int loop_end = 0;
			int loop_step = 1;
			int timeout = 0;
			var attr = node.get_attribute("DTest");
			if (attr != null)
			{
				loop_start = attr.has_argument(LOOP_START) ? attr.get_integer(LOOP_START, loop_start) : loop_start;
				loop_end = attr.has_argument(LOOP_END) ? attr.get_integer(LOOP_END, loop_end) : loop_end;
				loop_step = attr.has_argument(LOOP_STEP) ? attr.get_integer(LOOP_STEP, loop_step) : loop_step;
				timeout = attr.has_argument(TIMEOUT) ? attr.get_integer(TIMEOUT, timeout) : timeout;
			}
			
			var parameters = node.get_parameters();
			if (parameters.size == 0)
			{
				loop_start = loop_end = 0;
			}
			else if (parameters.size == 1)
			{
				if (loop_start == loop_end)
					loop_end = loop_start + 1;
			}
			else
			{
				return;
			}
			
			stream.printf("%s %s %d %d %d %d\n",
			full_name, node.coroutine ? "async" : "sync",
			loop_start, loop_end, loop_step, timeout);
			tests += full_name;
		}
	}
	
	public void finish()
	{
		stream.flush();
		stream = null;
	}
}

public class Preprocessor: Vala.CodeVisitor
{
	private Vala.CodeContext context;
	private string directory;
	private TestSpec spec;
	private FileStream? stream = null;
	private Vala.SourceFile? source_file = null;
	private string? file_name = null;
	private string[] lines;
	private int line;
	private int column;
	private int last_line;
	private uint tmp_id;
	
	public Preprocessor(Vala.CodeContext context, string directory, TestSpec spec)
	{
		this.context = context;
		this.directory = directory;
		this.spec = spec;
	}
	
	public void run()
	{
		DirUtils.create_with_parents(directory, 0755);
		context.accept(this);
	}
	
	public override void visit_source_file(Vala.SourceFile source_file)
	{
		if (source_file.file_type == Vala.SourceFileType.SOURCE)
		{
			this.source_file = source_file;
			if (open(source_file))
			{
				tmp_id = 0;
				source_file.accept_children(this);
				close();
			}
			this.source_file = null;

		}
	}
	
	public override void visit_method_call (Vala.MethodCall node)
	{
		if (lines.length == 0)
			return;
		var r = node.source_reference;
		var full_name = node._call.symbol_reference.get_full_name();
		var check_type = CheckType.parse(full_name);
		if (check_type == CheckType.ASSERT || check_type == CheckType.EXPECT)
		{
			if (write_forward(r.first_line, r.first_column))
			{
				var args = node.get_argument_list();
				var arg1 = args.get(0);
				var binary = arg1 as Vala.BinaryExpression;
				string? operator_str = null;
				if (binary != null && (
				binary.left.value_type.to_string() == "null"
				|| binary.right.value_type.to_string() == "null"))
					binary = null;
				
				if (binary != null && binary.right.value_type.to_string() != "null")
				{
					switch (binary.operator)
					{
					case Vala.BinaryOperator.LESS_THAN:
						operator_str = "<";
						break;
					case Vala.BinaryOperator.GREATER_THAN:
						operator_str = ">";
						break;
					case Vala.BinaryOperator.LESS_THAN_OR_EQUAL:
						operator_str = "<=";
						break;
					case Vala.BinaryOperator.GREATER_THAN_OR_EQUAL:
						operator_str = ">=";
						break;
					case Vala.BinaryOperator.EQUALITY:
						operator_str = "==";
						break;
					case Vala.BinaryOperator.INEQUALITY:
						operator_str = "!=";
						break;
					default:
						// Not a comparation
						binary = null;
						break;
					}
					
				}
				
				if (binary != null)
				{
					const string ID = "__test_tmp%u__";
					var type_left = binary.left.value_type.to_string();
					var type_right = binary.right.value_type.to_string();
					var id1 = ID.printf(++this.tmp_id);
					var id2 = ID.printf(++this.tmp_id);
					var left_expr = read_node(binary.left);
					var right_expr = read_node(binary.right);
					stream.puts("{");
					stream.printf(" %s %s = %s;", type_left, id1, left_expr);
					stream.printf(" %s %s = %s;", type_right, id2, right_expr);
					var id3 = ID.printf(++this.tmp_id);
					stream.printf(" bool %s = %s %s %s;", id3, id1, operator_str, id2);
					if (check_type == CheckType.EXPECT)
						stream.printf("this.real_expect2(false, %s", id3);
					else
						stream.printf(" if (!this.real_expect2(true, %s", id3);
					stream.printf(",\"%s\"", left_expr.replace("\"","\\\""));
					stream.printf(",\"%s\"", operator_str);
					stream.printf(",\"%s\"", right_expr.replace("\"","\\\""));
					if (type_left == "string")
						stream.printf(", %s", id1);
					else
						stream.printf(", %s.to_string()", id1);
					if (type_right == "string")
						stream.printf(", %s", id2);
					else
						stream.printf(", %s.to_string()", id2);
					stream.printf(", \"%s\", %d)", file_name.replace("\"","\\\""), r.first_line);
					if (check_type == CheckType.EXPECT)
						stream.puts("; }");
					else
						stream.puts(") return; }");
				}
				else
				{
					string expr = read_node(arg1);
					if (check_type == CheckType.EXPECT)
					{
						stream.printf("this.real_expect1(%s, \"%s\", \"%s\", %d)",
							expr, expr.replace("\"","\\\""), file_name.replace("\"","\\\""), r.first_line);
					}
					else
					{
						stream.printf("{ if(!this.real_assert1(%s, \"%s\", \"%s\", %d)) return;}",
							expr, expr.replace("\"","\\\""), file_name.replace("\"","\\\""), r.first_line);
					}
				}
				skip(r.last_line, r.last_column + 1);
			}
		}
		else if(check_type == CheckType.ASSERT_ARRAY || check_type == CheckType.EXPECT_ARRAY)
		{
			if (write_forward(r.first_line, r.first_column))
			{
				var args = node.get_argument_list();
				var a_type = args.get(0);
				var a_expected = args.get(1).to_string();
				var a_found = args.get(2).to_string();
				var a_cmp = args.get(3).to_string();
				var a_str = args.get(4);
				
				stream.puts("{");
				if (check_type == CheckType.EXPECT_ARRAY)
					stream.puts("this._expect_array(false");
				else
					stream.puts(" if (!this._expect_array(true");
				stream.printf(",\"%s\"", a_expected.replace("\"","\\\""));
				stream.printf(",\"%s\", ", a_found.replace("\"","\\\""));
				write_node(a_type);
				stream.printf(", %s, %s.length, %s, %s.length, %s, ",
				a_expected, a_expected, a_found, a_found, a_cmp);
				write_node(a_str);
				stream.printf(", \"%s\", %d)", file_name.replace("\"","\\\""), r.first_line);
				if (check_type == CheckType.EXPECT_ARRAY)
					stream.puts("; }");
				else
					stream.puts(") return; }");
				skip(r.last_line, r.last_column + 1);
			}
		}
	}
	
	public override void visit_addressof_expression(Vala.AddressofExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_array_creation_expression(Vala.ArrayCreationExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_assignment(Vala.Assignment node)
	{
		node.accept_children(this);
	}
	
	public override void visit_base_access(Vala.BaseAccess node)
	{
		node.accept_children(this);
	}
	
	public override void visit_binary_expression(Vala.BinaryExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_block(Vala.Block node)
	{
		node.accept_children(this);
	}
	
	public override void visit_boolean_literal(Vala.BooleanLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_break_statement(Vala.BreakStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_cast_expression(Vala.CastExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_catch_clause(Vala.CatchClause node)
	{
		node.accept_children(this);
	}
	
	public override void visit_character_literal(Vala.CharacterLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_class(Vala.Class node)
	{
		node.accept_children(this);
	}
	
	public override void visit_conditional_expression(Vala.ConditionalExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_constant(Vala.Constant node)
	{
		node.accept_children(this);
	}
	
	public override void visit_constructor(Vala.Constructor node)
	{
		node.accept_children(this);
	}
	
	public override void visit_continue_statement(Vala.ContinueStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_creation_method(Vala.CreationMethod node)
	{
		node.accept_children(this);
	}
	
	public override void visit_delegate(Vala.Delegate node)
	{
		node.accept_children(this);
	}
	
	public override void visit_delete_statement(Vala.DeleteStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_destructor(Vala.Destructor node)
	{
		node.accept_children(this);
	}
	
	public override void visit_do_statement(Vala.DoStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_element_access(Vala.ElementAccess node)
	{
		node.accept_children(this);
	}
	
	public override void visit_empty_statement(Vala.EmptyStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_end_full_expression(Vala.Expression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_enum(Vala.Enum node)
	{
		node.accept_children(this);
	}
	
	public override void visit_enum_value(Vala.EnumValue node)
	{
		node.accept_children(this);
	}
	
	public override void visit_error_code(Vala.ErrorCode node)
	{
		node.accept_children(this);
	}
	
	public override void visit_error_domain(Vala.ErrorDomain node)
	{
		node.accept_children(this);
	}
	
	public override void visit_expression(Vala.Expression node)
	{
		//node.accept_children(this);
	}
	
	public override void visit_expression_statement(Vala.ExpressionStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_for_statement(Vala.ForStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_foreach_statement(Vala.ForeachStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_if_statement(Vala.IfStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_initializer_list(Vala.InitializerList node)
	{
		node.accept_children(this);
	}
	public override void visit_integer_literal(Vala.IntegerLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_interface(Vala.Interface node)
	{
		node.accept_children(this);
	}
	
	public override void visit_lambda_expression(Vala.LambdaExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_list_literal(Vala.ListLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_local_variable(Vala.LocalVariable node)
	{
		node.accept_children(this);
	}
	
	public override void visit_lock_statement(Vala.LockStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_loop(Vala.Loop node)
	{
		node.accept_children(this);
	}

	public override void visit_map_literal(Vala.MapLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_member_access(Vala.MemberAccess node)
	{
		node.accept_children(this);
	}
	
	public override void visit_method(Vala.Method node)
	{
		spec.visit(node);
		node.accept_children(this);
	}
	
	public override void visit_named_argument (Vala.NamedArgument node)
	{
		node.accept_children(this);
	}
	
	public override void visit_namespace(Vala.Namespace node)
	{
		node.accept_children(this);
	}
	
	public override void visit_null_literal(Vala.NullLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_object_creation_expression(Vala.ObjectCreationExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_pointer_indirection(Vala.PointerIndirection node)
	{
		node.accept_children(this);
	}
	
	public override void visit_postfix_expression(Vala.PostfixExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_property(Vala.Property node)
	{
		node.accept_children(this);
	}
	
	public override void visit_real_literal(Vala.RealLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_regex_literal(Vala.RegexLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_set_literal(Vala.SetLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_sizeof_expression(Vala.SizeofExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_slice_expression(Vala.SliceExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_string_literal(Vala.StringLiteral node)
	{
		node.accept_children(this);
	}
	
	public override void visit_struct(Vala.Struct node)
	{
		node.accept_children(this);
	}
	
	public override void visit_switch_section(Vala.SwitchSection node)
	{
		node.accept_children(this);
	}
	
	public override void visit_switch_statement(Vala.SwitchStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_template(Vala.Template node)
	{
		node.accept_children(this);
	}
	
	public override void visit_throw_statement(Vala.ThrowStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_try_statement(Vala.TryStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_tuple(Vala.Tuple node)
	{
		node.accept_children(this);
	}
	
	public override void visit_type_check(Vala.TypeCheck node)
	{
		node.accept_children(this);
	}
	
	public override void visit_type_parameter(Vala.TypeParameter node)
	{
		node.accept_children(this);
	}
	
	public override void visit_typeof_expression(Vala.TypeofExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_unary_expression(Vala.UnaryExpression node)
	{
		node.accept_children(this);
	}
	
	public override void visit_unlock_statement(Vala.UnlockStatement node)
	{
		node.accept_children(this);
	}
	
	public override void visit_while_statement(Vala.WhileStatement node)
	{
		node.accept_children(this);
	}
	
	private bool open(Vala.SourceFile source_file)
	{
		if (source_file.content == null)
			return false;
		var source_path = source_file.filename;
		this.file_name = Path.get_basename(source_path);
		var stream_path = Path.build_filename(directory, Path.get_basename(source_path));
		stream = FileStream.open(stream_path, "w");
		
		stdout.printf(" %s -> %s\n", source_path, stream_path);
		if (stream == null)
		{
			Vala.Report.error (null, "Cannot open file '%s' for writing".printf(stream_path));
			return false;
		}
		
		lines = source_file.content.split("\n");
		source_file.content = null;
		last_line = lines.length;
		line = 1;
		column = 1;
		return true;
	}
	
	private bool write_node(Vala.CodeNode node)
	{
		var data = read_node(node);
		if (data != null)
		{
			stream.puts(data);
			return true;
		}
		return false;
	}
	
	private string? read_node(Vala.CodeNode node)
	{
		var r = node.source_reference;
		var result = skip(r.first_line, r.first_column);
		if (!result)
			return null;
		return read_forward(r.last_line, r.last_column + 1);
	}
	
	private string? read_forward(int line, int column)
	{
		if (line < this.line || line == this.line && column <= this.column)
			return null;
		
		var buffer = new StringBuilder();
		unowned string data;
		if (this.line == line)
		{
			data = lines[line -1];
			buffer.append(data.slice(this.column - 1, column - 1));
			this.column = column;
			return buffer.str;
		}
		
		data = lines[this.line - 1];
		buffer.append(this.column > 1 ? data.substring(this.column - 1) : data);
		buffer.append_c('\n');
		lines[this.line - 1] = null;
		this.column = 1;
		
		for (var i = this.line; i < line - 1; i++)
		{
			buffer.append(lines[i]);
			buffer.append_c('\n');
			lines[i] = null;
		}
		
		this.line = line;
		
		if (column > this.column)
		{
			data = lines[line - 1];
			buffer.append(data.slice(0, column -1));
			this.column = column;
		}
		
		return buffer.str;
	}
	
	private bool write_forward(int line, int column)
	{
		if (line < this.line || line == this.line && column <= this.column)
			return false;
			
		var data = read_forward(line, column);
		if (data != null)
		{
			stream.puts(data);
			return true;
		}
		return false;
	}
	
	private bool skip(int line, int column)
	{
		if (line < this.line || line == this.line && column <= this.column)
			return false;
		
		for (var i = this.line - 1; i < line - 1; i++)
		{
			lines[i] = null;
		}
		
		this.line = line;
		this.column = column;
		return true;
	}
	
	private void end()
	{
		unowned string data = lines[this.line -1];
		stream.puts(this.column > 1 ? data.substring(this.column - 1) : data);
		stream.putc('\n');
		lines[this.line -1] = null;
		
		for (var i = this.line - 1; i < lines.length; i++)
		{
			data = lines[i];
			if (data != null)
			{
				stream.puts(data);
				if (i < lines.length - 1)
					stream.putc('\n');
			}
			lines[i] = null;
		}
	}
	
	private void close()
	{
		end();
		stream.flush();
		stream = null;
	}
}

} // namespace Diorite.Check
