#!/bin/bash

# Author: Jiří Janoušek <janousek.jiri@gmail.com>
#
# To the extent possible under law, author has waived all
# copyright and related or neighboring rights to this file.
# http://creativecommons.org/publicdomain/zero/1.0/
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

OUT=./build
BUILD=../build
# On Fedora 20
MINGW_BIN=/usr/i686-w64-mingw32/sys-root/mingw/bin
MINGW_LIB=/usr/i686-w64-mingw32/sys-root/mingw/lib

case $PLATFORM in
mingw*)
	PLATFORM="WIN"
	LIBPREFIX="lib"
	LIBSUFFIX=".dll"
	TESTER="wine ${OUT}/dioritetester.exe"
	TESTGEN="wine ${OUT}/dioritetestgen.exe"
;;
lin*)
	PLATFORM="LINUX"
	LIBPREFIX="lib"
	LIBSUFFIX=".so"
	TESTER="dioritetester"
	TESTGEN="dioritetestgen"
;;
*)
	echo "Unsupported platform: $PLATFORM"
	exit 1
esac

clean()
{
	echo "*** $0 clean ***"
	rm -rf $OUT
}
