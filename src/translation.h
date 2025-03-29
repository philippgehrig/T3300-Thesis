#ifndef TRANSLATION_H
#define TRANSLATION_H

#include "bus_message.h"
#include "pcie.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * translate
 * ---------
 * Converts a BusMessage (CAN, FlexRay, or Video) into a PCIe message.
 *
 * The 64-bit PCIe header is constructed as:
 *   Bits 0-3   : Bus type (BUS_CAN, BUS_FLEXRAY, BUS_VIDEO)
 *   Bits 4-19  : Message ID (16 bits)
 *   Bits 20-35 : Length (16 bits)
 *   Bits 36-63 : Reserved (0)
 *
 * Parameters:
 *   - msg: Pointer to the input BusMessage.
 *
 * Returns:
 *   - A PcieMessage with the encoded header and payload.
 */
PcieMessage translate(const BusMessage *msg);

/*
 * reverse_translate
 * -----------------
 * Converts a PCIe message back into a BusMessage.
 *
 * This function decodes the 64-bit header and copies the payload.
 *
 * Parameters:
 *   - pcie: Pointer to the input PCIe message.
 *
 * Returns:
 *   - A BusMessage reconstructed from the PCIe message.
 */
BusMessage reverse_translate(const PcieMessage *pcie);

#ifdef __cplusplus
}
#endif

#endif // TRANSLATION_H
