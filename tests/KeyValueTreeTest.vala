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

namespace Diorite
{

public class KeyValueTreeTest: KeyValueStorageTest
{
	private KeyValueTree tree;
	
	public override void set_up()
	{
		tree = new KeyValueTree();
		storage = tree;
	}
	
	public override void tear_down()
	{
		tree = null;
		storage = null;
	}
	
	public void test_print()
	{
		var tree = new Diorite.KeyValueTree();
		tree.set_value("a", "a");
		tree.set_value("b", "b");
		tree.set_value("c.a", "c.a");
		tree.set_value("c.b", "c.b");
		tree.set_value("c.c", "c.c");
		tree.set_value("c.d.a", "c.d.a");
		tree.set_value("c.d.b", "c.d.b");
		tree.set_value("c.d.c", "c.d.c");
		tree.set_value("c.d.d", "c.d.d");
		tree.set_value("d.a", 1);
		tree.set_value("d.b", true);
		tree.set_value("d.c", 3.14);
		tree.set_value("d.d", int64.MAX);
		var expected = """root
- a: 'a'
- b: 'b'
- c: (null)
  - a: 'c.a'
  - b: 'c.b'
  - c: 'c.c'
  - d: (null)
    - a: 'c.d.a'
    - b: 'c.d.b'
    - c: 'c.d.c'
    - d: 'c.d.d'
- d: (null)
  - a: 1
  - b: true
  - c: 3.1400000000000001
  - d: 9223372036854775807
""";
		var result = tree.print("- ");
		expect(expected == result, "");
	}
}

} // namespace Nuvola
