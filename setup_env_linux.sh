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

alias configure="python3 ./waf configure --with-experimental-api"
alias rebuild="python3 ./waf distclean configure build --with-experimental-api"
alias fedora_configure="python3 ./waf configure --libdir /usr/local/lib64"
alias fedora_rebuild="python3 ./waf distclean configure build --libdir /usr/local/lib64"
alias update="python3 ./waf && sudo python3 ./waf install"
