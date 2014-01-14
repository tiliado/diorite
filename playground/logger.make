#!/usr/bin/make -f

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
	-X '-DG_LOG_DOMAIN="LoGGer"' \
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
	@echo "Run wine ${OUT}/${BINARY}.exe"

clean:
	rm -rf ${OUT}
