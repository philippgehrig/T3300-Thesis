#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>

int main(void) {
    int s;  // Socket descriptor
    struct sockaddr_can addr;
    struct ifreq ifr;
    struct can_frame frame;
    int nbytes;

    // Create the socket for CAN communication
    if ((s = socket(PF_CAN, SOCK_RAW, CAN_RAW)) < 0) {
        perror("Error while opening socket");
        return EXIT_FAILURE;
    }

    // Specify the CAN interface (e.g., "can0")
    strcpy(ifr.ifr_name, "can0");
    if (ioctl(s, SIOCGIFINDEX, &ifr) < 0) {
        perror("Error in ioctl");
        close(s);
        return EXIT_FAILURE;
    }

    // Bind the socket to the CAN interface
    addr.can_family  = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex; 
    if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("Error in socket bind");
        close(s);
        return EXIT_FAILURE;
    }

    printf("Socket opened and bound to %s\n", ifr.ifr_name);

    // Simulate sending 10 CAN messages with incrementing data bytes
    for (int i = 0; i < 10; i++) {
        frame.can_id  = 0x123;  // Example CAN ID
        frame.can_dlc = 8;      // Data length code (number of data bytes)
        
        // Fill data with some simulated values
        for (int j = 0; j < frame.can_dlc; j++) {
            frame.data[j] = i + j;
        }

        nbytes = write(s, &frame, sizeof(struct can_frame));
        if (nbytes != sizeof(struct can_frame)) {
            perror("Write error");
            close(s);
            return EXIT_FAILURE;
        }

        printf("Sent CAN message %d\n", i);
        sleep(1);  // Delay 1 second between messages
    }

    // Close the CAN socket
    close(s);
    return EXIT_SUCCESS;
}
