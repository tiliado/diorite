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

namespace Diorite.System
{
	/**
	 * Loads contents of a file in UTF-8 encoding
	 * 
	 * @param file    file to read
	 * @return contents of the file
	 * @throws GLib.Error on failure
	 */
	public string read_file(File file) throws GLib.Error
	{
		string data;
		uint8[] binary_data;
		file.load_contents(null, out binary_data, null);
		data = (string) binary_data;
		binary_data = null;
		return (owned) data;
	}
	
	/**
	 * 
	 * Replaces contents of a file with text in UTF-8 encoding
	 * 
	 * @param file        file to overwrite
	 * @param contents    contents of the file
	 * @throws GLib.Error on failure
	 */
	public void overwrite_file(File file, string contents) throws GLib.Error
	{
		try
		{
			file.get_parent().make_directory_with_parents();
		}
		catch (GLib.Error e)
		{}
		file.replace_contents(contents.data, null, false, FileCreateFlags.NONE, null);
	}
	
	
	/**
	 * Removes files in a directory.
	 * 
	 * @param dir          directory
	 * @param recursive    recursive removal
	 * @throw              Error on failure
	 */
	public void purge_directory_content(File dir, bool recursive=false) throws Error
	{
		var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
		FileInfo file_info;
		while ((file_info = enumerator.next_file ()) != null)
		{
			var f = dir.get_child(file_info.get_name());
			if (f.query_file_type(0) == FileType.DIRECTORY)
			{
				if (recursive)
					purge_directory_content(f, true);
			}
			f.delete();
		}
	}
	
	/**
	 * Deletes directory and its content and ignores IO errors.
	 * 
	 * @param dir          directory to remove
	 * @param recursive    recursive removal
	 * @return             true on success, false on failure
	 */
	public bool try_purge_dir(File dir, bool recursive=true){
		try
		{
			purge_directory_content(dir, recursive);
			dir.delete();
		}
		catch (Error e)
		{
			return false;
		}
		return true;
	}
}
