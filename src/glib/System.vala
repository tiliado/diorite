/*
 * Copyright 2011-2018 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Drt.System {

/**
 * Load the contents of a file as a string in UTF-8 encoding.
 *
 * @param file    The file to read.
 * @return The contents of the file.
 * @throws GLib.Error on failure.
 */
public string read_file(File file) throws GLib.Error {
    string data;
    uint8[] binary_data;
    file.load_contents(null, out binary_data, null);
    data = (string) binary_data;
    binary_data = null;
    return (owned) data;
}

// TODO: read_file_async

/**
 * Replace the contents of a file with a text in UTF-8 encoding.
 *
 * Parent directories are created as necessary.
 *
 * @param file        The file to overwrite.
 * @param contents    The contents of the file.
 * @param io_priority    The priority of the I/O operation.
 * @param cancellable    To cancel the operation.
 * @throws GLib.Error on failure
 */
public async void write_to_file_async(
    File file, owned string contents, int io_priority=GLib.Priority.DEFAULT, Cancellable? cancellable=null)
throws GLib.Error {
    Bytes bytes = String.as_bytes((owned) contents);
    yield make_dirs_async(file.get_parent(), io_priority, cancellable);
    yield file.replace_contents_bytes_async(bytes, null, false, FileCreateFlags.NONE, cancellable, null);
}


/**
 * Make directory with parents, ignore if it exists.
 *
 * @param directory    the directory to create
 * @throws GLib.Error on failure but not if it already exists.
 */
public void make_dirs(GLib.File directory) throws GLib.Error {
    try {
        directory.make_directory_with_parents();
    } catch (GLib.Error e) {
        if (!(e is GLib.IOError.EXISTS)) {
            throw e;
        }
    }
}


/**
 * Make a directory and its parents, ignore if they already exist.
 *
 * @param directory      The final directory to create.
 * @param io_priority    The priority of the I/O operation.
 * @param cancellable    To cancel the operation.
 * @throws GLib.Error on failure.
 */
