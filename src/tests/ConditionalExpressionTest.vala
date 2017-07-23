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

public class ConditionalExpressionTest: Drt.TestCase
{
	public void test_valid_expressions()
	{
		string[] entries = {
	        "true",
	        "false",
	        "true and true",
	        "true or true",
	        "true and false",
	        "false and true",
	        "true or false",
	        "not true",
	        "not false",
	        "not false and false",
	        "not (false and false)",
	        "false or not false",
	        
	    };
	    bool[] results = {
	        true,
	        false,
	        true,
	        true,
	        false,
	        false,
	        true,
	        false,
	        true,
	        false,
	        true,
	        true,
	        false,
	    };
		var expr = new ConditionalExpression();
		for (var i = 0; i < entries.length; i++)
		{
			var data = entries[i];
			bool res = false;
			expect_no_error(() => {res = expr.eval(data);}, "'%s'", data);
			expect_true(results[i] == res, "'%s'", data);
		}
	}
	
	public void test_invalid_expressions()
	{
		string[] entries = {
	        "false or not",
	        "true and",
	        "true or",
	        "(true",
	        "true true",
	        "(true or false) (true or false)",
	    };
		string[] errors = {
	        "*Unexpected end of data. One of IDENT, NOT or LPAREN tokens expected*",
	        "*Unexpected end of data. One of IDENT, NOT or LPAREN tokens expected*",
	        "*Unexpected end of data. One of IDENT, NOT or LPAREN tokens expected*",
	        "*Unexpected end of data. RPAREN token expected*",
	        "*Unexpected token IDENT. EOF token expected*",
	        "*Unexpected token LPAREN. EOF token expected*",
	    };
	    
		var expr = new ConditionalExpression();
		for (var i = 0; i < entries.length; i++)
		{
			var data = entries[i];
			expect_error(() => expr.eval(data), errors[i], "'%s'", data);
		}
	}
	
	
}

} // namespace Drt
