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

namespace Drtdb
{

private const string TABLE_USERS_SQL = """
CREATE TABLE DrtdbUser(
	id INTEGER PRIMARY KEY ASC,
	name TEXT,
	age INTEGER,
	height DOUBLE,
	blob BLOB,
	alive BOOLEAN,
	extra BLOB
)""";

private const string TABLE_USERS_NAME = "DrtdbUser";

private class User : GLib.Object
{
	public int64 id {get; construct;}
	public string name {get; construct set;}
	public int age {get; construct set;}
	public double height {get; construct set;}
	public Bytes? blob {get; construct set;}
	public bool alive {get; construct set;}
	public ByteArray? extra {get; construct set;}
	public int not_in_db {get; set; default = 1024;}
	
	public User(int64 id, string name, int age, double height, bool alive)
	{
		GLib.Object(id: id);
		this.name = name;
		this.age = age;
		this.height = height;
		this.alive = alive;
	}
	
	public static string[] all_props()
	{
		return {"id", "name", "age", "height", "alive", "blob", "extra"};
	}
}

private class SimpleUser
{
	public int64 id {get; private set;}
	public string name {get; set;}
	public int age {get; set;}
	public double height {get; set;}
	public Bytes? blob {get; set;}
	public bool alive {get; set;}
	public ByteArray? extra {get; set;}
	public int not_in_db {get; set; default = 1024;}
	
	public SimpleUser(int64 id, string name, int age, double height, bool alive)
	{
		this.id = id;
		this.name = name;
		this.age = age;
		this.height = height;
		this.alive = alive;
	}
}

} // namespace Drtdb


