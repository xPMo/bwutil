PREFIX ?= /usr/local
BINDIR ?= ${PREFIX}/bin

install:
	mkdir ${BINDIR}
	install -Dm755 bin/bwutil ${BINDIR}

symlink:
	ln -s ${PWD}/bin/bwutil ${BINDIR}
