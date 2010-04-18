PREFIX =	/usr/local
PREFIXBIN =	${PREFIX}/bin
PREFIXINC =	${PREFIX}/include
PREFIXLIB =	${PREFIX}/lib

DEBUG =		-g
#OPT =		-O3 -funroll-loops
CSTANDARD =	-std=c89 -pedantic
WARNINGS =	-Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-label -Wno-parentheses
CFLAGS =	${CSTANDARD} ${DEBUG} ${OPT} ${WARNINGS}

OBJ =		y.tab.o lex.yy.o main.o opt.o err.o help.o process.o syntree.o symtable.o
BIN =		micc

CC =		gcc
SHELL =		/bin/sh

MICCINC =	p16f877a.h stdio.h
MICCLIB =	p16f877a.s

all: ${BIN}

micc: ${OBJ}
	gcc -o ${BIN} ${OBJ} -ll

y.tab.c y.tab.h lex.yy.c: c.y c.l
	yacc -d c.y
	lex c.l

syntree.c: y.tab.h

%.d: %.c
	@set -e; rm -f $@; \
		${CC} -MM ${CFLAGS} $< > $@.$$$$; \
		sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
		rm -f $@.$$$$

-include $(OBJ:.o=.d)

strip:
	strip ${BIN}

install: all
	mkdir -p ${PREFIXBIN}
	cp -f ${BIN} ${PREFIXBIN}/
	mkdir -p ${PREFIXINC}/micc
	cd ../include ; cp -f ${MICCINC} ${PREFIXINC}/micc/
	mkdir -p ${PREFIXLIB}/micc
	cd ../lib ; cp -f ${MICCLIB} ${PREFIXLIB}/micc/

uninstall:
	if [ -d ${PREFIXBIN} ] ; then \
		cd ${PREFIXBIN} ; \
		rm -f ${BIN} ; \
	fi
	if [ -d ${PREFIXINC}/micc ] ; then \
		cd ${PREFIXINC}/micc ; \
		rm -f ${MICCINC} ; \
		cd ${PREFIXINC} ; \
		rmdir --ignore-fail-on-non-empty micc ; \
	fi
	if [ -d ${PREFIXLIB}/micc ] ; then \
		cd ${PREFIXLIB}/micc ; \
		rm -f ${MICCLIB} ; \
		cd ${PREFIXLIB} ; \
		rmdir --ignore-fail-on-non-empty micc ; \
	fi

clean:
	rm -f ${BIN} ${OBJ} lex.yy.c y.tab.c y.tab.h
	rm -f *.d

distclean:
	make clean
	rm -f *.d.*
	rm -f *~ *#
