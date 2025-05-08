# Deployment

This directory contains all the tools, scripts, and configurations needed for deploying and configuring the system on NVIDIA Jetson devices. The deployment process consists of three main components:

1. **Flash** - Scripts and configurations for flashing NVIDIA Jetson devices
2. **Proxy** - Network proxy configuration tools and scripts
3. **PCIe** - PCIe client deployment and endpoint configuration

## Directory Structure

```
📁 deployment/
 ├── 📄 README.md                  # This documentation file
 ├── 📁 flash/                     # Flashing tools and configurations
 │   ├── 📄 automatedFlash.sh      # Script for automating the flashing process
 │   ├── 📁 NvidiaOrinRoot/        # Root filesystem for Orin devices
 │   │   └── 📁 Linux_for_Tegra/   # NVIDIA L4T package for Orin
 │   └── 📁 NvidiaXavierRoot/      # Root filesystem for Xavier devices
 │       └── 📁 Linux_for_Tegra/   # NVIDIA L4T package for Xavier
 ├── 📁 proxy/                     # Proxy configuration tools
 │   ├── 📄 80proxy               # APT proxy configuration file
 │   ├── 📄 check_jetpack_installation.sh # Script to verify JetPack installation
 │   ├── 📄 configureProxy.sh      # Script to configure proxy settings
 │   ├── 📄 setup-jetson-remote.sh # Remote setup script for Jetson devices
 │   └── 📁 trusted.gpg.d/        # Trusted GPG keys for package repositories
 └── 📁 pcie/                      # PCIe deployment and configuration
     ├── 📄 configure-pcie-endpoint.sh # Script to configure PCIe endpoint
     ├── 📄 deploy-pcie-client.sh  # Script to deploy PCIe client
     ├── 📄 deploy-pcie-client.yml # Ansible playbook for PCIe client deployment
     ├── 📄 diagnose-pcie-endpoint.sh # Script to diagnose PCIe endpoint issues
     ├── 📄 inventory.yml          # Target device inventory configuration
     └── 📄 setup-pcie-endpoint.sh # Script to set up PCIe endpoint
```

## Flash Directory

The flash directory contains tools and configurations for flashing NVIDIA Jetson devices with the appropriate operating system and firmware.

### Prerequisites

- Host machine running Ubuntu (18.04 or later recommended)
- USB cable to connect to the Jetson device
- Jetson device in recovery mode

### Flashing Process

1. **Automated Flashing**

   The `automatedFlash.sh` script automates the flashing process for both Orin and Xavier devices:

   ```bash
   cd deployment/flash
   sudo ./automatedFlash.sh [OPTIONS]
   ```

   Options:
   - `--device TYPE`: Specify device type (orin or xavier)
   - `--variant VARIANT`: Specify device variant (e.g., devkit, nx, nano)
   - `--help`: Display usage information

2. **NVIDIA L4T Packages**

   The flashing process uses NVIDIA Linux for Tegra (L4T) packages specific to each device type:
   
   - `NvidiaOrinRoot/` contains the L4T package for Orin devices
   - `NvidiaXavierRoot/` contains the L4T package for Xavier devices

   These directories contain the necessary files to flash the devices, including bootloaders, kernel images, and root filesystems.

## Proxy Directory

The proxy directory contains tools and configurations for setting up network proxy settings on Jetson devices.

### Proxy Configuration Files

- **80proxy**: APT proxy configuration file that defines proxy settings for package management
- **trusted.gpg.d/**: Directory containing trusted GPG keys for package repositories

### Proxy Configuration Scripts

1. **configureProxy.sh**

   This script configures proxy settings, NTP server, and trusted GPG keys on Jetson devices:

   ```bash
   cd deployment/proxy
   sudo ./configureProxy.sh [OPTIONS]
   ```

   Options:
   - `--proxy-host HOST`: Set proxy hostname or IP (default: 192.168.1.1)
   - `--proxy-port PORT`: Set proxy port (default: 44000)
   - `--no-proxy`: Disable proxy configuration
   - `--ntp-server HOST`: Set NTP server hostname or IP (default: 53.60.5.254)
   - `--no-local-config`: Don't use local proxy configuration files
   - `--help`: Show help message

2. **setup-jetson-remote.sh**

   This script performs remote setup operations on Jetson devices, including proxy configuration:

   ```bash
   cd deployment/proxy
   ./setup-jetson-remote.sh [OPTIONS]
   ```

   The script connects to a remote Jetson device via SSH and performs setup operations.

3. **check_jetpack_installation.sh**

   This script verifies that JetPack components are properly installed on a Jetson device:

   ```bash
   cd deployment/proxy
   ./check_jetpack_installation.sh
   ```

   The script checks for the presence of key JetPack components and reports their status.

## PCIe-Client Deployment

The PCIe-Client deployment automates the installation and configuration of the PCIe client on NVIDIA Jetson devices. This directory contains the necessary Ansible playbooks and scripts to deploy the PCIe client to multiple Jetson devices simultaneously.

### Prerequisites

- Ansible installed on your deployment machine
- SSH access to target Jetson devices
- Environment variables configured (see below)

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
   cd deployment/pcie
   ./deploy-pcie-client.sh
   ```
   
   This script loads environment variables from the root `.env` file and executes the Ansible playbook.

4. **Manual Deployment (Alternative)**

   If you prefer to run the playbook directly:
   ```bash
   cd deployment/pcie
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

## Complete Deployment Workflow

A complete workflow for deploying a system would typically involve these steps in order:

1. **Flash the Jetson device**:
   ```bash
   cd deployment/flash
   sudo ./automatedFlash.sh --device orin --variant devkit
   ```

2. **Configure proxy settings** (if needed):
   ```bash
   cd deployment/proxy
   ./setup-jetson-remote.sh --jetson-host 192.168.1.100 --jetson-user username
   ```

3. **Verify JetPack installation**:
   ```bash
   cd deployment/proxy
   ./check_jetpack_installation.sh
   ```

4. **Deploy PCIe client**:
   ```bash
   cd deployment/pcie
   ./deploy-pcie-client.sh
   ```

5. **Configure PCIe endpoint** (if using endpoint mode):
   ```bash
   cd deployment/pcie
   ./setup-pcie-endpoint.sh
   ```

This complete workflow will prepare a Jetson device with the operating system, network configuration, and PCIe functionality required for the system.

