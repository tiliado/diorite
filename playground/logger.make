#!/usr/bin/make -f

OUT=./_build
BASE=.
BINARY=logger

run: build
	${OUT}/${BINARY}

build:
	@mkdir -p ${OUT}
	valac -d ${OUT} -b ${BASE} --thread --save-temps -v \
	--pkg=dioriteglib \
	-X '-DG_LOG_DOMAIN="LoGGer"' \
	-o ${BINARY} \
	logger.vala

clean:
	rm -rf ${OUT}
