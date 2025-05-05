#ifndef PCIE_CLIENT_H
#define PCIE_CLIENT_H

#include <stddef.h>

// Client initialization and cleanup
int pcie_client_init();
void pcie_client_cleanup();

// Check if PCIe client is initialized
int pcie_client_is_initialized();

// Communication functions
int pcie_client_send(const char *message);
int pcie_client_receive(char *buffer, size_t buffer_size);

// Internal cleanup functions
void pcie_sender_cleanup();
void pcie_receiver_cleanup();

// Configuration
typedef struct {
    const char* device_id;
    const char* vendor_id;
    const char* subsystem_id;
} pcie_config_t;

// Get current PCIe configuration
const pcie_config_t* pcie_client_get_config();

#endif // PCIE_CLIENT_H