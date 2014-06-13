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

using Diorite.Test;

class SingleListTest: Diorite.TestCase
{
	[DTest(start=0, end=20)]
	public void test_append(int offset)
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < offset; i++)
		{
			list.append(i.to_string());
			expect(i + 1 == list.length);
			expect(i == int.parse(list[i]));
		}
		
		check_ascending(list);
	}
	
	[DTest(start=0, end=20)]
	public void test_prepend(int offset)
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < offset; i++)
		{
			list.prepend(i.to_string());
			expect(i + 1 == list.length);
			expect(i == int.parse(list[0]));
		}
		
		check_descending(list, offset);
	}
	
	[DTest(start=0, end=20)]
	public void test_prepend_reverse(int offset)
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < offset; i++)
			list.prepend(i.to_string());
		
		list.reverse();
		check_ascending(list);
	}
	
	[DTest(start=0, end=20)]
	public void test_append_reverse(int offset)
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < offset; i++)
			list.append(i.to_string());
		
		list.reverse();
		check_descending(list, offset);
	}
	
	private void check_ascending(Diorite.SingleList<string> list)
	{
		var j = 0;
		foreach (var k in list)
			expect(j++ == int.parse(k));
	}
	
	private void check_descending(Diorite.SingleList<string> list, int len)
	{
		var j = len;
		foreach (var k in list)
			expect(--j == int.parse(k));
	}
	
	public void test_insert_remove()
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < 20; i++)
			list.append(i.to_string());
		
		for (var d = 0; d < list.length; d++)
		{
			mark = "del%d".printf(d);
			list.remove_at(d);
			var j = 0;
			foreach (var k in list)
			{
				if (j == d)
					j++;
				expect(j++ == int.parse(k));
			}
			
			list.insert(d.to_string(), d);
			check_ascending(list);
		}
	}
	
	public void test_index()
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < 20; i++)
			list.append(i.to_string());
		
		for (var d = 0; d < list.length; d++)
		{
			mark = "d%d".printf(d);
			expect(d == list.index(d.to_string()));
		}
	}
	
	public void test_contains()
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < 20; i++)
			list.append(i.to_string());
		
		for (var d = 0; d < list.length; d++)
		{
			mark = "d%d".printf(d);
			expect(list.contains(d.to_string()));
		}
		
		for (var d = 0 + 20; d < list.length + 10; d++)
		{
			mark = "d%d".printf(d);
			expect(!list.contains(d.to_string()));
		}
	}
	
	public void test_set()
	{
		var list = new Diorite.SingleList<string>(str_equal);
		for (var i = 0; i < 20; i++)
			list.append(i.to_string());
		
		for (var d = 0; d < list.length; d++)
		{
			mark = "d%d".printf(d);
			expect(list.contains(d.to_string()));
		}
		
		for (var d = 0; d < list.length; d++)
		{
			mark = "d%d".printf(d);
			list[d] = (d + 20).to_string();
			var j = 0;
			foreach (var k in list)
			{
				if (j == d)
				{
					expect(20 + j++ == int.parse(k));
				}
				else
				{
					expect(j++ == int.parse(k));
				}
			}
			list[d] = d.to_string();
			check_ascending(list);
		}
	}
}
