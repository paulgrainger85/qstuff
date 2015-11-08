OS=$(shell uname)
CC=gcc
CFLAGS=-m32 -shared -fPIC
CINCL= -I$(HOME)/include
CDIR=$(HOME)/git/pgriggy/c
LIB=$(HOME)/bin
KDB_ARCH=l32

ifeq ($(OS),Darwin)
	CC=/usr/bin/gcc
	CFLAGS=-m32 -bundle -undefined dynamic_lookup
	KDB_ARCH=m32
endif

cadd:
	$(CC) $(CFLAGS) $(CDIR)/add.c -o $(LIB)/add.so $(CINCL)
	ln -sf $(LIB)/add.so $(QHOME)/$(KDB_ARCH)/add.so
