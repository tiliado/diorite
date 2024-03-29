# encoding: utf-8
#
# Copyright 2014-2020 Jiří Janoušek <janousek.jiri@gmail.com>
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
VERSION = "4.24.0"

MIN_VALA = "0.42.0"
MIN_GLIB = "2.56.1"
MIN_GTK = "3.22.30"
MIN_GEE = "0.20.1"

# Extras #
#========#

import os
import sys
assert sys.version_info >= (3, 4, 0), "Run waf with Python >= 3.4"

from waflib.Errors import ConfigurationError
from waflib.Configure import conf
from waflib import TaskGen, Utils, Errors, Node, Task

TARGET_GLIB = MIN_GLIB.rsplit(".", 1)[0]
REVISION_SNAPSHOT = "snapshot"


def get_git_version():
    import os
    import subprocess
    if os.path.isdir(".git"):
        output = subprocess.check_output(["git", "describe", "--tags", "--long"])
        return output.decode("utf-8").strip().rsplit("-", 2)
    return VERSION, "0", REVISION_SNAPSHOT

def add_version_info(ctx):
    bare_version, n_commits, revision_id = get_git_version()
    if revision_id != REVISION_SNAPSHOT:
        revision_id = "{}-{}".format(n_commits, revision_id)
    numeric, pre_release = bare_version.split("-", 1) if "-" in bare_version else (bare_version, "")
    versions = [int(i) for i in numeric.split(".")]
    if pre_release:
        pre_release = "-{}{}".format(pre_release, n_commits)
    else:
        versions[2] += int(n_commits)
    version = "{}.{}.{}{}".format(*versions, pre_release)
    series = str(versions[0])
    ctx.env.SERIES = series
    ctx.env.VERSION = version
    ctx.env.VERSIONS = versions
    ctx.env.REVISION_ID = revision_id


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


@conf
def valadoc(ctx, package_name, doclets="devhelp html", **kwargs):
    if ctx.env.BUILD_VALADOC:
        doclets = [s.strip() for s in doclets.split()]
        taskgens = []
        for doclet in doclets:
            name = "valadoc-%s-%s" % (package_name, doclet)
            taskgens.append(ctx(
                features="valadoc",
                doclet = doclet,
                package_name = package_name,
                name = name,
                target = name,
                output_dir = "doc/%s/%s" % (doclet, package_name),
                add_deps = doclet == "devhelp",
                skip = not ctx.options.buildvaladoc,
                **kwargs))
        return taskgens

@conf
def gir_compile(ctx, name, lib):
    return ctx(
        rule='${GIR_COMPILER} ${SRC} --output=${TGT} --shared-library="lib%s.so"' % lib,
        source=ctx.path.find_or_declare(name + ".gir"),
        target=ctx.path.find_or_declare(name + ".typelib"),
        install_path="${LIBDIR}/girepository-1.0")

@TaskGen.feature('valalint')
@TaskGen.before_method('process_source', 'process_rule')
def valalint_taskgen(self):
    source = Utils.to_list(getattr(self, 'source', []))
    if isinstance(source, Node.Node):
        source = [source]
    if not source:
        raise Errors.WafError('no input file')
    for i, item in enumerate(source):
        if isinstance(item, str):
            source[i] =  self.path.find_resource(item)
        elif not isinstance(item, Node.Node):
            raise Errors.WafError('invalid source for %r' % self)
    self.source = []
    task = self.create_task('valalint', source, None)

    if getattr(self, 'packages', None):
        task.packages = Utils.to_list(self.packages)
    if getattr(self, 'vapi_dirs', None):
        vapi_dirs = Utils.to_list(self.vapi_dirs)
        for vapi_dir in vapi_dirs:
            try:
                task.vapi_dirs.append(self.path.find_dir(vapi_dir).abspath())
            except AttributeError:
                Logs.warn('Unable to locate Vala API directory: %r', vapi_dir)
    if getattr(self, 'protected', None):
        task.protected = self.protected
    if getattr(self, 'private', None):
        task.private = self.private
    if getattr(self, 'inherit', None):
        task.inherit = self.inherit
    if getattr(self, 'deps', None):
        task.deps = self.deps
    if getattr(self, 'vala_defines', None):
        task.vala_defines = Utils.to_list(self.vala_defines)
    if getattr(self, 'vala_target_glib', None):
        task.vala_target_glib = self.vala_target_glib
    if getattr(self, 'enable_non_null_experimental', None):
        task.enable_non_null_experimental = self.enable_non_null_experimental
    if getattr(self, 'force', None):
        task.force = self.force
    if getattr(self, 'checks', None):
        task.valalint_checks = Utils.to_list(self.checks)


