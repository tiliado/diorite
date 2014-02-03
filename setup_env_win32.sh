export WIN32=/usr/i686-w64-mingw32/sys-root/mingw
export PKG_CONFIG_PATH=$WIN32/lib/pkgconfig
export CC=i686-w64-mingw32-gcc
export DISPLAY=:0
alias configure="./waf configure --platform=win --prefix=$WIN32"
