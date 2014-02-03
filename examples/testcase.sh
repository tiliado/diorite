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

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 build|dist|run lin|mingw"
	exit 1
fi

set -eu
NAME="testcase"
CMD="$1"
PLATFORM="$2"
. conf.inc.sh 

build()
{
	dist
	echo "*** $0 build ***"
	mkdir -p ${OUT}/testgen
	$TESTGEN -d ${OUT}/testgen --vapidir $BUILD --vapidir ../vapi testcase.vala
	
	valac -d ${OUT} -b . --thread --save-temps -v \
	--library=${NAME} -o ${LIBPREFIX}${NAME}${LIBSUFFIX} \
	--vapidir $BUILD -X -I$BUILD -X -L$BUILD \
	--vapidir ../vapi --pkg glib-2.0 --target-glib=2.32 \
	--pkg=dioriteglib --pkg=posix --pkg gmodule-2.0 \
	-X -fPIC -X -shared \
	-X '-DG_LOG_DOMAIN="Diorite"' \
	${OUT}/testgen/testcase.vala
}

dist()
{
	echo "*** $0 dist ***"
	mkdir -p ${OUT}
	if [ "$PLATFORM" == "WIN" ]; then
		for file in  \
		libglib-2.0-0.dll libgobject-2.0-0.dll libgthread-2.0-0.dll \
		libgcc_s_sjlj-1.dll libintl-8.dll libffi-6.dll iconv.dll \
		libgio-2.0-0.dll libgmodule-2.0-0.dll zlib1.dll libvala-0.16-0.dll \
		gspawn-win32-helper.exe gspawn-win32-helper-console.exe
		do
			cp -spuvf ${MINGW_BIN}/$file ${OUT}
		done
		
		for file in \
		dioriteglib-0.dll dioriteinterrupthelper.exe dioritetestgen.exe dioritetester.exe
		do
			cp -lpuvf ${BUILD}/$file ${OUT}
		done
	fi
}

run()
{
	build
	dist
	echo "*** $0 run ***"
	$TESTER build/testcase build/testgen/tests.spec
}

$CMD
