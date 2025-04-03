# CAN Simulation on Raspberry Pi

This project demonstrates how to simulate CAN messages using a Raspberry Pi with a CAN shield. The provided C program (`can.c`) utilizes SocketCAN to send simulated CAN frames.

## Requirements

- Raspberry Pi running a Linux-based OS
- CAN shield compatible with SocketCAN
- gcc compiler
- Kernel headers (Linux CAN headers are typically part of these)
  - On Debian-based systems, you may need to install them via:
    ```bash
    sudo apt-get install linux-headers-$(uname -r)
    ```

## Setup

1. **Connect your CAN shield:**
   - Ensure your CAN shield is correctly connected to your Raspberry Pi.
   - Verify that the CAN interface (usually `can0`) is available. You might need to configure your network interface (e.g., via `sudo ip link set can0 up type can bitrate 500000`).

2. **Compile the Program:**
   - Open a terminal in the project directory.
   - Run the following command to build the project:
     ```bash
     make
     ```
   - The Makefile will first check for the presence of the Linux CAN header files. If they are not found, you will see an error message instructing you to install the appropriate kernel headers.

3. **Run the Simulation:**
   - After compilation, execute the program with:
     ```bash
     ./can
     ```
   - The program will simulate sending a series of CAN messages. You should see output in the terminal indicating the messages being sent.

## Cleaning Up

To remove the compiled executable, run:
```bash
make clean
```

## Customization

- CAN Interface:
If your CAN interface is different from can0, update the interface name in the can.c source file.
Message Parameters:
- You can adjust the CAN ID, data length, and payload within can.c as per your requirements.


## Troubleshooting

- Ensure the CAN interface is up and properly configured before running the program.
- Use tools like candump from the can-utils package to monitor CAN messages on your network.