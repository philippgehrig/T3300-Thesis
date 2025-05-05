#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pcie_common.h"
#include "pcie_client.h"

// Global configuration for the PCIe client
static pcie_config_t g_config = {NULL, NULL, NULL};

// Track initialization state
static int g_initialized = 0;

// Internal helper function to load environment variables
static int load_env_variables() {
    const char *device_id = getenv("PCIE_DEVICE_ID");
    const char *vendor_id = getenv("PCIE_VENDOR_ID");
    const char *subsystem_id = getenv("PCIE_SUBSYSTEM_ID");

    if (!device_id || !vendor_id || !subsystem_id) {
        pcie_log("Client", "Error: Missing required environment variables.");
        return -1;
    }

    // Store configuration in global struct
    g_config.device_id = device_id;
    g_config.vendor_id = vendor_id;
    g_config.subsystem_id = subsystem_id;

    pcie_log("Client", "Environment variables loaded successfully.");
    return 0;
}

// Initialize the PCIe client
int pcie_client_init() {
    if (load_env_variables() != 0) {
        return -1;
    }

    pcie_log("Client", "Initializing PCIe client with the following configuration:");
    printf("Device ID: %s\n", g_config.device_id);
    printf("Vendor ID: %s\n", g_config.vendor_id);
    printf("Subsystem ID: %s\n", g_config.subsystem_id);

    // Set initialization flag
    g_initialized = 1;
    
    // Placeholder for actual initialization logic

    return 0;
}

// Get PCIe client configuration
const pcie_config_t* pcie_client_get_config() {
    if (!g_initialized) {
        return NULL;
    }
    return &g_config;
}

// Check if PCIe client is initialized
int pcie_client_is_initialized() {
    return g_initialized;
}

// Cleanup the PCIe client
void pcie_client_cleanup() {
    pcie_log("Client", "Cleaning up PCIe client.");
    
    // Clean up sender resources
    pcie_sender_cleanup();
    
    // Clean up receiver resources
    pcie_receiver_cleanup();
    
    // Reset initialization flag
    g_initialized = 0;
}