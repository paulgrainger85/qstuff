CC=gcc
CFLAGS=-m32 -shared -fPIC
HOME=/home/paul
CINCL= -I$(HOME)/include
CDIR=$(HOME)/git/pgriggy/c
LIB=$(HOME)/bin

cadd:
	$(CC) $(CFLAGS) $(CDIR)/add.c -o $(LIB)/add.o $(CINCL)
	ln -s $(LIB)/add.o $(QHOME)/l32/add.so
