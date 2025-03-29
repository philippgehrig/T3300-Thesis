CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./src -I./tests

TRANSLATION_SRC = src/translation.c
TRANSLATION_OBJ = $(TRANSLATION_SRC:.c=.o)

all: test_bidirectional

test_bidirectional: $(TRANSLATION_OBJ) tests/test_bidirectional.c
	$(CC) $(CFLAGS) -o test_bidirectional $(TRANSLATION_OBJ) tests/test_bidirectional.c

clean:
	rm -f $(TRANSLATION_OBJ) test_bidirectional
