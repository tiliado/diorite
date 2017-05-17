#! /usr/bin/env python
# encoding: UTF-8
# Copyright 2009 Nicolas Joseph
# Copyright 2017 Jiří Janoušek <janousek.jiri@gmail.com>

"""
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
"""

from waflib import Task, Utils, Errors, Logs, Options, Node, Build
from waflib.TaskGen import feature, before_method


class valadoc(Task.Task):
	vars  = ['VALADOC', 'VALADOCFLAGS']
	color = 'BLUE'
	after = ['cprogram', 'cstlib', 'cshlib']
	
	def runnable_status(self):
		if self.skip:
			return Task.SKIP_ME 
		else:
			return super(valadoc, self).runnable_status()
	
	def run(self):
		cmd = self.env.VALADOC + self.env.VALADOCFLAGS
		cmd.extend([a.abspath() for a in self.inputs])
		return self.exec_command(cmd)


@before_method('process_source')
@feature('valadoc')
def process_valadoc2(self):
	"""
	Generate API documentation from Vala source code with valadoc

	doc = bld(
		features = 'valadoc',
		files = bld.path.ant_glob('src/**/*.vala'),
		output_dir = '../doc/html',
		package_name = 'vala-gtk-example',
		package_version = '1.0.0',
		packages = 'gtk+-2.0',
		vapi_dirs = '../vapi',
		force = True
	)
	"""
	
	try:
		# Don't process vala source files with valac
		self.meths.remove('process_source')
	except ValueError:
		pass
	
	valadoctask = self.valadoctask = self.create_task('valadoc')
	
	def addflags(flags):
		self.env.append_value('VALADOCFLAGS', flags)
	
	def add_attr_to_flags(name, default=None, mandatory=False):
		value = getattr(self, name, default)
		setattr(self, name, value)
		if value:
			addflags('--%s=%s' % (name.replace("_", "-"), value))
			return True
		elif mandatory:
			self.bld.fatal('Missing attribute "%s".' % name)
		else:
			return False 
	
	# Input files
	files = getattr(self, "files", None)
	if not files:
		self.bld.fatal('Missing input files')
	valadoctask.inputs.extend(files)
	
	# Output directory
	if hasattr(self, 'output_dir'):
		if isinstance(self.output_dir, str):
			valadoctask.output_dir = self.path.get_bld().make_node(self.output_dir)
			try:
				valadoctask.output_dir.mkdir()
			except OSError:
				raise self.bld.fatal('Cannot create the valadoc output  dir %r' % valadoctask.output_dir)
		else:
			valadoctask.output_dir = self.output_dir
	else:
		raise self.bld.fatal('No valadoc output directory')
	valadoctask.outputs.append(valadoctask.output_dir)
	addflags('--directory=%s' % valadoctask.output_dir.abspath())
	
	# Attributes/flags
	valadoctask.skip = getattr(self, "skip", False)
	add_attr_to_flags("package_name", mandatory=True)
	add_attr_to_flags("package_version", mandatory=True)
	add_attr_to_flags("profile", 'gobject')
	add_attr_to_flags("doclet")
	add_attr_to_flags("gir")
	add_attr_to_flags("importdir")
	if not getattr(self, "protected", True):
		addflags("--no-protected")
	if getattr(self, "add_deps", False):
		addflags("--deps")
	flags = (
		"internal", "private", "force", "verbose", "use_svg_images",
		"enable_experimental", "enable_experimental_non_null")
	for flag in flags:
		if getattr(self, flag, False):
			addflags("--%s" % flag.replace("_", "-"))
	
	# Lists
	self.packages = Utils.to_list(getattr(self, 'packages', []))
	self.use = Utils.to_list(getattr(self, 'use', []))
	self.import_packages = Utils.to_list(getattr(self, 'importpackages', []))
	self.vapi_dirs = Utils.to_list(getattr(self, 'vapi_dirs', []))
	self.gir_dirs = Utils.to_list(getattr(self, 'gir_dirs', []))
	self.vala_defines = Utils.to_list(getattr(self, 'vala_defines', []))
	
	if self.profile == 'gobject':
		if not 'GOBJECT' in self.use:
			self.use.append('GOBJECT')

	self.vala_target_glib = getattr(self, 'vala_target_glib', getattr(Options.options, 'vala_target_glib', None))
	if self.vala_target_glib:
		addflags('--target-glib=%s' % self.vala_target_glib)
	
	if hasattr(self, 'use'):
		local_packages = Utils.to_list(self.use)[:] # make sure to have a copy
		seen = []
		while len(local_packages) > 0:
			package = local_packages.pop()
			if package in seen:
				continue
			seen.append(package)
			
			# check if the package exists
			try:
				package_obj = self.bld.get_tgen_by_name(package)
			except Errors.WafError:
				continue

			# in practice the other task is already processed
			# but this makes it explicit
			package_obj.post()
			package_name = package_obj.target
			for task in package_obj.tasks:
				if isinstance(task, Build.inst):
					# TODO are we not expecting just valatask here?
					continue
				for output in task.outputs:
					if output.name == package_name + ".vapi":
						valadoctask.set_run_after(task)
						if package_name not in self.packages:
							self.packages.append(package_name)
						if output.parent not in self.vapi_dirs:
							self.vapi_dirs.append(output.parent)

			if hasattr(package_obj, 'use'):
				lst = self.to_list(package_obj.use)
				lst.reverse()
				local_packages = [pkg for pkg in lst if pkg not in seen] + local_packages
	
	addflags(['--define=%s' % x for x in self.vala_defines])
	addflags(['--pkg=%s' % x for x in self.packages])
	addflags(['--import=%s' % x for x in self.import_packages])
	
	for vapi_dir in self.vapi_dirs:
		if isinstance(vapi_dir, Node.Node):
			node = vapi_dir
		else:
			node = self.path.find_dir(vapi_dir)
		if not node:
			Logs.warn('Unable to locate Vala API directory: %r', vapi_dir)
		else:
			addflags('--vapidir=%s' % node.abspath())
	
	for gir_dir in self.gir_dirs:
		if isinstance(gir_dir, Node.Node):
			node = gir_dir
		else:
			node = self.path.find_dir(gir_dir)
		if not node:
			Logs.warn('Unable to locate gir directory: %r', gir_dir)
		else:
			addflags('--girdir=%s' % node.abspath())
	

def configure(conf):
	conf.find_program('valadoc', errmsg='You must install valadoc <http://live.gnome.org/Valadoc> for generate the API documentation')

