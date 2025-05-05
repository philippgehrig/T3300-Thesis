#ifndef PCIE_TRANSLATION_H
#define PCIE_TRANSLATION_H

#include <stdint.h>
#include <stddef.h>

// Message types for different bus protocols
typedef enum {
    MSG_TYPE_CAN,     // Controller Area Network
    MSG_TYPE_LIN,     // Local Interconnect Network
    MSG_TYPE_FLEXRAY, // FlexRay
    MSG_TYPE_ETHERNET // Automotive Ethernet
} bus_message_type_t;

// Generic structure for CAN messages
typedef struct {
    uint32_t can_id;     // CAN identifier
    uint8_t can_dlc;     // Data length code
    uint8_t data[8];     // CAN data (max 8 bytes)
    uint8_t flags;       // Additional flags (e.g., RTR, error frame)
} can_message_t;

// Generic structure for LIN messages
typedef struct {
    uint8_t lin_id;      // LIN identifier
    uint8_t lin_dlc;     // Data length
    uint8_t data[8];     // LIN data (max 8 bytes)
    uint8_t checksum;    // LIN checksum
} lin_message_t;

// Generic structure for FlexRay messages
typedef struct {
    uint16_t frame_id;   // FlexRay frame ID
    uint8_t payload_length; // Payload length
    uint8_t data[64];    // FlexRay data (max 64 bytes)
    uint8_t channel;     // Channel (A, B or both)
    uint8_t cycle;       // Cycle count
} flexray_message_t;

// Generic structure for Ethernet messages
typedef struct {
    uint8_t dest_mac[6]; // Destination MAC address
    uint8_t src_mac[6];  // Source MAC address
    uint16_t ethertype;  // Ethertype
    uint8_t *data;       // Ethernet payload
    size_t data_len;     // Payload length
} ethernet_message_t;

// Unified message structure that can represent messages from any bus
typedef struct {
    bus_message_type_t type;      // Type of message
    uint64_t timestamp;           // Message timestamp
    union {
        can_message_t can;
        lin_message_t lin;
        flexray_message_t flexray;
        ethernet_message_t ethernet;
    } data;
} bus_message_t;

// PCIe message structure with header for zonal architecture
typedef struct {
    uint32_t zone_id;             // Source/destination zone ID
    uint32_t device_id;           // Source/destination device ID
    uint32_t message_id;          // Message ID for routing/filtering
    uint32_t priority;            // Message priority (0=highest)
    uint32_t payload_size;        // Size of payload in bytes
    bus_message_t bus_message;    // The actual bus message
} pcie_message_t;

// Function prototypes for message translation

// Translate a CAN message to PCIe message format
int translate_can_to_pcie(const can_message_t *can_msg, pcie_message_t *pcie_msg, uint32_t zone_id, uint32_t device_id);

// Translate a PCIe message to CAN message format
int translate_pcie_to_can(const pcie_message_t *pcie_msg, can_message_t *can_msg);

// Send a bus message over PCIe
int pcie_send_bus_message(const bus_message_t *msg, uint32_t zone_id, uint32_t device_id, uint32_t priority);

// Receive a bus message from PCIe
int pcie_receive_bus_message(bus_message_t *msg, uint32_t *zone_id, uint32_t *device_id);

#endif // PCIE_TRANSLATION_H