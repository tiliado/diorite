#!/usr/bin/make -f

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

OUT=./_build
BASE=.
BINARY=logger
MINGW_BIN=/usr/i686-w64-mingw32/sys-root/mingw/bin
MINGW_LIB=/usr/i686-w64-mingw32/sys-root/mingw/lib

default:
	@echo "targets: build|run-linux|dist-win|clean"

run-linux: build
	${OUT}/${BINARY}

build:
	@mkdir -p ${OUT}
	valac -d ${OUT} -b ${BASE} --thread --save-temps -v \
	--pkg=dioriteglib \
	-X '-DG_LOG_DOMAIN="Diorite"' \
	logger.vala

dist-win: build
	cp ${MINGW_BIN}/libglib-2.0-0.dll ${OUT}/libglib-2.0-0.dll
	cp ${MINGW_BIN}/libgobject-2.0-0.dll ${OUT}/libgobject-2.0-0.dll
	cp ${MINGW_BIN}/libgthread-2.0-0.dll ${OUT}/libgthread-2.0-0.dll
	cp ${MINGW_BIN}/libgcc_s_sjlj-1.dll ${OUT}/libgcc_s_sjlj-1.dll
	cp ${MINGW_BIN}/libintl-8.dll ${OUT}/libintl-8.dll
	cp ${MINGW_BIN}/libffi-6.dll ${OUT}/libffi-6.dll
	cp ${MINGW_BIN}/iconv.dll ${OUT}/iconv.dll
	
	cp ${MINGW_LIB}/dioriteglib-0.dll ${OUT}/dioriteglib-0.dll

clean:
	rm -rf ${OUT}
