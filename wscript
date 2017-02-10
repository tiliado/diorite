# encoding: utf-8
#
# Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Top of source tree
top = '.'
# Build directory
out = 'build'

# Application name and version
APPNAME = "diorite"
VERSION = "0.3.1+"
SERIES = VERSION.rsplit(".", 1)[0]

TARGET_GLIB_TUPLE = (2, 40)
TARGET_GLIB = '{}.{}'.format(*TARGET_GLIB_TUPLE)
TARGET_GTK_TUPLE = (3, 10)
TARGET_GTK = '{}.{}'.format(*TARGET_GTK_TUPLE)

import subprocess
try:
	try:
		# Read revision info from file revision-info created by ./waf dist
		timestamp, short_id, long_id = open("upstream-revision", "r").read().split(" ", 2)
	except Exception as e:
		# Read revision info from current branch
		output = subprocess.Popen(["git", "log", "-n", "1", "--pretty=format:%ct %h %H"], stdout=subprocess.PIPE).communicate()[0]
		timestamp, short_id, long_id = output.split(" ", 2)
	
	from datetime import datetime
	timestamp = datetime.utcfromtimestamp(int(timestamp))
except Exception as e:
	timestamp, short_id, long_id = None, "fuzzy", "fuzzy"

if VERSION[-1] == "+":
	if timestamp:
		VERSION += "{}.{}".format(timestamp.strftime("%Y%m%d%H%M"), short_id)
	else:
		VERSION = VERSION[:-1]

import sys
from waflib.Configure import conf
from waflib.Errors import ConfigurationError
from waflib.Context import WAFVERSION
from waflib import Utils

WAF_VERSION = tuple(int(i) for i in WAFVERSION.split("."))
REQUIRED_VERSION = (1, 7, 14) 
if WAF_VERSION < REQUIRED_VERSION:
	print("Too old waflib %s < %s. Use waf binary distributed with the source code!" % (WAF_VERSION, REQUIRED_VERSION))
	sys.exit(1)

LINUX = "LINUX"
WIN = "WIN"

if sys.platform.startswith("linux"):
	_PLATFORM = LINUX
elif sys.platform.startswith("win"):
	_PLATFORM = WIN
else:
	_PLATFORM = sys.platform.upper()

@conf
def vala_def(ctx, vala_definition):
	"""Appends a Vala definition"""
	if not hasattr(ctx.env, "VALA_DEFINES"):
		ctx.env.VALA_DEFINES = []
	if isinstance(vala_def, tuple) or isinstance(vala_def, list):
		for d in vala_definition:
			ctx.env.VALA_DEFINES.append(d)
	else:
		ctx.env.VALA_DEFINES.append(vala_definition)

@conf
def check_dep(ctx, pkg, uselib, version, mandatory=True, store=None, vala_def=None, define=None):
	"""Wrapper for ctx.check_cfg."""
	result = True
	try:
		res = ctx.check_cfg(package=pkg, uselib_store=uselib, atleast_version=version, mandatory=True, args = '--cflags --libs')
		if vala_def:
			ctx.vala_def(vala_def)
		if define:
			for key, value in define.iteritems():
				ctx.define(key, value)
	except ConfigurationError as e:
		result = False
		if mandatory:
			raise e
	finally:
		if store is not None:
			ctx.env[store] = result
	return res

# Add extra options to ./waf command
def options(ctx):
	ctx.load('compiler_c vala')
	ctx.add_option('--noopt', action='store_true', default=False, dest='noopt', help="Turn off compiler optimizations")
	ctx.add_option('--debug', action='store_true', default=True, dest='debug', help="Turn on debugging symbols")
	ctx.add_option('--no-debug', action='store_false', dest='debug', help="Turn off debugging symbols")
	ctx.add_option('--no-ldconfig', action='store_false', default=True, dest='ldconfig', help="Don't run ldconfig after installation")
	ctx.add_option('--platform', default=_PLATFORM, help="Target platform")
	ctx.add_option('--with-experimental-api', action='store_true', default=False, dest='experimental', help="Include experimental API.")

