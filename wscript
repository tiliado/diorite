# encoding: utf-8
#
# Copyright 2014-2017 Jiří Janoušek <janousek.jiri@gmail.com>
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

# Metadata #
#==========#

top = '.'
out = 'build'
APPNAME = "diorite"
VERSION = "0.3.3"

MIN_VALA = "0.34.0"
MIN_GLIB = "2.42.1"
MIN_GTK = "3.22.0"

# Extras #
#========#

from waflib.Errors import ConfigurationError
from waflib import Utils
from waflib.TaskGen import extension


TARGET_GLIB = MIN_GLIB.rsplit(".", 1)[0]
SERIES = VERSION.rsplit(".", 1)[0]
VERSIONS = tuple(int(i) for i in VERSION.split("."))
REVISION_SNAPSHOT = "snapshot"


def get_revision_id():
	import subprocess
	try:
		output = subprocess.Popen(["git", "describe", "--tags", "--long"], stdout=subprocess.PIPE).communicate()[0]
		__, revision_id = output.decode("utf-8").strip().split("-", 1)
		revision_id = revision_id.replace("-", ".")
	except Exception as e:
		revision_id = REVISION_SNAPSHOT
	return revision_id

def glib_encode_version(version):
	major, minor, _ = tuple(int(i) for i in version.split("."))
	return major << 16 | minor << 8

def vala_def(ctx, vala_definition):
	"""Appends a Vala definition"""
	if not hasattr(ctx.env, "VALA_DEFINES"):
		ctx.env.VALA_DEFINES = []
	if isinstance(vala_def, tuple) or isinstance(vala_def, list):
		for d in vala_definition:
			ctx.env.VALA_DEFINES.append(d)
	else:
		ctx.env.VALA_DEFINES.append(vala_definition)


def pkgconfig(ctx, pkg, uselib, version, mandatory=True, store=None, vala_def=None, define=None):
	"""Wrapper for ctx.check_cfg."""
	result = True
	try:
		res = ctx.check_cfg(package=pkg, uselib_store=uselib, atleast_version=version, mandatory=True, args = '--cflags --libs')
		if vala_def:
			vala_def(ctx, vala_def)
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


# Actions #
#=========#

def options(ctx):
	ctx.load('compiler_c vala')
	ctx.add_option('--noopt', action='store_true', default=False, dest='noopt', help="Turn off compiler optimizations")
	ctx.add_option('--flatpak', action='store_true', default=False, dest='flatpak', help="Enable Flatpak tweaks.")
	ctx.add_option('--nodebug', action='store_false', default=True, dest='debug', help="Turn off debugging symbols")
	
def configure(ctx):
	ctx.env.REVISION_ID = get_revision_id()
	
	ctx.msg("Version", VERSION, "GREEN")
	if ctx.env.REVISION_ID != REVISION_SNAPSHOT:
		ctx.msg("Upstream revision", ctx.env.REVISION_ID, "GREEN")
	else:
		ctx.msg("Upstream revision", "unknown", "RED")
	ctx.msg('Install prefix', ctx.options.prefix, "GREEN")
	
	ctx.env.append_unique("VALAFLAGS", "-v")
	ctx.env.append_unique("LINKFLAGS", ["-Wl,--no-undefined", "-Wl,--as-needed"])
	ctx.env.FLATPAK = ctx.options.flatpak
	if ctx.env.FLATPAK:
		vala_def(ctx, "FLATPAK")
	if not ctx.options.noopt:
		ctx.env.append_unique('CFLAGS', '-O2')
	if ctx.options.debug:
		ctx.env.append_unique('VALAFLAGS', '-g')
		ctx.env.append_unique('CFLAGS', '-g3')
		
	ctx.load('compiler_c vala')
	ctx.check_vala(min_version=tuple(int(i) for i in MIN_VALA.split(".")))
	pkgconfig(ctx, 'glib-2.0', 'GLIB', MIN_GLIB)
	pkgconfig(ctx, 'gthread-2.0', 'GTHREAD', MIN_GLIB)
	pkgconfig(ctx, 'gio-2.0', 'GIO', MIN_GLIB)
	pkgconfig(ctx, 'gio-unix-2.0', 'UNIXGIO', MIN_GLIB)
	pkgconfig(ctx, 'gtk+-3.0', 'GTK+', MIN_GTK)
	pkgconfig(ctx, 'gdk-3.0', 'GDK', MIN_GTK)
	pkgconfig(ctx, 'gdk-x11-3.0', 'GDKX11', MIN_GTK)
	pkgconfig(ctx, 'x11', 'X11', "0")
	pkgconfig(ctx, 'sqlite3', 'SQLITE', "3.7")
	
	ctx.define("DRT_VERSION", VERSION + "+" + ctx.env.REVISION_ID)
	ctx.define("DRT_REVISION", ctx.env.REVISION_ID)
	ctx.define("DRT_VERSION_MAJOR", VERSIONS[0])
	ctx.define("DRT_VERSION_MINOR", VERSIONS[1])
	ctx.define("DRT_VERSION_BUGFIX", VERSIONS[2])
	ctx.define("DRT_VERSION_SUFFIX", ctx.env.REVISION_ID)
	
	ctx.define('GLIB_VERSION_MAX_ALLOWED', glib_encode_version(MIN_GLIB))
	ctx.define('GLIB_VERSION_MIN_REQUIRED', glib_encode_version(MIN_GLIB))
	ctx.define('GDK_VERSION_MAX_ALLOWED', glib_encode_version(MIN_GTK))
	ctx.define('GDK_VERSION_MIN_REQUIRED', glib_encode_version(MIN_GTK))