class valalint(Task.Task):
    vars  = ['VALALINT', 'VALALINTFLAGS']
    color = 'BLUE'
    def __init__(self, *k, **kw):
        Task.Task.__init__(self, *k, **kw)
        self.valalint_checks = []

    def run(self):
        cmd = [Utils.subst_vars('${VALALINT}', self.env)]
        if getattr(self, 'valalint_checks', None):
            for check in self.valalint_checks:
                cmd.append ('-c %s' % check)
        if self.env.VALALINTFLAGS:
            cmd.extend(self.env.VALALINTFLAGS)
        cmd.append (' '.join ([i.abspath() for i in self.inputs]))
        return self.generator.bld.exec_command(' '.join(cmd))

# Actions #
#=========#

def options(ctx):
    ctx.load('compiler_c vala')
    ctx.add_option('--noopt', action='store_true', default=False, dest='noopt', help="Turn off compiler optimizations")
    ctx.add_option('--flatpak', action='store_true', default=False, dest='flatpak', help="Enable Flatpak tweaks.")
    ctx.add_option('--nodebug', action='store_false', default=True, dest='debug', help="Turn off debugging symbols")
    ctx.add_option('--novaladoc', action='store_false', default=True, dest='buildvaladoc', help="Don't build Vala documentation.")
    ctx.add_option('--gir', action='store_true', default=False, dest='build_gir', help="Build GIR.")
    ctx.add_option('--no-strict', action='store_false', default=True, dest='strict', help="Disable strict checks (e.g. fatal warnings).")
    ctx.add_option(
        '--no-vala-lint', action='store_false', default=False, dest='lint_vala', help="Noop.")
    ctx.add_option(
        '--lint-vala-auto-fix', action='store_true', default=False,
        dest='lint_vala_auto_fix', help="Use Vala linter and automatically fix errors (dangerous).")

def configure(ctx):
    add_version_info(ctx)

    ctx.msg("Version", ctx.env.VERSION, "GREEN")
    if ctx.env.REVISION_ID != REVISION_SNAPSHOT:
        ctx.msg("Upstream revision", ctx.env.REVISION_ID, color="GREEN")
    else:
        ctx.msg("Upstream revision", "unknown", color="RED")
    ctx.msg('Install prefix', ctx.options.prefix, color="GREEN")

    ctx.env.append_unique("VALAFLAGS", ["-v"])
    if ctx.options.strict:
        ctx.env.append_unique("VALAFLAGS", ["--fatal-warnings"])
        ctx.env.append_unique("VALADOCFLAGS", ["--fatal-warnings"])
        ctx.env.append_unique('CFLAGS', [
            '-lm',
            '-Wall', '-Werror',
            '-Wno-unused-but-set-variable',
            '-Wno-incompatible-pointer-types',
            '-Wno-discarded-qualifiers',
            '-Wno-unused-function',
            '-Wno-unused-variable',
            '-Wno-unused-label',
            '-Wno-deprecated-declarations',
            '-Wno-address',
            ])
    ctx.env.append_unique("LINKFLAGS", ["-Wl,--no-undefined", "-Wl,--as-needed"])
    ctx.env.FLATPAK = ctx.options.flatpak
    if ctx.env.FLATPAK:
        vala_def(ctx, "FLATPAK")
    if not ctx.options.noopt:
        ctx.env.append_unique('CFLAGS', '-O2')
    if ctx.options.debug:
        ctx.env.append_unique('CFLAGS', '-g3')

    ctx.load('compiler_c vala')
    ctx.check_vala(min_version=tuple(int(i) for i in MIN_VALA.split(".")))

    ctx.env.BUILD_GIR = ctx.options.build_gir
    if ctx.env.BUILD_GIR:
        ctx.find_program('g-ir-compiler', var='GIR_COMPILER')

    ctx.env.BUILD_VALADOC = ctx.options.buildvaladoc
    if ctx.env.BUILD_VALADOC:
        ctx.load('valadoc', tooldir='.')

    ctx.env.LINT_VALA = ctx.options.lint_vala
    if ctx.env.LINT_VALA:
        ctx.find_program('valalint', var='VALALINT')

    pkgconfig(ctx, 'glib-2.0', 'GLIB', MIN_GLIB)
    pkgconfig(ctx, 'gthread-2.0', 'GTHREAD', MIN_GLIB)
    pkgconfig(ctx, 'gio-2.0', 'GIO', MIN_GLIB)
    pkgconfig(ctx, 'gio-unix-2.0', 'UNIXGIO', MIN_GLIB)
    pkgconfig(ctx, 'gtk+-3.0', 'GTK+', MIN_GTK)
    pkgconfig(ctx, 'gdk-3.0', 'GDK', MIN_GTK)
    pkgconfig(ctx, 'gdk-x11-3.0', 'GDKX11', MIN_GTK)
    pkgconfig(ctx, 'gee-0.8', 'GEE', MIN_GEE)
    pkgconfig(ctx, 'x11', 'X11', "0")
    pkgconfig(ctx, 'sqlite3', 'SQLITE', "3.7")

    ctx.define("DRT_VERSION", ctx.env.VERSION)
    ctx.define("DRT_REVISION", ctx.env.REVISION_ID)
    ctx.define("DRT_VERSION_MAJOR", ctx.env.VERSIONS[0])
    ctx.define("DRT_VERSION_MINOR", ctx.env.VERSIONS[1])
    ctx.define("DRT_VERSION_BUGFIX", ctx.env.VERSIONS[2])
    ctx.define("DRT_VERSION_SUFFIX", ctx.env.REVISION_ID)

    ctx.define('GLIB_VERSION_MAX_ALLOWED', glib_encode_version(MIN_GLIB))
    ctx.define('GLIB_VERSION_MIN_REQUIRED', glib_encode_version(MIN_GLIB))
    ctx.define('GDK_VERSION_MAX_ALLOWED', glib_encode_version(MIN_GTK))
    ctx.define('GDK_VERSION_MIN_REQUIRED', glib_encode_version(MIN_GTK))

