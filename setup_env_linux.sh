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

alias configure="./waf configure --with-experimental-api"
alias rebuild="./waf distclean configure build --with-experimental-api"
alias fedora_configure="./waf configure --libdir /usr/local/lib64"
alias fedora_rebuild="./waf distclean configure build --libdir /usr/local/lib64"
alias update="./waf && sudo ./waf install"
