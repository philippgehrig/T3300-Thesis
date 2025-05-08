#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <linux/time.h>
#include <stdint.h>
#include "pcie_common.h"
#include "pcie_client.h"
#include "pcie_translation.h"

// Get current timestamp in microseconds
static uint64_t get_timestamp_us() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)(ts.tv_sec * 1000000 + ts.tv_nsec / 1000);
}

// Translate a CAN message to PCIe message format
int translate_can_to_pcie(const can_message_t *can_msg, pcie_message_t *pcie_msg, uint32_t zone_id, uint32_t device_id) {
    if (can_msg == NULL || pcie_msg == NULL) {
        pcie_log("Translator", "Error: Invalid pointers for CAN to PCIe translation");
        return -1;
    }

    // Fill in PCIe message header
    pcie_msg->zone_id = zone_id;
    pcie_msg->device_id = device_id;
    pcie_msg->message_id = can_msg->can_id;  // Use CAN ID as message ID
    pcie_msg->priority = 0;  // Default to highest priority
    pcie_msg->payload_size = sizeof(bus_message_t);

    // Fill in bus message content
    pcie_msg->bus_message.type = MSG_TYPE_CAN;
    pcie_msg->bus_message.timestamp = get_timestamp_us();
    
    // Copy the CAN message data
    memcpy(&(pcie_msg->bus_message.data.can), can_msg, sizeof(can_message_t));

    return 0;
}

// Translate a PCIe message to CAN message format
int translate_pcie_to_can(const pcie_message_t *pcie_msg, can_message_t *can_msg) {
    if (pcie_msg == NULL || can_msg == NULL) {
        pcie_log("Translator", "Error: Invalid pointers for PCIe to CAN translation");
        return -1;
    }

    // Check if the message type is CAN
    if (pcie_msg->bus_message.type != MSG_TYPE_CAN) {
        pcie_log("Translator", "Error: PCIe message is not a CAN message");
        return -1;
    }

    // Copy the CAN message data from the PCIe message
    memcpy(can_msg, &(pcie_msg->bus_message.data.can), sizeof(can_message_t));

    return 0;
}

// Send a bus message over PCIe
int pcie_send_bus_message(const bus_message_t *msg, uint32_t zone_id, uint32_t device_id, uint32_t priority) {
    if (msg == NULL) {
        pcie_log("Translator", "Error: Invalid message pointer for PCIe send");
        return -1;
    }

    // Create a PCIe message
    pcie_message_t pcie_msg;
    pcie_msg.zone_id = zone_id;
    pcie_msg.device_id = device_id;
    pcie_msg.priority = priority;
    pcie_msg.payload_size = sizeof(bus_message_t);
    
    // Set the message ID based on the bus message type
    switch (msg->type) {
        case MSG_TYPE_CAN:
            pcie_msg.message_id = msg->data.can.can_id;
            break;
        case MSG_TYPE_LIN:
            pcie_msg.message_id = msg->data.lin.lin_id;
            break;
        case MSG_TYPE_FLEXRAY:
            pcie_msg.message_id = msg->data.flexray.frame_id;
            break;
        case MSG_TYPE_ETHERNET:
            pcie_msg.message_id = msg->data.ethernet.ethertype;
            break;
        default:
            pcie_log("Translator", "Error: Unknown bus message type");
            return -1;
    }
    
    // Copy the bus message
    memcpy(&(pcie_msg.bus_message), msg, sizeof(bus_message_t));
    
    // Serialize the PCIe message to a buffer
    char buffer[1024];
    size_t msg_size = sizeof(pcie_message_t);
    memcpy(buffer, &pcie_msg, msg_size);
    
    // Send the serialized message via PCIe
    pcie_log("Translator", "Sending bus message over PCIe");
    return pcie_client_send(buffer);
}

// Receive a bus message from PCIe
int pcie_receive_bus_message(bus_message_t *msg, uint32_t *zone_id, uint32_t *device_id) {
    if (msg == NULL || zone_id == NULL || device_id == NULL) {
        pcie_log("Translator", "Error: Invalid pointers for PCIe receive");
        return -1;
    }
    
    // Buffer for receiving PCIe message
    char buffer[1024];
    
    // Receive raw PCIe message
    if (pcie_client_receive(buffer, sizeof(buffer)) != 0) {
        pcie_log("Translator", "Error: Failed to receive PCIe message");
        return -1;
    }
    
    // Deserialize the PCIe message
    pcie_message_t pcie_msg;
    memcpy(&pcie_msg, buffer, sizeof(pcie_message_t));
    
    // Extract the zone and device IDs
    *zone_id = pcie_msg.zone_id;
    *device_id = pcie_msg.device_id;
    
    // Extract the bus message
    memcpy(msg, &(pcie_msg.bus_message), sizeof(bus_message_t));
    
    pcie_log("Translator", "Received bus message from PCIe");
    return 0;
}