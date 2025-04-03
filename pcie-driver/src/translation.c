#include "translation.h"

PcieMessage translate(const BusMessage *msg) {
    PcieMessage pcie;
    
    // Construct the 64-bit header:
    // Bits 0-3:   busType (4 bits)
    // Bits 4-19:  id (16 bits)
    // Bits 20-35: length (16 bits)
    // Bits 36-63: reserved (0)
    pcie.header = ((uint64_t)(msg->busType & 0xF)) |
                  (((uint64_t)(msg->id & 0xFFFF)) << 4) |
                  (((uint64_t)(msg->length & 0xFFFF)) << 20);
                  
    // Copy the payload into the PCIe message.
    // We assume that msg->length does not exceed MAX_PAYLOAD_SIZE.
    for (uint32_t i = 0; i < msg->length && i < MAX_PAYLOAD_SIZE; i++) {
        pcie.payload[i] = msg->data[i];
    }
    // Zero-out any remaining bytes in the PCIe payload.
    for (uint32_t i = msg->length; i < MAX_PAYLOAD_SIZE; i++) {
        pcie.payload[i] = 0;
    }
    
    return pcie;
}

BusMessage reverse_translate(const PcieMessage *pcie) {
    BusMessage msg;
    
    // Decode the 64-bit header.
    msg.busType = (BusType)(pcie->header & 0xF);
    msg.id = (uint32_t)((pcie->header >> 4) & 0xFFFF);
    msg.length = (uint32_t)((pcie->header >> 20) & 0xFFFF);
    
    // Copy payload from PCIe message into the BusMessage.
    // We assume msg.length does not exceed MAX_PAYLOAD_SIZE.
    for (uint32_t i = 0; i < msg.length && i < MAX_PAYLOAD_SIZE; i++) {
        msg.data[i] = pcie->payload[i];
    }
    // Zero-out any remaining bytes in msg.data.
    for (uint32_t i = msg.length; i < MAX_PAYLOAD_SIZE; i++) {
        msg.data[i] = 0;
    }
    
    return msg;
}