# Configure build process
def configure(ctx):
	
	ctx.env.PLATFORM = PLATFORM = ctx.options.platform.upper()
	if PLATFORM not in (WIN, LINUX):
		print("Unsupported platform %s. Please try to talk to devs to consider support of your platform." % sys.platform)
		sys.exit(1)
	
	ctx.msg("Version", VERSION, "GREEN")
	if long_id != "fuzzy":
		ctx.msg("Upstream revision", long_id, "GREEN")
	else:
		ctx.msg("Upstream revision", "unknown (unsupported build)", "RED")
	
	ctx.define(PLATFORM, 1)
	ctx.env.VALA_DEFINES = [PLATFORM]
	ctx.msg('Target platform', PLATFORM, "GREEN")
	ctx.msg('Install prefix', ctx.options.prefix, "GREEN")
	
	ctx.load('compiler_c vala')
	
	# Enable experimental API
	ctx.env.EXPERIMENTAL = ctx.options.experimental
	if ctx.env.EXPERIMENTAL:
		ctx.vala_def("EXPERIMENTAL")
		ctx.check_vala(min_version=(0,26,1))
	else:
		ctx.check_vala(min_version=(0,22,1))
	
	# Don't be quiet
	ctx.env.VALAFLAGS.remove("--quiet")
	ctx.env.append_value("VALAFLAGS", "-v")
	
	# enable threading
	ctx.env.append_value("VALAFLAGS", "--thread")
	
	# Turn compiler optimizations on/off
	if ctx.options.noopt:
		ctx.msg('Compiler optimizations', "OFF?!", "RED")
		ctx.env.append_unique('CFLAGS', '-O0')
	else:
		ctx.env.append_unique('CFLAGS', '-O2')
		ctx.msg('Compiler optimizations', "ON", "GREEN")
	
	# Include debugging symbols
	if ctx.options.debug:
		#~ ctx.env.append_unique('VALAFLAGS', '-g')
		if PLATFORM == LINUX:
			ctx.env.append_unique('CFLAGS', '-g3')
		elif PLATFORM == WIN:
			ctx.env.append_unique('CFLAGS', ['-g', '-gdwarf-2'])
	
	# Anti-underlinking and anti-overlinking linker flags.
	ctx.env.append_unique("LINKFLAGS", ["-Wl,--no-undefined", "-Wl,--as-needed"])
	
	# Check dependencies
	ctx.check_dep('glib-2.0', 'GLIB', TARGET_GLIB)
	ctx.check_dep('gthread-2.0', 'GTHREAD', TARGET_GLIB)
	ctx.check_dep('gio-2.0', 'GIO', TARGET_GLIB)
	ctx.check_dep('gtk+-3.0', 'GTK+', TARGET_GTK)
	ctx.check_dep('gdk-3.0', 'GDK', TARGET_GTK)
	ctx.check_dep('gdk-x11-3.0', 'GDKX11', TARGET_GTK)
	ctx.check_dep('x11', 'X11', "0")
	
	if ctx.env.EXPERIMENTAL:
		ctx.check_dep('sqlite3', 'SQLITE', "3.7")
	
	ctx.define('GLIB_VERSION_MAX_ALLOWED', _glib_encode_version(*TARGET_GLIB_TUPLE))
	ctx.define('GLIB_VERSION_MIN_REQUIRED', _glib_encode_version(*TARGET_GLIB_TUPLE))
	ctx.define('GDK_VERSION_MAX_ALLOWED', _glib_encode_version(*TARGET_GTK_TUPLE))
	ctx.define('GDK_VERSION_MIN_REQUIRED', _glib_encode_version(*TARGET_GTK_TUPLE))
	
	VERSIONS = VERSION.split("+")
	if len(VERSIONS) == 1:
		VERSION_SUFFIX = "stable"
	else:
		VERSION_SUFFIX = VERSIONS[1]
	VERSIONS = tuple(int(i) for i in VERSIONS[0].split("."))
	ctx.define("DRT_VERSION", VERSION)
	ctx.define("DRT_REVISION", long_id)
	ctx.define("DRT_VERSION_MAJOR", VERSIONS[0])
	ctx.define("DRT_VERSION_MINOR", VERSIONS[1])
	ctx.define("DRT_VERSION_BUGFIX", VERSIONS[2])
	ctx.define("DRT_VERSION_SUFFIX", VERSION_SUFFIX)
	
	if PLATFORM == LINUX:
		ctx.check_dep('gio-unix-2.0', 'UNIXGIO', TARGET_GLIB)
	elif PLATFORM == WIN:
		ctx.check_dep('gio-windows-2.0', 'WINGIO', TARGET_GLIB)

