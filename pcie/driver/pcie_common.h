#ifndef PCIE_COMMON_H
#define PCIE_COMMON_H

#include <stdio.h>

#define BUFFER_SIZE 256

// Common logging function for all PCIe components
static inline void pcie_log(const char *component, const char *message) {
    if (message) {
        printf("[PCIe %s] %s\n", component, message);
    }
}

#endif // PCIE_COMMON_H