CC = g++
CFLAGS = -Wall -Wextra -std=c++17 -I./pcie/driver -I./translation -I./tests
CFLAGS_C = -Wall -Wextra -I./pcie/driver -I./translation

# For C files
CC_C = gcc
STD_C = -std=c11

# OS detection
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
    # macOS specific paths for Google Test (Homebrew installation)
    GTEST_INCLUDE = -I/opt/homebrew/include
    GTEST_LIB_PATH = -L/opt/homebrew/lib
    CFLAGS += $(GTEST_INCLUDE)
    GTEST_LIBS = $(GTEST_LIB_PATH) -lgtest -lgtest_main -pthread
    LIBS = -pthread
else
    # Linux specific paths
    GTEST_LIBS = -lgtest -lgtest_main -pthread
    LIBS = -lrt -pthread
endif

DRIVER_SRCS = pcie/driver/pcie_client.c pcie/driver/pcie_sender.c pcie/driver/pcie_receiver.c pcie/driver/pcie_common.h
TRANSLATION_SRCS = translation/pcie_translation.c translation/pcie_translation.h

all: test_pcie_client test_translation test_zonal zonal_example

# Compile the PCIe client test
test_pcie_client: tests/test_pcie_client.cpp $(DRIVER_SRCS)
	$(CC) $(CFLAGS) -o test_pcie_client tests/test_pcie_client.cpp pcie/driver/pcie_client.c pcie/driver/pcie_sender.c pcie/driver/pcie_receiver.c $(GTEST_LIBS)

# Compile the translation test
test_translation: tests/test_translation.cpp $(DRIVER_SRCS) $(TRANSLATION_SRCS)
	$(CC) $(CFLAGS) -o test_translation tests/test_translation.cpp pcie/driver/pcie_client.c pcie/driver/pcie_sender.c pcie/driver/pcie_receiver.c translation/pcie_translation.c $(GTEST_LIBS)

# Compile the zonal example test
test_zonal: tests/test_zonal_example.cpp $(DRIVER_SRCS) $(TRANSLATION_SRCS)
	$(CC) $(CFLAGS) -o test_zonal tests/test_zonal_example.cpp pcie/driver/pcie_client.c pcie/driver/pcie_sender.c pcie/driver/pcie_receiver.c translation/pcie_translation.c $(GTEST_LIBS)

# Compile the zonal architecture example
zonal_example: pcie/examples/zonal_example.c $(DRIVER_SRCS) $(TRANSLATION_SRCS)
	$(CC_C) $(STD_C) $(CFLAGS_C) -o zonal_example pcie/examples/zonal_example.c pcie/driver/pcie_client.c pcie/driver/pcie_sender.c pcie/driver/pcie_receiver.c translation/pcie_translation.c $(LIBS)

clean:
	rm -f test_pcie_client test_translation test_zonal zonal_example