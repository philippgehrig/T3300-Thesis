# Makefile for CAN simulation project

CC = gcc
CFLAGS = -Wall -O2
TARGET = can

# Check for the existence of the Linux CAN header file.
check:
	@if [ ! -f /usr/include/linux/can.h ]; then \
		echo "Error: Linux CAN headers not found."; \
		echo "Please ensure you have the kernel headers installed (e.g., linux-headers-$(shell uname -r))."; \
		exit 1; \
	fi

all: check $(TARGET)

$(TARGET): can.c
	$(CC) $(CFLAGS) -o $(TARGET) can.c

clean:
	rm -f $(TARGET)
