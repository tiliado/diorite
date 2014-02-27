#!/bin/bash

# Author: Jiří Janoušek <janousek.jiri@gmail.com>
#
# To the extent possible under law, author has waived all
# copyright and related or neighboring rights to this file.
# http://creativecommons.org/publicdomain/zero/1.0/
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 build|dist|run|debug lin|mingw"
	exit 1
fi

set -eu
NAME="logger"
CMD="$1"
PLATFORM="$2"
. conf.inc.sh 

build()
{
	dist
	echo "*** $0 build ***"
	mkdir -p ${OUT}
	
	set -x
	
	valac -C -d ${OUT} -b . --thread --save-temps -v \
	--vapidir $BUILD  --vapidir ../vapi \
	--pkg glib-2.0 --target-glib=2.32 --pkg=dioriteglib \
	${NAME}.vala
	
	$CC ${OUT}/${NAME}.c -o ${OUT}/${NAME}${EXECSUFFIX} \
	$CFLAGS '-DG_LOG_DOMAIN="MyDiorite"' \
	-I$BUILD -L$BUILD  "-L$(readlink -e "$BUILD")" -ldioriteglib \
	$(pkg-config --cflags --libs glib-2.0 gobject-2.0 gthread-2.0)
	
	
}

run()
{
	build
	dist
	echo "*** $0 run ***"
	set -x
	LD_LIBRARY_PATH=../build ${LAUNCHER} ${OUT}/${NAME}${EXECSUFFIX}
}

debug()
{
	build
	dist
	echo "*** $0 debug ***"
	set -x
	LD_LIBRARY_PATH=../build ${DEBUGGER} ${OUT}/${NAME}${EXECSUFFIX}
}

$CMD
