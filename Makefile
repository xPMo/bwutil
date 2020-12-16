PREFIX ?= /usr/local
BINDIR ?= ${PREFIX}/bin

install:
	install -Dm755 bin/bwutil ${BINDIR}/bwutil

symlink:
	ln -s ${PWD}/bin/bwutil ${BINDIR}
