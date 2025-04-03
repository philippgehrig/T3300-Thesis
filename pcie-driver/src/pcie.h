#ifndef PCIE_H
#define PCIE_H

#include <stdint.h>
#include "bus_message.h"

/*
 * PcieMessage
 * -----------
 * Represents a PCIe message with a 64-bit header and a payload.
 *
 * The header encoding is defined as:
 *  - Bits 0-3:   Bus type
 *  - Bits 4-19:  Message ID (16 bits)
 *  - Bits 20-35: Payload length (16 bits)
 *  - Bits 36-63: Reserved (set to 0)
 */
typedef struct {
    uint64_t header;                   // 64-bit header
    uint8_t payload[MAX_PAYLOAD_SIZE]; // Payload (maximum size as defined)
} PcieMessage;

#endif // PCIE_H
