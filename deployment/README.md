# Deployment

## PCIe-Client

The deployment process automates the installation and configuration of the PCIe client on NVIDIA Jetson devices. This directory contains the necessary Ansible playbooks and scripts to deploy the PCIe client to multiple Jetson devices simultaneously.

### Prerequisites

- Ansible installed on your deployment machine
- SSH access to target Jetson devices
- Environment variables configured (see below)

### Directory Structure

```
deployment/
├── deploy-pcie-client.yml  # Main Ansible playbook for PCIe client deployment
├── deploy-pcie-client.sh   # Shell script wrapper for deployment
├── inventory.yml           # Target device inventory configuration
├── pcie/                   # PCIe endpoint configuration scripts
│   ├── diagnose-pcie-endpoint.sh      # Script to diagnose PCIe endpoint issues
│   ├── configure-pcie-endpoint.sh     # Script to configure PCIe endpoint settings
│   └── setup-pcie-endpoint.sh         # Script to set up PCIe endpoint functionality
└── README.md               # This documentation file
```

### Configuration

1. **Environment Variables**

   All credentials and configuration settings are stored in the repository's root `.env` file. A template is provided in `.env.template` at the repository root.
   
   Required environment variables:
   ```
   ANSIBLE_USER=username     # SSH username for Jetson devices
   ANSIBLE_PASSWORD=password # SSH password for Jetson devices
   ```

2. **Inventory Configuration**

   The `inventory.yml` file defines the target Jetson devices. Update the IP addresses to match your environment:
   ```yaml
   jetson1:
     ansible_host: 192.168.1.101  # Replace with actual IP address
   jetson2:
     ansible_host: 192.168.1.102  # Replace with actual IP address
   ```

### Deployment Instructions

1. **Update Environment Variables**

   Ensure your `.env` file at the repository root contains valid credentials:
   ```
   ANSIBLE_USER=your_actual_username
   ANSIBLE_PASSWORD=your_actual_password
   ```

2. **Make Deployment Script Executable**

   Before running the deployment script for the first time, you need to make it executable:
   ```bash
   chmod +x deploy-pcie-client.sh
   ```

3. **Run Deployment Script**

   ```bash
   cd deployment
   ./deploy-pcie-client.sh
   ```
   
   This script loads environment variables from the root `.env` file and executes the Ansible playbook.

4. **Manual Deployment (Alternative)**

   If you prefer to run the playbook directly:
   ```bash
   cd deployment
   ansible-playbook -i inventory.yml deploy-pcie-client.yml --extra-vars "ansible_user=username ansible_password=password"
   ```

### What Gets Deployed

The deployment process:

1. Installs required dependencies on the target Jetson devices
2. Copies PCIe client source code to each device
3. Compiles the PCIe client
4. Installs the compiled binary to `/usr/local/bin/`
5. Sets up a systemd service to automatically run the PCIe client on startup
6. Starts the service

### Troubleshooting

- **SSH Connection Issues**: Verify SSH credentials and ensure the Jetson devices are reachable
- **Build Failures**: Check for required dependencies on the target devices
- **Service Failures**: Examine logs with `journalctl -u pcie-client`

### Advanced Configuration

For additional customization options, modify the `deploy-pcie-client.yml` playbook. Key parameters that can be adjusted include:

- `target_dir`: The directory where the PCIe client is deployed on the target devices
- Build options in the generated Makefile
- Service configuration parameters

## PCIe Endpoint Configuration

The `pcie/` directory contains scripts to diagnose, configure, and set up PCIe endpoint functionality on NVIDIA Jetson devices. These scripts help manage the PCIe endpoint mode, which allows the Jetson device to function as a PCIe endpoint (device) rather than a PCIe root complex (host).

### Prerequisites

- SSH access to the target Jetson device
- Root access on the Jetson device (for configuration changes)
- The Jetson device must be flashed with appropriate ODMDATA value to support PCIe endpoint mode