def build(ctx):
	#~ print ctx.env
	PLATFORM = ctx.env.PLATFORM
	DIORITE_GLIB = "{}glib-{}".format(APPNAME, SERIES)
	DIORITE_GTK = "{}gtk-{}".format(APPNAME, SERIES)
	DIORITE_DB = "{}db-{}".format(APPNAME, SERIES)
	DIORITE_TESTS = "{}tests-{}".format(APPNAME, SERIES)
	RUN_DIORITE_TESTS = "run-{}".format(DIORITE_TESTS)
	packages = 'posix glib-2.0 gio-2.0'
	uselib = 'GLIB GTHREAD'
	vala_defines = ctx.env.VALA_DEFINES
	
	if PLATFORM == WIN:
		DIORITE_GLIB_LIBNAME = "dioriteglib-" + API_VERSION.split(".")[0]
		DIORITE_GTK_LIBNAME = "dioritegtk-" + API_VERSION.split(".")[0]
		DIORITE_DB_LIBNAME = "dioritedb-" + API_VERSION.split(".")[0]
		PC_CFLAGS="-mms-bitfields"
		uselib += " WINGIO"
		packages += " gio-windows-2.0 win32"
	else:
		DIORITE_GLIB_LIBNAME = DIORITE_GLIB
		DIORITE_GTK_LIBNAME = DIORITE_GTK
		DIORITE_DB_LIBNAME = DIORITE_DB
		DIORITE_TESTS_LIBNAME = DIORITE_DB
		PC_CFLAGS=""
		uselib += " UNIXGIO"
		packages += " gio-unix-2.0"
	
	ctx(features = "c cshlib",
		target = DIORITE_GLIB,
		name = DIORITE_GLIB,
		source = ctx.path.ant_glob('src/glib/*.vala') + ctx.path.ant_glob('src/glib/*.c') + ctx.path.ant_glob('src/glib/*.vapi'),
		packages = packages,
		uselib = uselib,
		includes = ["src/glib"],
		vala_defines = vala_defines,
		cflags = ['-DG_LOG_DOMAIN="DioriteGlib"'],
		vapi_dirs = ['vapi'],
		vala_target_glib = TARGET_GLIB,
	)
	
	ctx(features = "c cshlib",
		target = DIORITE_GTK,
		name = DIORITE_GTK,
		source = ctx.path.ant_glob('src/gtk/*.vala') + ctx.path.ant_glob('src/gtk/*.c'),
		packages = " gtk+-3.0 x11 gdk-3.0 gdk-x11-3.0 gio-2.0 glib-2.0",
		uselib = "GTK+ GDK X11 GDKX11 GIO GLIB",
		use = [DIORITE_GLIB],
		includes = ["src/gtk"],
		vala_defines = vala_defines,
		cflags = ['-DG_LOG_DOMAIN="DioriteGtk"'],
		vapi_dirs = ['vapi'],
		vala_target_glib = TARGET_GLIB,
	)
	
	if ctx.env.EXPERIMENTAL:
		ctx(features = "c cshlib",
			target = DIORITE_DB,
			name = DIORITE_DB,
			source = ctx.path.ant_glob('src/db/*.vala') + ctx.path.ant_glob('src/db/*.c'),
			packages = packages + " sqlite3",
			uselib = uselib + " SQLITE",
			use = [DIORITE_GLIB],
			includes = ["src/db"],
			vala_defines = vala_defines,
			cflags = ['-DG_LOG_DOMAIN="DioriteDB"'],
			vapi_dirs = ['vapi'],
			vala_target_glib = TARGET_GLIB,
		)
		
		ctx(features = "c cshlib",
			target = DIORITE_TESTS,
			name = DIORITE_TESTS,
			source = ctx.path.ant_glob('src/tests/*.vala') + ctx.path.ant_glob('src/tests/*.c'),
			packages = " gtk+-3.0 x11 gdk-3.0 gdk-x11-3.0 gio-2.0 glib-2.0",
			uselib = "GTK+ GDK X11 GDKX11 GIO GLIB",
			use = [DIORITE_GLIB, DIORITE_GTK, DIORITE_DB],
			includes = ["src/tests"],
			vala_defines = vala_defines,
			cflags = ['-DG_LOG_DOMAIN="DioriteTests"'],
			vapi_dirs = ['vapi'],
			vala_target_glib = TARGET_GLIB,
			install_path = None,
			install_binding = False
		)
		ctx(
			rule='../testgen.py -i ${SRC} -o ${TGT}',
			source=ctx.path.find_or_declare('%s.vapi' % DIORITE_TESTS),
			target=ctx.path.find_or_declare("%s.vala" % RUN_DIORITE_TESTS))
		ctx.program(
			target = RUN_DIORITE_TESTS,
			source = [ctx.path.find_or_declare("%s.vala" % RUN_DIORITE_TESTS)],
			packages = "gio-2.0 glib-2.0",
			uselib = "GIO GLIB",
			use = [DIORITE_GLIB, DIORITE_GTK, DIORITE_DB, DIORITE_TESTS],
			vala_defines = vala_defines,
			defines = ['G_LOG_DOMAIN="DioriteTests"'],
			vapi_dirs = ['vapi'],
			vala_target_glib = TARGET_GLIB,
			install_path = None
		)
	
	ctx(features = 'subst',
		source='src/dioriteglib.pc.in',
		target='{}glib-{}.pc'.format(APPNAME, SERIES),
		install_path='${LIBDIR}/pkgconfig',
		VERSION=VERSION,
		PREFIX=ctx.env.PREFIX,
		INCLUDEDIR = ctx.env.INCLUDEDIR,
		LIBDIR = ctx.env.LIBDIR,
		APPNAME=APPNAME,
		PC_CFLAGS=PC_CFLAGS,
		LIBNAME=DIORITE_GLIB_LIBNAME,
		SERIES=SERIES,
		)
	
	ctx(features = 'subst',
		source='src/dioritegtk.pc.in',
		target='{}gtk-{}.pc'.format(APPNAME, SERIES),
		install_path='${LIBDIR}/pkgconfig',
		VERSION=VERSION,
		PREFIX=ctx.env.PREFIX,
		INCLUDEDIR = ctx.env.INCLUDEDIR,
		LIBDIR = ctx.env.LIBDIR,
		APPNAME=APPNAME,
		PC_CFLAGS=PC_CFLAGS,
		LIBNAME=DIORITE_GTK_LIBNAME,
		DIORITE_GLIB=DIORITE_GLIB,
		)
	
	if ctx.env.EXPERIMENTAL:
		ctx(features = 'subst',
		source='src/dioritedb.pc.in',
		target='{}db-{}.pc'.format(APPNAME, SERIES),
		install_path='${LIBDIR}/pkgconfig',
		VERSION=VERSION,
		PREFIX=ctx.env.PREFIX,
		INCLUDEDIR = ctx.env.INCLUDEDIR,
		LIBDIR = ctx.env.LIBDIR,
		APPNAME=APPNAME,
		PC_CFLAGS=PC_CFLAGS,
		LIBNAME=DIORITE_DB_LIBNAME,
		DIORITE_GLIB=DIORITE_GLIB,
		)
		
	if PLATFORM == WIN :
		ctx.program(
		target = "dioriteinterrupthelper",
		source = ['src/helpers/interrupthelper.vala'],
		use = [DIORITE_GLIB],
		packages = 'glib-2.0 win32',
		uselib = 'GLIB',
		vapi_dirs = ['vapi'],
		vala_target_glib = TARGET_GLIB,
		)
	
	ctx.install_as('${BINDIR}/diorite-testgen-' + SERIES, 'testgen.py', chmod=Utils.O755)
	ctx.add_post_fun(post)

def dist(ctx):
	ctx.algo = "tar.gz"
	ctx.excl = '.git .gitignore build/* **/.waf* **/*~ **/*.swp **/.lock* **/*.pyc'
	ctx.exec_command("git log -n 1 --pretty='format:%ct %h %H' > upstream-revision")
	
	def archive():
		ctx._archive()
		node = ctx.path.find_node("upstream-revision")
		if node:
			node.delete()
	ctx._archive = ctx.archive
	ctx.archive = archive

def post(ctx):
	if ctx.cmd in ('install', 'uninstall'):
		if ctx.env.PLATFORM == LINUX and ctx.options.ldconfig:
			ctx.exec_command('/sbin/ldconfig') 

def _glib_encode_version(major, minor):
	return major << 16 | minor << 8

from waflib.TaskGen import extension
@extension('.vapi')
def vapi_file(self, node):
	try:
		valatask = self.valatask
	except AttributeError:
		valatask = self.valatask = self.create_task('valac')
		self.init_vala_task()

	valatask.inputs.append(node)
