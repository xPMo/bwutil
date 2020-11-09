PREFIX ?= /usr/local
BINDIR ?= ${PREFIX}/bin

install:
	install -Dm755 bin/bwutil ${BINDIR}

symlink:
	ln -s ${PWD}/bin/bwutil ${BINDIR}
