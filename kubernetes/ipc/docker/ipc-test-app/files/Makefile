CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -D_XOPEN_SOURCE=500

TARGETS = shm-sysv shm-posix uds-share-file uds-share-shm

all: $(TARGETS)

$(TARGETS): %: src/%.c
	$(CC) $(CFLAGS) -o $@ $^

install: $(TARGETS)
	install -D -m 755 $(TARGETS) $(DESTDIR)/usr/bin/

clean:
	rm -f $(TARGETS)

.PHONY: all clean install
