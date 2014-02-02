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

namespace Diorite.Check
{

class Generator
{
	private static string directory;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] vapi_dirs;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] packages;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] sources;
	
	const OptionEntry[] options =
	{
		{ "vapidir", 0, 0, OptionArg.FILENAME_ARRAY, ref vapi_dirs, "Look for package bindings in DIRECTORY", "DIRECTORY..." },
		{ "pkg", 0, 0, OptionArg.STRING_ARRAY, ref packages, "Include binding for PACKAGE", "PACKAGE..." },
		{ "directory", 'd', 0, OptionArg.FILENAME, ref directory, "Output directory", "DIRECTORY" },
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref sources, null, "FILE..." },
		{ null }
	};
	
	private Vala.CodeContext context;
	
	public Generator()
	{
		context = new Vala.CodeContext();
		context.verbose_mode = true;
		context.report.enable_warnings = true;
		Vala.CodeContext.push(context);
		context.basedir = ".";
		context.directory = directory ?? "./testgen";
		context.vapi_directories = vapi_dirs;
		context.profile = Vala.Profile.GOBJECT;
		context.add_define("GOBJECT");
	
		int glib_major = 2;
		int glib_minor = 22;
		context.target_glib_major = glib_major;
		context.target_glib_minor = glib_minor;
		
		for (int i = 16; i <= glib_minor; i += 2)
			context.add_define ("GLIB_2_%d".printf(i));
	}
	
	public int run()
	{
		if (!add_packages({"glib-2.0", "gobject-2.0", "dioriteglib"}))
		{
			Vala.Report.error(null, "Failed to load essential dependencies.");
			return 1;
		}
		
		if (!add_packages(packages))
			return 1;
		
		if (!add_source_files(sources))
			return 1;
		
		var parser = new Vala.Parser();
		parser.parse(context);
		if (context.report.get_errors() > 0)
			return 1;
		
		var gir_parser = new Vala.GirParser();
		gir_parser.parse(context);
		if (context.report.get_errors() > 0)
			return 1;
		
		context.check();
		if (context.report.get_errors() > 0)
			return 1;
		
		var preprocessor = new Preprocessor(context, directory);
		preprocessor.run();
		if (context.report.get_errors() > 0)
			return 1;
		
		return 0;
	}
	
	
	private bool add_packages(string[] packages)
	{
		var result = true;
		foreach (var pkg in packages)
			result = add_package(pkg) && result;
		return result;
	}
	
	private bool add_package(string pkg)
	{
		if (context.has_package(pkg))
			return true;

		var pkg_path = context.get_vapi_path(pkg) ?? context.get_gir_path(pkg);
		if (pkg_path == null)
		{
			Vala.Report.error(null, "Package `%s' has not been found.".printf(pkg));
			return false;
		}

		context.add_package(pkg);
		context.add_source_file(new Vala.SourceFile(context, Vala.SourceFileType.PACKAGE, pkg_path));

		return add_package_deps(pkg, pkg_path);
	}
	
	private bool add_package_deps(string pkg, string pkg_path)
	{
		var result = true;
		var path = Path.build_filename(Path.get_dirname(pkg_path), "%s.deps".printf(pkg));
		if (!FileUtils.test(path, FileTest.EXISTS))
			return true; // No deps file
		
		try
		{
			string list;
			ulong size;
			FileUtils.get_contents(path, out list, out size);
			foreach (var name in list.split("\n"))
			{
				name = name.strip ();
				if (name != "")
					result = add_package(name) && result;
				
			}
		}
		catch (GLib.Error e)
		{
			Vala.Report.error(null, "Error during reading dependency file: %s".printf(e.message));
		}
		
		return result;
	}
	
	private bool add_source_files(string[] files)
	{
		var result = true;
		foreach (var path in files)
			result = add_source_file(path) && result;
		return result;
	}
	
	private bool add_source_file(string path)
	{
		if (!path.has_suffix(".vala"))
		{
			Vala.Report.error(null, "File '%s' is not supported, only *.vala files.".printf(path));
			return false;
		}
		
		if (!FileUtils.test(path, FileTest.EXISTS))
		{
			Vala.Report.error(null, "File '%s' not found.".printf(path));
			return false;
		}
		
		string content;
		ulong size;
		try
		{
			FileUtils.get_contents(path, out content, out size);
		}
		catch (GLib.Error e)
		{
			Vala.Report.error(null, "Error during reading source file '%s': %s".printf(path, e.message));
			return false;
		}
		
		var source = new Vala.SourceFile(context, Vala.SourceFileType.SOURCE, path, content);
		var glib_ns = new Vala.UsingDirective(new Vala.UnresolvedSymbol(null, "GLib", null));
		source.add_using_directive(glib_ns);
		context.root.add_using_directive(glib_ns);
		context.add_source_file(source);
		
		return true;
	}
	
	static int main(string[] args)
	{
		try
		{
			var opt_context = new OptionContext("- Diorite Test Generator");
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		}
		catch (OptionError e)
		{
			stdout.printf("%s\n", e.message);
			return 1;
		}
		
		if (sources == null)
		{
			stderr.printf ("No source file specified.\n");
			return 1;
		}
		
		var gen = new Generator();
		return gen.run();
	}
}

} // namespace Diorite.Check
