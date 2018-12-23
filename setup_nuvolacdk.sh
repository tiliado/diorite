LD_LIBRARY_PATH=$PWD/build
PATH="$PWD/build:$PATH"
if [ -z "$PKG_CONFIG_PATH" ]; then
    PKG_CONFIG_PATH="$PWD/build:/app/lib/pkgconfig:/usr/lib/pkgconfig"
else
    PKG_CONFIG_PATH="$PWD/build:/app/lib/pkgconfig:$PKG_CONFIG_PATH"
fi
CFLAGS="$CFLAGS -I$PWD/build -L$PWD/build"
CC="gcc"
export CC CFLAGS PKG_CONFIG_PATH PATH LD_LIBRARY_PATH
export GI_TYPELIB_PATH="$PWD/build:$GI_TYPELIB_PATH"

# Memory corruption checks
export MALLOC_CHECK_=3
export MALLOC_PERTURB_=$(($RANDOM % 255 + 1))

alias configure="python3 ./waf configure --flatpak"
alias waf="python3 ./waf -v "
alias update="python3 ./waf && sudo python3 ./waf install"

rebuild()
{
    python3 ./waf distclean configure build --flatpak "$@" \
    && build/run-dioritetests
}

valgrind-tests() {
    python3 ./waf \
    && G_DEBUG=gc-friendly G_SLICE=always-malloc valgrind \
        --leak-check=full --leak-resolution=high --num-callers=20 \
        --show-leak-kinds=definite,indirect,possible \
        --suppressions=/usr/share/glib-2.0/valgrind/glib.supp \
        --suppressions=src/diorite.supp \
        --log-file=valgrind-tests.log ./build/run-dioritetests "$@" \
    && less valgrind-tests.log
}
