#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <stdint.h>
#include "pcie_common.h"
#include "pcie_client.h"

// PCIe device handle
static int pcie_fd = -1;
static void *pcie_map = NULL;
static size_t map_size = 0x1000;  // 4KB memory-mapped region

#define BUFFER_SIZE 256

// Send a message via PCIe
int pcie_client_send(const char *message) {
    // Check if client is initialized first
    if (!pcie_client_is_initialized()) {
        pcie_log("Sender", "Error: PCIe client not initialized.");
        return -1;
    }
    
    if (message == NULL) {
        pcie_log("Sender", "Error: NULL message cannot be sent.");
        return -1;
    }
    
    // Access the configuration
    const pcie_config_t *config = pcie_client_get_config();
    if (!config) {
        pcie_log("Sender", "Error: Failed to get PCIe configuration.");
        return -1;
    }
    
    // Open PCIe device if not already open
    if (pcie_fd < 0) {
        char device_path[128];
        snprintf(device_path, sizeof(device_path), "/sys/bus/pci/devices/%s/resource0", config->device_id);
        
        pcie_fd = open(device_path, O_RDWR | O_SYNC);
        if (pcie_fd < 0) {
            pcie_log("Sender", "Error: Failed to open PCIe device.");
            fprintf(stderr, "Open failed: %s\n", strerror(errno));
            return -1;
        }
        
        // Memory map the PCIe BAR region
        pcie_map = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, pcie_fd, 0);
        if (pcie_map == MAP_FAILED) {
            pcie_log("Sender", "Error: Failed to memory map PCIe region.");
            fprintf(stderr, "mmap failed: %s\n", strerror(errno));
            close(pcie_fd);
            pcie_fd = -1;
            return -1;
        }
        
        pcie_log("Sender", "PCIe device opened and mapped successfully.");
    }
    
    // Get message length (including null terminator)
    size_t msg_len = strlen(message) + 1;
    if (msg_len > map_size) {
        pcie_log("Sender", "Error: Message too large for PCIe transfer.");
        return -1;
    }
    
    // Write message length to the first 4 bytes (simple header)
    uint32_t *header = (uint32_t *)pcie_map;
    *header = (uint32_t)msg_len;
    
    // Copy message to the mapped memory
    char *data_region = (char *)pcie_map + sizeof(uint32_t);
    memcpy(data_region, message, msg_len);
    
    // Ensure the write is flushed to the device
    msync(pcie_map, sizeof(uint32_t) + msg_len, MS_SYNC);
    
    pcie_log("Sender", "Message sent successfully via PCIe.");
    printf("Message sent via device %s: %s\n", config->device_id, message);
    return 0;
}

// Close PCIe sender resources
void pcie_sender_cleanup() {
    if (pcie_map != NULL && pcie_map != MAP_FAILED) {
        munmap(pcie_map, map_size);
        pcie_map = NULL;
    }
    
    if (pcie_fd >= 0) {
        close(pcie_fd);
        pcie_fd = -1;
    }
    
    pcie_log("Sender", "PCIe sender resources cleaned up.");
}