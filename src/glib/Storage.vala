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

namespace Drt
{

/**
 * File storage abstraction that provides easy access to a set of common paths: user's data,
 * cache and configuration directories and system data directories.
 */
public class Storage: GLib.Object
{
	[Description(nick = "User data dir", blurb = "Directory used to store user-specific data. Read-write access may be available.")]
	public GLib.File user_data_dir {get; protected set;}
	
	protected File[] _data_dirs;
	public GLib.File[] data_dirs() {
		File[] dirs = {};
		foreach (var dir in _data_dirs) {
			if (dir.query_file_type(0) == FileType.DIRECTORY) {
				dirs += dir;
			}
		}
		return dirs;
	}
	
	[Description(nick = "User cache dir", blurb = "Directory used to store user-specific cached data. Read-write access may be available.")]
	public GLib.File user_cache_dir {get; protected set;}
	
	[Description(nick = "User configuration dir", blurb = "Directory used to store user-specific configuration data. Read-write access may be available.")]
	public GLib.File user_config_dir {get; protected set;}
	
	/**
	 * Creates new storage
	 * 
	 * @param user_data_dir      Directory for user's data
	 * @param data_dirs          System data directories
	 * @param user_config_dir    Directory for user's configuration
	 * @param user_cache_dir     Directory for user's cached files
	 */
	public Storage(string user_data_dir, string[] data_dirs, string user_config_dir,
	string user_cache_dir)
	{
		this.user_data_dir = File.new_for_path(user_data_dir);
		this.user_config_dir = File.new_for_path(user_config_dir);
		this.user_cache_dir = File.new_for_path(user_cache_dir);
		
		File[] _data_dirs = {};
		foreach (string path in data_dirs)
			_data_dirs += File.new_for_path(path);
		
		this._data_dirs = _data_dirs;
	}
	
	/**
	 * Returns new child storage.
	 * 
	 * @param id    child storage id
	 * @return      child storage 
	 */
	public Storage get_child(string id)
	{
		string[] data_dirs = {};
		foreach (var dir in this._data_dirs)
			data_dirs += dir.get_child(id).get_path();
		
		return new Storage(user_data_dir.get_child(id).get_path(), data_dirs,
			user_config_dir.get_child(id).get_path(),
			user_cache_dir.get_child(id).get_path());
	}
	
	/**
	 * Returns the default path of configuration file/directory with given name
	 * 
	 * @param path Name of configuration file/directory
	 * @return default configuration path
	 */
	public File? get_config_path(string path)
	{
		return user_config_dir.get_child(path);
	}
	
	/**
	 * Returns the default path of cache file/directory with given name
	 * 
	 * @param path    The path relative to base cache directory.
	 * @return default cache path
	 */
	public File get_cache_path(string path)
	{
		return user_cache_dir.get_child(path);
	}
	
	/**
	 * Returns the default path of cache subdir with given name, create it if it doesn't exist.
	 * 
	 * @param path    Subdirectory path.
	 * @return cache subdirectory
	 */
	public File create_cache_subdir(string path)
	{
		var dir = user_cache_dir.get_child(path);
		try
		{
			System.make_dirs(dir);
		}
		catch (GLib.Error e)
		{
			warning("Failed to create directory '%s'. %s", dir.get_path(), e.message);
		}
		return dir;
	}
	
	/**
	 * Returns the default path of data dir/file with given name
	 * 
	 * @param path    child file/dir path
	 * @return default data path
	 */
	public File get_data_path(string path)
	{
		return user_data_dir.get_child(path);
	}
	
	/**
	 * Returns the default path of data subdir with given name, create it if it doesn't exist.
	 * 
	 * @param path    Subdirectory path.
	 * @return data subdirectory
	 */
	public File create_data_subdir(string path)
	{
		var dir = user_data_dir.get_child(path);
		try
		{
			System.make_dirs(dir);
		}
		catch (GLib.Error e)
		{
			warning("Failed to create directory '%s'. %s", dir.get_path(), e.message);
		}
		return dir;
	}
	
	/**
	 * Looks for a file in data directories.
	 * 
	 * User's data directory has a precedence over system data directories.
	 * 
	 * See also require_data_file().
	 * 
	 * @param name name of the file
	 * @return file instance or null if no file has been found
	 */
	public File? get_data_file(string name)
	{
		File f = user_data_dir.get_child(name);
		if (f.query_file_type(0) == FileType.REGULAR)
			return f;
		foreach (File dir in data_dirs())
		{
			f = dir.get_child(name);
			if (f.query_file_type(0) == FileType.REGULAR)
				return f;
		}
		return null;
	}
	
	/**
	 * Looks for a required file in data directories.
	 * 
	 * User's data directory has a precedence over system data directories.
	 * If the required data file is not found, application aborts with an error message.
	 * 
	 * See also get_data_file().
	 * 
	 * @param name name of the file
	 * @return file instance, never null
	 */
	public File require_data_file(string name)
	{
		var data_file = get_data_file(name);
		if (data_file != null)
			return data_file;
		
		var paths = user_data_dir.get_path();
		foreach (File dir in data_dirs())
			paths += ":" + dir.get_path();
		error("Required data file '%s' not found in '%s'.", name, paths);
	}
	
	/**
	 * Make sure a required file exists in any of data directories.
	 * 
	 * User's data directory has a precedence over system data directories.
	 * If the required data file is not found, application aborts with an error message.
	 * 
	 * See also require_data_file().
	 * 
	 * @param name name of the file
	 */
	public void assert_data_file(string name)
	{
		require_data_file(name);
	}
}

/**
 * File storage abstraction that provides easy access to a set of common paths: user's data,
 * cache and configuration directories and system data directories. This implementation
 * uses paths compliant with XDG specification.
 */
public class XdgStorage: Storage
{
	/**
	 * Creates new storage with XGD paths.
	 */
	public XdgStorage()
	{
		
		base(Environment.get_user_data_dir(), Environment.get_system_data_dirs(),
		Environment.get_user_config_dir(), Environment.get_user_cache_dir());
	}
	
	/**
	 * Creates new storage with XGD paths for a project.
	 * 
	 * @param id identifier of the project
	 */
	public XdgStorage.for_project(string id, string user_suffix="")
	{
		this();
		this.user_data_dir = user_data_dir.get_child(id + user_suffix);
		this.user_config_dir = user_config_dir.get_child(id + user_suffix);
		this.user_cache_dir = user_cache_dir.get_child(id + user_suffix);
		
		File[] data_dirs = {};
		foreach (var dir in this._data_dirs)
			data_dirs += dir.get_child(id);
		this._data_dirs = data_dirs;
	}
}

} // namespace Drt
