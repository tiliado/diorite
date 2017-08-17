LD_LIBRARY_PATH=$PWD/build
PATH="$PWD/build:$PATH"
if [ -z "$PKG_CONFIG_PATH" ]; then
	PKG_CONFIG_PATH="$PWD/build:/usr/lib/pkgconfig"
else
	PKG_CONFIG_PATH="$PWD/build:$PKG_CONFIG_PATH"
fi
CFLAGS="$CFLAGS -I$PWD/build -L$PWD/build"
CC="gcc"
export CC CFLAGS PKG_CONFIG_PATH PATH LD_LIBRARY_PATH
export GI_TYPELIB_PATH="$PWD/build:$GI_TYPELIB_PATH"

alias configure="python3 ./waf configure --flatpak"
alias waf="python3 ./waf -v "
alias update="python3 ./waf && sudo python3 ./waf install"

rebuild()
{
	python3 ./waf distclean configure build --flatpak "$@" \
	&& build/run-dioritetests
}
