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
 */

void main(string[] args)
{
	Drt.Logger.init(stderr, GLib.LogLevelFlags.LEVEL_DEBUG);
	var tree = new Drt.KeyValueTree();
	tree.set_value("a", "a");
	tree.set_value("b", "b");
	tree.set_value("c.a", "c.a");
	tree.set_value("c.b", "c.b");
	tree.set_value("c.c", "c.c");
	tree.set_value("c.d.a", "c.d.a");
	tree.set_value("c.d.b", "c.d.b");
	tree.set_value("c.d.c", "c.d.c");
	tree.set_value("c.d.d", "c.d.d");
	stdout.puts("Bullet: null\n");
	stdout.puts(tree.to_string());
	stdout.puts("\n\nBullet: '- '\n");
	stdout.puts(tree.print("- "));
	
	var person = new Person("Jiří Janoušek", 25, 65.5);
	tree.bind_object_property("person.", person, "name");
	tree.bind_object_property("person.", person, "age", Drt.PropertyBindingFlags.PROPERTY_TO_KEY);
	tree.bind_object_property("person.", person, "weight", Drt.PropertyBindingFlags.KEY_TO_PROPERTY);
	person.name = "John";
	person.age = 16;
	person.weight = 100.25;
	
	tree.set_double("person.weight", 50.5);
	tree.set_string("person.name", "My name");
	
	stdout.puts("\n\nBullet: '- '\n");
	stdout.puts(tree.print("- "));
}

class Person: GLib.Object
{
	public string name {get; construct set;}
	public int age {get; construct set;}
	public double weight {get; construct set;}
	
	public Person(string name, int age, double weight)
	{
		GLib.Object(name: name, age: age, weight: weight);
	}
	
	~Person()
	{
		message("~Person");
	}
}