def build(ctx):
    def valalint(source_dir=None, **kwargs):
        if not ctx.env.LINT_VALA:
            return
        if source_dir is not None:
            kwargs["source"] = ctx.path.ant_glob(source_dir + '/**/*.vala')
        return ctx(features="valalint", **kwargs)

    if ctx.options.lint_vala_auto_fix:
        ctx.env.append_unique('VALALINTFLAGS', '--fix')

    #~ print ctx.env
    PC_CFLAGS = ""
    DIORITE_GLIB = "{}glib{}".format(APPNAME, ctx.env.SERIES)
    DIORITE_GTK = "{}gtk{}".format(APPNAME, ctx.env.SERIES)
    DIORITE_DB = "{}db{}".format(APPNAME, ctx.env.SERIES)
    DIORITE_TESTS = "{}tests".format(APPNAME)
    RUN_DIORITE_TESTS = "run-{}".format(DIORITE_TESTS)
    packages = 'posix glib-2.0 gio-2.0 gio-unix-2.0 gee-0.8'
    packages_gtk = packages + " gtk+-3.0 x11 gdk-3.0 gdk-x11-3.0"
    uselib = 'GLIB GIO UNIXGIO GEE'
    uselib_gtk = uselib + " GTK+ GDK X11 GDKX11"
    vala_defines = ctx.env.VALA_DEFINES

    vapi_dirs = ['build', 'vapi']
    env_vapi_dir = os.environ.get("VAPIDIR")
    if env_vapi_dir:
        vapi_dirs.extend(os.path.relpath(path) for path in env_vapi_dir.split(":"))

    valalint(source_dir = 'src/glib')
    valalint(source_dir = 'src/gtk')
    valalint(source_dir = 'src/db')
    valalint(source_dir = 'src/tests')
    ctx.add_group()

    ctx(features = "c cshlib",
        target = DIORITE_GLIB,
        name = DIORITE_GLIB,
        gir = "Drt-1.0" if ctx.env.BUILD_GIR else None,
        source = ctx.path.ant_glob('src/glib/*.vala') + ctx.path.ant_glob('src/glib/*.vapi'),
        packages = packages,
        uselib = uselib,
        vala_defines = vala_defines,
        cflags = ['-DG_LOG_DOMAIN="DioriteGlib"'],
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
    )
    if ctx.env.BUILD_GIR:
        ctx.gir_compile("Drt-1.0", DIORITE_GLIB)
    ctx.valadoc(
        package_name = DIORITE_GLIB,
        package_version = ctx.env.VERSION,
        files = ctx.path.ant_glob('src/glib/*.vala') + ctx.path.ant_glob('src/glib/*.vapi'),
        packages = packages,
        vala_defines = vala_defines,
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
        force = True,
        verbose=True
    )

    ctx(features = "c cshlib",
        target = DIORITE_GTK,
        name = DIORITE_GTK,
        gir = "Drtgtk-1.0" if ctx.env.BUILD_GIR else None,
        source = ctx.path.ant_glob('src/gtk/*.vala'),
        packages = packages_gtk,
        uselib = uselib_gtk,
        use = [DIORITE_GLIB],
        vala_defines = vala_defines,
        cflags = ['-DG_LOG_DOMAIN="DioriteGtk"'],
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
        internal=True,
        private=True,
    )
    if ctx.env.BUILD_GIR:
        ctx.gir_compile("Drtgtk-1.0", DIORITE_GTK)
    ctx.valadoc(
        package_name = DIORITE_GTK,
        package_version = ctx.env.VERSION,
        files = ctx.path.ant_glob('src/gtk/*.vala') + ctx.path.ant_glob('src/gtk/*.vapi'),
        use = [DIORITE_GLIB],
        packages = packages_gtk,
        vala_defines = vala_defines,
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
        internal=True,
        private=True,
        force = True,
        verbose=True
    )

    ctx(features = "c cshlib",
        target = DIORITE_DB,
        name = DIORITE_DB,
        gir = "Drtdb-1.0" if ctx.env.BUILD_GIR else None,
        source = ctx.path.ant_glob('src/db/*.vala'),
        packages = packages + " sqlite3",
        uselib = uselib + " SQLITE",
        use = [DIORITE_GLIB],
        vala_defines = vala_defines,
        cflags = ['-DG_LOG_DOMAIN="DioriteDB"'],
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
    )
    if ctx.env.BUILD_GIR:
        ctx.gir_compile("Drtdb-1.0", DIORITE_DB)
    ctx.valadoc(
        package_name = DIORITE_DB,
        package_version = ctx.env.VERSION,
        files = ctx.path.ant_glob('src/db/*.vala') + ctx.path.ant_glob('src/db/*.vapi'),
        use = [DIORITE_GLIB],
        packages = packages + " sqlite3",
        vala_defines = vala_defines,
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
        internal=True,
        private=True,
        force = True,
        verbose=True
    )

    ctx(features = "c cshlib",
        target = DIORITE_TESTS,
        name = DIORITE_TESTS,
        source = ctx.path.ant_glob('src/tests/*.vala'),
        packages = packages_gtk,
        uselib = uselib_gtk,
        use = [DIORITE_GLIB, DIORITE_GTK, DIORITE_DB],
        vala_defines = vala_defines,
        defines = ['G_LOG_DOMAIN="DioriteTests"'],
        lib = ['m'],
        vapi_dirs = vapi_dirs,
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
        vapi_dirs = vapi_dirs,
        vala_target_glib = TARGET_GLIB,
        install_path = None
    )

    # https://www.bassi.io/articles/2018/03/15/pkg-config-and-paths/
    PREFIX = ctx.env.PREFIX
    PC_PATHS = {}
    for name in "LIBDIR", "INCLUDEDIR", "DATADIR":
        path = getattr(ctx.env, name)
        PC_PATHS[name] = "${prefix}" + path[len(PREFIX):] if path.startswith(PREFIX + "/") else path

    ctx(features = 'subst',
        source='src/dioriteglib.pc.in',
        target='{}glib{}.pc'.format(APPNAME, ctx.env.SERIES),
        install_path='${LIBDIR}/pkgconfig',
        VERSION=ctx.env.VERSION,
        PREFIX=PREFIX,
        APPNAME=APPNAME,
        PC_CFLAGS=PC_CFLAGS,
        LIBNAME=DIORITE_GLIB,
        **PC_PATHS,
    )

    ctx(features = 'subst',
        source='src/dioritegtk.pc.in',
        target='{}gtk{}.pc'.format(APPNAME, ctx.env.SERIES),
        install_path='${LIBDIR}/pkgconfig',
        VERSION=ctx.env.VERSION,
        PREFIX=PREFIX,
        APPNAME=APPNAME,
        PC_CFLAGS=PC_CFLAGS,
        LIBNAME=DIORITE_GTK,
        DIORITE_GLIB=DIORITE_GLIB,
        **PC_PATHS,
    )

    ctx(features = 'subst',
        source='src/dioritedb.pc.in',
        target='{}db{}.pc'.format(APPNAME, ctx.env.SERIES),
        install_path='${LIBDIR}/pkgconfig',
        VERSION=ctx.env.VERSION,
        PREFIX=PREFIX,
        APPNAME=APPNAME,
        PC_CFLAGS=PC_CFLAGS,
        LIBNAME=DIORITE_DB,
        DIORITE_GLIB=DIORITE_GLIB,
        **PC_PATHS,
    )

    ctx.install_as('${BINDIR}/diorite-testgen' + ctx.env.SERIES, 'testgen.py', chmod=Utils.O755)
