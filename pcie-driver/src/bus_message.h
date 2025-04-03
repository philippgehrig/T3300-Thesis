#ifndef BUS_MESSAGE_H
#define BUS_MESSAGE_H

#include <stdint.h>

#define MAX_PAYLOAD_SIZE 1024

// Supported bus types.
typedef enum {
    BUS_CAN = 0,
    BUS_FLEXRAY = 1,
    BUS_VIDEO = 2
} BusType;

/*
 * BusMessage
 * ----------
 * Represents a generic message coming from various bus protocols.
 *
 * - busType: Indicates the protocol (CAN, FlexRay, Video).
 * - id: Identifier (16-bit used here for simplicity).
 * - length: Length in bytes of the payload.
 * - data: Payload data (size MAX_PAYLOAD_SIZE).
 */
typedef struct {
    BusType busType;
    uint32_t id;
    uint32_t length;
    uint8_t data[MAX_PAYLOAD_SIZE];
} BusMessage;

#endif // BUS_MESSAGE_H
