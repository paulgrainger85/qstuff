OS=$(shell uname)
CC=gcc
CFLAGS=-m32 -shared -fPIC -Wall
CINCL= -I$(HOME)/include
CDIR=$(HOME)/git/pgriggy/c
LIB=$(HOME)/bin
KDB_ARCH=l32

ifeq ($(OS),Darwin)
	CC=/usr/bin/gcc
	CFLAGS=-m32 -bundle -undefined dynamic_lookup -Wall
	KDB_ARCH=m32
endif

kdb:	cadd updateqq

cadd:
	$(CC) $(CFLAGS) $(CDIR)/add.c -o $(LIB)/add.so $(CINCL)
	@echo "\n\033[1;32m--- Linking following libraries ---\033[1;34m"
	ln -sf $(LIB)/add.so $(QHOME)/$(KDB_ARCH)/add.so

updateqq:
	@echo ".c.add:\`add 2:(\`add;2)" >> $(QHOME)/c.q
	@echo ".c.test:\`add 2:(\`test;1)" >> $(QHOME)/c.q
	@echo "\n\033[1;32m--- Installing the following functions to kdb ---\033[1;33m"
	@cat $(QHOME)/c.q|sort|uniq|tee $(QHOME)/c.q

