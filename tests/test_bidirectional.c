#include <stdio.h>
#include "translation.h"

int main(void) {
    // --- Test for CAN ---
    BusMessage canMsg = { BUS_CAN, 0x123, 8, {0xAA, 0xBB, 0xCC, 0xDD, 0x11, 0x22, 0x33, 0x44} };
    PcieMessage pcieMsg = translate(&canMsg);
    BusMessage decodedCan = reverse_translate(&pcieMsg);
    printf("CAN Test:\n");
    printf("  Original ID: 0x%X, Decoded ID: 0x%X\n", canMsg.id, decodedCan.id);
    printf("  Original Length: %d, Decoded Length: %d\n", canMsg.length, decodedCan.length);
    
    // --- Test for FlexRay ---
    BusMessage flexrayMsg = { BUS_FLEXRAY, 0x456, 16, {0} };
    for (uint32_t i = 0; i < flexrayMsg.length; i++) {
        flexrayMsg.data[i] = i;
    }
    pcieMsg = translate(&flexrayMsg);
    BusMessage decodedFlexray = reverse_translate(&pcieMsg);
    printf("\nFlexRay Test:\n");
    printf("  Original ID: 0x%X, Decoded ID: 0x%X\n", flexrayMsg.id, decodedFlexray.id);
    printf("  Original Length: %d, Decoded Length: %d\n", flexrayMsg.length, decodedFlexray.length);
    
    // --- Test for Video ---
    BusMessage videoMsg = { BUS_VIDEO, 0x789, 32, {0} };
    for (uint32_t i = 0; i < videoMsg.length; i++) {
        videoMsg.data[i] = (uint8_t)(0xFF - i);
    }
    pcieMsg = translate(&videoMsg);
    BusMessage decodedVideo = reverse_translate(&pcieMsg);
    printf("\nVideo Test:\n");
    printf("  Original ID: 0x%X, Decoded ID: 0x%X\n", videoMsg.id, decodedVideo.id);
    printf("  Original Length: %d, Decoded Length: %d\n", videoMsg.length, decodedVideo.length);
    
    int errors = 0;
    for (uint32_t i = 0; i < videoMsg.length; i++) {
        if (videoMsg.data[i] != decodedVideo.data[i]) {
            errors++;
        }
    }
    if (errors == 0) {
        printf("\nBidirectional translation tests passed.\n");
    } else {
        printf("\nBidirectional translation tests failed with %d errors.\n", errors);
    }
    
    return 0;
}
