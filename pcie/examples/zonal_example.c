#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include "../driver/pcie_common.h"
#include "../driver/pcie_client.h"
#include "../../translation/pcie_translation.h"

// Flag for controlling the main loop
static volatile int running = 1;

// Signal handler for graceful termination
static void signal_handler(int sig) {
    (void)sig; // Suppress unused parameter warning
    running = 0;
}

// Simulated function to read a CAN message from a CAN bus
void simulate_can_message_receive(can_message_t *can_msg) {
    static uint8_t counter = 0;
    
    // Fill in simulated CAN message
    can_msg->can_id = 0x123;  // Example CAN ID
    can_msg->can_dlc = 8;     // Data length code (max 8 bytes)
    
    // Fill data with some simulated values
    for (int i = 0; i < can_msg->can_dlc; i++) {
        can_msg->data[i] = counter + i;
    }
    
    can_msg->flags = 0;  // No special flags
    counter++;
}

// Simulated function to send a CAN message to a CAN bus
void simulate_can_message_send(const can_message_t *can_msg) {
    printf("Simulated CAN message send - ID: 0x%X, Data: ", can_msg->can_id);
    for (int i = 0; i < can_msg->can_dlc; i++) {
        printf("%02X ", can_msg->data[i]);
    }
    printf("\n");
}

// Example of a CAN-to-PCIe gateway in Zone 1
void run_zone1_gateway() {
    printf("Starting Zone 1 Gateway (CAN to PCIe)\n");
    
    // Initialize the PCIe client
    if (pcie_client_init() != 0) {
        fprintf(stderr, "Failed to initialize PCIe client in Zone 1\n");
        return;
    }
    
    // Process CAN messages in a loop
    while (running) {
        // 1. Read a CAN message from the CAN bus
        can_message_t can_msg;
        simulate_can_message_receive(&can_msg);
        
        // 2. Create a bus message structure
        bus_message_t bus_msg;
        bus_msg.type = MSG_TYPE_CAN;
        bus_msg.timestamp = 0;  // Will be set by pcie_send_bus_message
        memcpy(&(bus_msg.data.can), &can_msg, sizeof(can_message_t));
        
        // 3. Send the bus message over PCIe
        // Arguments: message, zone_id, device_id, priority
        if (pcie_send_bus_message(&bus_msg, 1, 42, 0) != 0) {
            fprintf(stderr, "Failed to send bus message over PCIe\n");
        } else {
            printf("CAN message sent to PCIe backbone from Zone 1\n");
        }
        
        // Sleep for a bit before sending the next message
        sleep(1);
    }
    
    // Cleanup the PCIe client
    pcie_client_cleanup();
    printf("Zone 1 Gateway stopped\n");
}

// Example of a PCIe-to-CAN gateway in Zone 2
void run_zone2_gateway() {
    printf("Starting Zone 2 Gateway (PCIe to CAN)\n");
    
    // Initialize the PCIe client
    if (pcie_client_init() != 0) {
        fprintf(stderr, "Failed to initialize PCIe client in Zone 2\n");
        return;
    }
    
    // Process PCIe messages in a loop
    while (running) {
        // 1. Receive a bus message from PCIe
        bus_message_t bus_msg;
        uint32_t source_zone_id;
        uint32_t source_device_id;
        
        if (pcie_receive_bus_message(&bus_msg, &source_zone_id, &source_device_id) != 0) {
            fprintf(stderr, "Failed to receive bus message from PCIe\n");
            sleep(1);
            continue;
        }
        
        printf("Received message from Zone %u, Device %u\n", source_zone_id, source_device_id);
        
        // 2. Check if it's a CAN message
        if (bus_msg.type == MSG_TYPE_CAN) {
            // 3. Convert to CAN message and send on local CAN bus
            simulate_can_message_send(&(bus_msg.data.can));
        } else {
            printf("Ignoring non-CAN message of type %d\n", bus_msg.type);
        }
        
        // Process messages as fast as they arrive
    }
    
    // Cleanup the PCIe client
    pcie_client_cleanup();
    printf("Zone 2 Gateway stopped\n");
}

int main(int argc, char *argv[]) {
    // Set up signal handling for graceful termination
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Check command line arguments to determine which zone to simulate
    if (argc < 2) {
        fprintf(stderr, "Usage: %s [zone1|zone2]\n", argv[0]);
        return 1;
    }
    
    if (strcmp(argv[1], "zone1") == 0) {
        run_zone1_gateway();
    } else if (strcmp(argv[1], "zone2") == 0) {
        run_zone2_gateway();
    } else {
        fprintf(stderr, "Unknown zone: %s\n", argv[1]);
        return 1;
    }
    
    return 0;
}