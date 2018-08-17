/*
 * Copyright 2011-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt.System
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
	 * Make directory with parents, ignore if it exists.
	 * 
	 * @param directory    the directory to create
	 * @throws GLib.Error on failure but not if it already exists.
	 */
	public void make_dirs(GLib.File directory) throws GLib.Error
	{
		try
		{
			directory.make_directory_with_parents();
		}
		catch (GLib.Error e)
		{
			if (!(e is GLib.IOError.EXISTS))
				throw e;
		}
	}
	
	public async void make_directory_with_parents_async(
		File directory, int io_priority=GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws GLib.Error
	{
		
		Drt.Lst<File> dirs = new Drt.Lst<File>();
		dirs.prepend(directory);
		File? dir;
		while ((dir = dirs[0]) != null)
		{
			try
			{
				yield dir.make_directory_async(io_priority, cancellable);
				dirs.remove_at(0);
			}
			catch (GLib.Error e)
			{
				if (e is GLib.IOError.NOT_FOUND)
				{
					dirs.prepend(dir.get_parent());
				}
				else
				{
					dirs = null;
					throw e;
				}
			}
		}
	}
	
	/**
	 * Move existing source directory to a target destination if it doesn't exists
	 * 
	 * If the source directory doesn't exist or the target directory do exist, nothing happens.
	 * Parent directories are created as necessary.
	 * 
	 * @param source_dir    source directory
	 * @param target_dir    target directory
	 * @throws GLib.Error on failure
	 * @return `true` if the directory has been moved, `false` otherwise
	 */
	public bool move_dir_if_target_not_found(File source_dir, File target_dir) throws GLib.Error
	{
		if (source_dir.query_file_type(0, null) != FileType.DIRECTORY
		|| target_dir.query_file_type(0, null) == FileType.DIRECTORY)
			return false;
		make_dirs(target_dir.get_parent());
		return source_dir.move(target_dir, 0, null, null);
	}
	
	/**
	 * 
	 * Replaces contents of a file with text in UTF-8 encoding
	 * 
	 * @param file        file to overwrite
	 * @param contents    contents of the file
	 * @throws GLib.Error on failure
	 */
	public async void overwrite_file_async(
		File file, string contents, int io_priority=GLib.Priority.DEFAULT, Cancellable? cancellable = null)
		throws GLib.Error
	{
		try
		{
			yield make_directory_with_parents_async(file.get_parent(), io_priority, cancellable);
		}
		catch (GLib.Error e)
		{
		}
		yield file.replace_contents_async(contents.data, null, false, FileCreateFlags.NONE, cancellable, null);
	}
	
	
	/**
	 * Removes files in a directory.
	 * 
	 * @param dir          directory
	 * @param recursive    recursive removal
	 * @throws              Error on failure
	 */
	public void purge_directory_content(File dir, bool recursive=false) throws GLib.Error
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
	public bool try_purge_dir(File dir, bool recursive=true)
	{
		try
		{
			purge_directory_content(dir, recursive);
			dir.delete();
		}
		catch (GLib.Error e)
		{
			return false;
		}
		return true;
	}
	
	public void copy_tree(File source_dir, File dest_dir, Cancellable? cancellable=null) throws GLib.Error
	{
		if (!dest_dir.query_exists())
			dest_dir.make_directory_with_parents();
		
		var enumerator = source_dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
		FileInfo file_info;
		while ((file_info = enumerator.next_file ()) != null)
		{
			var name = file_info.get_name();
			var source_item = source_dir.get_child(name);
			var dest_item = dest_dir.get_child(name);
			if (source_item.query_file_type(0) == FileType.DIRECTORY)
				copy_tree(source_item, dest_item, cancellable);
			else if(source_item.query_file_type(0) == FileType.REGULAR)
				source_item.copy(dest_item, 0, cancellable); 
			else
				warning("Skipped: %s", source_item.get_path());
		}
	}
	
	/**
	 * Recursive resolve symlink
	 * 
	 * @param file           The file to be resolved if it is a symlink.
	 * @param cancellable    Cancellable object
	 * @return Resolved file object if the original was symlink, the original file otherwise.
	 */
	public async File resolve_symlink(File file, Cancellable? cancellable)
	{
		File result = file;
		try
		{
			var info = yield file.query_info_async(
				"standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, cancellable);
			if (info.get_file_type() == FileType.SYMBOLIC_LINK)
			{
				var target = info.get_symlink_target();
				result = target[0] == '/' ? File.new_for_path(target) : file.get_parent().get_child(target);
				return yield resolve_symlink(result, cancellable);
			}
		}
		catch (GLib.Error e)
		{
			return result;
		}
		return result;
	}
}

namespace Drt.System
{

/**
 * Find process id for command basename
 * 
 * @param basename    the basename of program's path
 * @return all process ids with given program basename
 */
public int[] find_pid_by_basename(string basename)
{
	int[] result = {};
	try
	{
		var procfs = Dir.open("/proc", 0);
		string? name = null;
		while ((name = procfs.read_name()) != null)
		{
			var pid = int.parse(name);
			var path = Path.build_filename ("/proc", name, "exe");
			if (pid > 0 && FileUtils.test(path, FileTest.IS_SYMLINK))
			{
				try
				{
					var target = FileUtils.read_link(path);
					if (Path.get_basename(target) == basename)
						result += pid;
				}
				catch (FileError e)
				{
					if (pid > 1)
						warning("readlink error: %s.", e.message);
				}
			}
		}
	}
	catch (FileError e)
	{
		warning("pidof error: %s.", e.message);
	}
	return result;
}

/**
 * Get command line of a process with given PID.
 * 
 * @param pid    Process id.
 * @return Its command line if the process exists, null otherwise.
 */
public string? cmdline_for_pid(int pid) {
	try {
		return read_file(File.new_for_path("/proc/%d/cmdline".printf(pid)));
	} catch (GLib.Error e) {
		return null;
	}
}

/**
 * Send signal to multiple processes.
 * 
 * @param pids      The ids of processes to send signal to.
 * @param signum    The signal number. See {@link GLib.ProcessSignal}.
 * @return `0` on success, error code on the very first failure.
 */
public int sigall(int[] pids, int signum)
{
	foreach (var pid in pids)
	{
		var result = Posix.kill((Posix.pid_t) pid, signum);
		if (result != 0)
			return result;
	}
	return 0;
}


private static uint8[] cached_machine_id;


/**
 * Try to get machine id hash.
 * 
 * Why not to return the id directly? "It should be considered confidential, and must not be exposed in untrusted
 * environments, in particular on the network. If a stable unique identifier that is tied to the machine is needed
 * for some application, the machine ID or any part of it must not be used directly. Instead the machine ID should
 * be hashed with a cryptographic, keyed hash function, using a fixed, application-specific key."
 * [[https://www.freedesktop.org/software/systemd/man/machine-id.html|Source]].
 * 
 * @param app_key     The application-specific key.
 * @param checksum    Checksum type.
 * @return the hash of machine id on success, `null` on failure.
 */
public async string? get_machine_id_hash(uint8[] app_key, GLib.ChecksumType checksum) {
	if (cached_machine_id == null) {
	    uint8[] id;
	    try {
	        yield File.new_for_path("/etc/machine-id").load_contents_async(null, out id, null);
	    } catch (GLib.Error e1) {
	        try {
	            yield File.new_for_path("/var/lib/dbus/machine-id").load_contents_async(null, out id, null);
	        } catch (GLib.Error e2) {
	            Drt.warn_error(e1, "Failed to get machine id.");
	            Drt.warn_error(e2, "Failed to get machine id.");
	            return null;
	        }
	    }
	    if (id == null) {
	        warning("Null machine id.");
	        return null;
	    }
	    string id_string = ((string) id).strip();
	    if (id_string.length < 32) {
	        warning("Too short machine id (%d characters).", id_string.length);
	        return null;
	    }
	    if (!hex_to_bin(id_string, out cached_machine_id)) {
			warning("Machine id is not a valid hexadecimal string.");
			cached_machine_id = id_string.data;
		}
	}
    return GLib.Hmac.compute_for_data(checksum, app_key, cached_machine_id);
}

} // namespace Drt.System
