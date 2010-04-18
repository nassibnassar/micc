SHELL =		/bin/sh

all:
	cd src ; ${MAKE} all

install:
	cd src ; ${MAKE} ${MAKEFLAGS} install

uninstall:
	cd src ; ${MAKE} ${MAKEFLAGS} uninstall

clean:
	cd src ; ${MAKE} clean

distclean:
	cd src ; ${MAKE} distclean
	rm -f *~ *#