### Scripts Overview

1. **diagnose-pcie-endpoint.sh**

   This script diagnoses PCIe endpoint mode issues on Jetson platforms by checking various system configurations.

   ```bash
   cd deployment/pcie
   chmod +x diagnose-pcie-endpoint.sh
   ./diagnose-pcie-endpoint.sh
   ```

   Alternatively, run it via SSH directly on the target device:
   
   ```bash
   ssh user@jetson-device "bash -s" < diagnose-pcie-endpoint.sh
   ```

   The script performs the following checks:
   - Kernel parameters for PCIe endpoint
   - Loaded and available PCIe-related kernel modules
   - PCIe controller status
   - ConfigFS mount status
   - Device tree configuration for PCIe endpoint
   - Available PCIe endpoint functions
   - ODMDATA value (if accessible)
   - PCIe driver messages from kernel logs

   If you encounter issues, this script helps identify whether they are related to:
   - Incorrect ODMDATA values
   - Missing kernel modules
   - Incorrect device tree configuration

2. **configure-pcie-endpoint.sh**

   This script configures PCIe endpoint settings on the Jetson device.

   ```bash
   cd deployment/pcie
   chmod +x configure-pcie-endpoint.sh
   ./configure-pcie-endpoint.sh [OPTIONS]
   ```

   Options:
   - `--controller CONTROLLER_NAME`: Specify the PCIe controller to configure (default: the first available controller)
   - `--vid VENDOR_ID`: Set the PCIe Vendor ID (default: 0x10DE for NVIDIA)
   - `--did DEVICE_ID`: Set the PCIe Device ID (default: 0x0001)
   - `--help`: Display usage information

   The script configures the PCIe endpoint controller with the specified vendor and device IDs.

3. **setup-pcie-endpoint.sh**

   This script performs a complete setup of the PCIe endpoint functionality.

   ```bash
   cd deployment/pcie
   chmod +x setup-pcie-endpoint.sh
   ./setup-pcie-endpoint.sh [OPTIONS]
   ```

   Options:
   - `--controller CONTROLLER_NAME`: Specify the PCIe controller
   - `--function FUNCTION_NAME`: Specify the PCIe endpoint function to use (default: pci_epf_test)
   - `--vid VENDOR_ID`: Set the PCIe Vendor ID
   - `--did DEVICE_ID`: Set the PCIe Device ID
   - `--help`: Display usage information

   The script performs the following actions:
   - Loads necessary kernel modules
   - Configures the PCIe controller in endpoint mode
   - Creates and configures a PCIe endpoint function
   - Binds the function to the controller
   - Enables the PCIe endpoint functionality

### Usage Flow

For a complete PCIe endpoint configuration workflow:

1. First, diagnose the device to ensure it supports PCIe endpoint mode:
   ```bash
   ./diagnose-pcie-endpoint.sh
   ```

2. If the diagnosis confirms PCIe endpoint capabilities, configure the endpoint:
   ```bash
   ./configure-pcie-endpoint.sh --vid 0x10DE --did 0x0001
   ```

3. Finally, set up the PCIe endpoint functionality:
   ```bash
   ./setup-pcie-endpoint.sh --function pci_epf_test
   ```

### Common Issues and Solutions

- **"Operation not permitted" errors**: This typically indicates that the Jetson device was not flashed with the correct ODMDATA value to support PCIe endpoint mode. Re-flash the device with the appropriate configuration.

- **Missing modules**: If the diagnostic script shows missing PCIe endpoint modules, they may need to be built and installed separately, or you may need to update to a newer Jetson Linux version that includes these modules.

- **Configuration persistence**: Note that the configuration set by these scripts does not persist across reboots by default. Use systemd services to apply the configuration at boot time.

- **Hardware requirements**: Ensure that the PCIe connector on the Jetson device is properly connected to a PCIe host system for testing endpoint functionality.

