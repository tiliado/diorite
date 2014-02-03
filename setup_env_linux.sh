LD_LIBRARY_PATH=$PWD/build
PATH="$PWD/build:$PATH"
alias configure="./waf configure"
if [ -z "$PKG_CONFIG_PATH" ]; then
	PKG_CONFIG_PATH="$PWD/build:/usr/lib/pkgconfig"
else
	PKG_CONFIG_PATH="$PWD/build:$PKG_CONFIG_PATH"
fi
CFLAGS="$CFLAGS -I$PWD/build -L$PWD/build"

export CFLAGS PKG_CONFIG_PATH PATH LD_LIBRARY_PATH
