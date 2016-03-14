.PHONY: all clean dispatcher install

CC=gcc
CFLAGS +=-Wall -g
LIB_DIR=lib/libscion
LIBFILE=$(LIB_DIR)/libscion.a
LIB_H_SRC=$(LIB_DIR)/*.c $(LIB_DIR)/*.h
DISPATCHER_DIR=endhost
DISPATCHER=$(DISPATCHER_DIR)/dispatcher
SOCKET_DIR=endhost/ssp
SOCKET=$(SOCKET_DIR)/libsocket.so

all:
	$(MAKE) -C $(LIB_DIR)
	$(MAKE) -C $(DISPATCHER_DIR)
	$(MAKE) -C $(SOCKET_DIR)

dispatcher:
	$(MAKE) -C $(DISPATCHER_DIR)

install:
	cp $(DISPATCHER) bin/

clean:
	$(MAKE) clean -C $(LIB_DIR)
	$(MAKE) clean -C $(DISPATCHER_DIR)
	$(MAKE) clean -C $(SOCKET_DIR)
	rm -f bin/dispatcher
