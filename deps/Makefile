OS := $(shell uname)

ifeq ($(OS),Darwin)
CFLAGS += -Wl,-flat_namespace -Wl,-undefined,suppress
endif

all: libexjl.so

libexjl.so: libexjl.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(CWARN) -shared -fPIC -o $@ $<