public async void make_dirs_async(File directory, int io_priority=GLib.Priority.DEFAULT, Cancellable? cancellable=null)
throws GLib.Error {
    while (true) {
        try {
            yield directory.make_directory_async(io_priority, cancellable);
            break;
        } catch (GLib.Error e) {
            if (e is GLib.IOError.EXISTS) {
                FileInfo info = yield directory.query_info_async(
                    FileAttribute.STANDARD_TYPE, 0, io_priority, cancellable);
                if (info.get_file_type() != FileType.DIRECTORY) {
                    throw e;
                }
                break;
            } else if (e is GLib.IOError.NOT_FOUND) {
                yield make_dirs_async(directory.get_parent(), io_priority, cancellable);
            } else {
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
 * @param source_dir    The source directory.
 * @param target_dir    The target directory.
 * @throws GLib.Error on failure
 * @return `true` if the directory has been moved, `false` otherwise
 */
public bool move_dir_if_target_not_found(File source_dir, File target_dir) throws GLib.Error {
    if (source_dir.query_file_type(0, null) != FileType.DIRECTORY
    || target_dir.query_file_type(0, null) == FileType.DIRECTORY) {
        return false;
    }
    make_dirs(target_dir.get_parent());
    return source_dir.move(target_dir, 0, null, null);
}

// TODO: move_dir_if_target_not_found_async


/**
 * Remove files in a directory.
 *
 * @param dir          The directory to purge.
 * @param recursive    Whether to purge recursively.
 * @throws             GLib.Error on failure
 */
public void purge_directory_content(File dir, bool recursive=false) throws GLib.Error {
    FileEnumerator enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
    FileInfo file_info;
    while ((file_info = enumerator.next_file()) != null) {
        File f = dir.get_child(file_info.get_name());
        if (f.query_file_type(0) == FileType.DIRECTORY) {
            if (recursive) {
                purge_directory_content(f, true);
            }
        }
        f.delete();
    }
}

// TODO: purge_directory_content_async


/**
 * Delete directory and its content and ignore I/O errors.
 *
 * @param dir          The directory to remove.
 * @param recursive    Whether to purge recursively.
 * @return             `true` on success, `false` on failure
 */
public bool try_purge_dir(File dir, bool recursive=true) {
    try {
        purge_directory_content(dir, recursive);
        dir.delete();
    } catch (GLib.Error e) {
        return false;
    }
    return true;
}


/**
 * Recursively copy all files and directories.
 *
 * @param source_dir     The source directory.
 * @param dest_dir       The destination directory.
 * @param cancellable    To cancel the operation.
 * @throws GLib.Error on failure.
 */
public void copy_tree(File source_dir, File dest_dir, Cancellable? cancellable=null) throws GLib.Error {
    if (!dest_dir.query_exists()) {
        dest_dir.make_directory_with_parents();
    }
    FileEnumerator enumerator = source_dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
    FileInfo file_info;
    while ((file_info = enumerator.next_file()) != null) {
        string name = file_info.get_name();
        File source_item = source_dir.get_child(name);
        File dest_item = dest_dir.get_child(name);
        if (source_item.query_file_type(0) == FileType.DIRECTORY) {
            copy_tree(source_item, dest_item, cancellable);
        } else if (source_item.query_file_type(0) == FileType.REGULAR) {
            source_item.copy(dest_item, 0, cancellable);
        } else {
            warning("Skipped: %s", source_item.get_path());
        }
    }
}


/**
 * Recursively resolve a symbolic link.
 *
 * @param file           The file to be resolved if it is a symlink.
 * @param cancellable    To cancel the operation.
 * @return Resolved file object if the original was a symbolic link, the original file otherwise.
 */
public async File resolve_symlink(File file, Cancellable? cancellable) {
    File result = file;
    try {
        FileInfo info = yield file.query_info_async(
            "standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, cancellable);
        if (info.get_file_type() == FileType.SYMBOLIC_LINK) {
            string target = info.get_symlink_target();
            result = target[0] == '/' ? File.new_for_path(target) : file.get_parent().get_child(target);
            return yield resolve_symlink(result, cancellable);
        }
    } catch (GLib.Error e) {
        // FIXME: throw the error
        return result;
    }
    return result;
}


/**
 * Find process id for command basename.
 *
 * @param basename    The basename of program's path.
 * @return All process ids with given program basename.
 */
public int[] find_pid_by_basename(string basename) {
    int[] result = {};
    try {
        Dir procfs = Dir.open("/proc", 0);
        string? name = null;
        while ((name = procfs.read_name()) != null) {
            int pid = int.parse(name);
            string path = Path.build_filename("/proc", name, "exe");
            if (pid > 0 && FileUtils.test(path, FileTest.IS_SYMLINK)) {
                try {
                    string target = FileUtils.read_link(path);
                    if (Path.get_basename(target) == basename) {
                        result += pid;
                    }
                } catch (FileError e) {
                    if (pid > 1) {
                        warning("readlink error: %s.", e.message);
                    }
                }
            }
        }
    } catch (FileError e) {
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
public string? get_cmdline_for_pid(int pid) {
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
public int sigall(int[] pids, int signum) {
    foreach (int pid in pids) {
        int result = Posix.kill((Posix.pid_t) pid, signum);
        if (result != 0) {
            return result;
        }
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
 * @param checksum    The checksum type.
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
        if (!Blobs.hexadecimal_to_blob(id_string, out cached_machine_id)) {
            warning("Machine id is not a valid hexadecimal string.");
            cached_machine_id = id_string.data;
        }
    }
    return GLib.Hmac.compute_for_data(checksum, app_key, cached_machine_id);
}

[CCode(cname="HOST_NAME_MAX", cheader_filename="limits.h")]
private extern const int HOST_NAME_MAX;

public string? get_hostname() {
    char[] hostname = new char[HOST_NAME_MAX + 1];
    if (Posix.gethostname(hostname) != 0) {
        return null;
    }
    return (string) hostname;
}

} // namespace Drt.System
