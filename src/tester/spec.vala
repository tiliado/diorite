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

namespace Diorite
{

public class TestSpec
{
	public string name {get; private set;}
	public bool @async {get; private set;}
	
	public TestSpec(string name, bool @async)
	{
		this.name = name;
		this.@async = @async;
	}
}

public class TestSpecReader
{
	private const string ASYNC = "async";
	private string path;
	
	public TestSpecReader(string path)
	{
		this.path = path;
	}
	
	public TestSpec get_spec(string name) throws Error
	{
		var stream = FileStream.open(path, "r");
		if (stream == null)
			throw new Error.IOERROR("Cannot open '%s' for reading.", path);
		
		string line;
		while((line = stream.read_line()) != null)
		{
			var fields = line.strip().split(" ");
			if (fields.length != 2 || fields[0] != name)
				continue;
			return new TestSpec(name, fields[1] == ASYNC);
		}
		throw new Error.NOT_FOUND("Test '%s' not found in '%s'.", name, path);
	}
	
	public TestSpecIter iterator()
	{
		return new TestSpecIter(FileStream.open(path, "r"));
	}
}

public class TestSpecIter
{
	private FileStream? stream;
	
	public TestSpecIter(owned FileStream? stream)
	{
		this.stream = (owned) stream;
	}
	
	public string? next_value()
	{
		if (stream == null)
			return null;
		var line = stream.read_line();
		if (line != null)
			return line.strip().split(" ")[0];
		return null;
	}
}


} // namespace Diorite