def build(ctx):
	#~ print ctx.env
	PC_CFLAGS = ""
	DIORITE_GLIB = "{}glib-{}".format(APPNAME, SERIES)
	DIORITE_GTK = "{}gtk-{}".format(APPNAME, SERIES)
	DIORITE_DB = "{}db-{}".format(APPNAME, SERIES)
	DIORITE_TESTS = "{}tests-{}".format(APPNAME, SERIES)
	RUN_DIORITE_TESTS = "run-{}".format(DIORITE_TESTS)
	packages = 'posix glib-2.0 gio-2.0 gio-unix-2.0'
	packages_gtk = packages + " gtk+-3.0 x11 gdk-3.0 gdk-x11-3.0"
	uselib = 'GLIB GIO UNIXGIO'
	uselib_gtk = uselib + " GTK+ GDK X11 GDKX11"
	vala_defines = ctx.env.VALA_DEFINES
	
	ctx(features = "c cshlib",
		target = DIORITE_GLIB,
		name = DIORITE_GLIB,
		source = ctx.path.ant_glob('src/glib/*.vala') + ctx.path.ant_glob('src/glib/*.vapi'),
		packages = packages,
		uselib = uselib,
		vala_defines = vala_defines,
		cflags = ['-DG_LOG_DOMAIN="DioriteGlib"'],
		vapi_dirs = ['vapi'],
		vala_target_glib = TARGET_GLIB,
	)
	
	ctx(features = "c cshlib",
		target = DIORITE_GTK,
		name = DIORITE_GTK,
		source = ctx.path.ant_glob('src/gtk/*.vala'),
		packages = packages_gtk,
		uselib = uselib_gtk,
		use = [DIORITE_GLIB],
		vala_defines = vala_defines,
		cflags = ['-DG_LOG_DOMAIN="DioriteGtk"'],
		vapi_dirs = ['vapi'],
		vala_target_glib = TARGET_GLIB,
	)
	
	ctx(features = "c cshlib",
		target = DIORITE_DB,
		name = DIORITE_DB,
		source = ctx.path.ant_glob('src/db/*.vala'),
		packages = packages + " sqlite3",
		uselib = uselib + " SQLITE",
		use = [DIORITE_GLIB],
		vala_defines = vala_defines,
		cflags = ['-DG_LOG_DOMAIN="DioriteDB"'],
		vapi_dirs = ['vapi'],
		vala_target_glib = TARGET_GLIB,
	)
	
	ctx(features = "c cshlib",
		target = DIORITE_TESTS,
		name = DIORITE_TESTS,
		source = ctx.path.ant_glob('src/tests/*.vala'),
		packages = packages_gtk,
		uselib = uselib_gtk,
		use = [DIORITE_GLIB, DIORITE_GTK, DIORITE_DB],
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
		target=ctx.path.find_or_declare("%s.vala" % RUN_DIORITE_TESTS)
	)
	
	ctx.program(
		target = RUN_DIORITE_TESTS,
		source = [ctx.path.find_or_declare("%s.vala" % RUN_DIORITE_TESTS)],
		packages = packages,
		uselib = uselib,
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
		LIBNAME=DIORITE_GLIB,
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
		LIBNAME=DIORITE_GTK,
		DIORITE_GLIB=DIORITE_GLIB,
	)
	
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
		LIBNAME=DIORITE_DB,
		DIORITE_GLIB=DIORITE_GLIB,
	)
	
	ctx.install_as('${BINDIR}/diorite-testgen-' + SERIES, 'testgen.py', chmod=Utils.O755)
