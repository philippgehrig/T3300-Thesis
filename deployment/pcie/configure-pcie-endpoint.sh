#!/bin/bash

# Script to configure PCIe Endpoint mode on Jetson platforms
# To be run on the Jetson device after flashing and booting

echo "Configuring PCIe Endpoint mode..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Load necessary kernel modules
echo "Loading required kernel modules..."
modprobe pci_epf_nv_test
modprobe configfs

# Check if modules loaded successfully
if ! lsmod | grep -q "pci_epf_nv_test"; then
  echo "ERROR: Failed to load pci_epf_nv_test module"
  echo "Available modules:"
  find /lib/modules/$(uname -r) -name "*pci*" | grep -i ep
  exit 1
fi

# Navigate to the configfs PCIe endpoint directory
cd /sys/kernel/config/pci_ep/

# Show available controllers and functions
echo "Available controllers:"
ls -la controllers/ 2>/dev/null || echo "No controllers directory found"

echo "Available functions:"
ls -la functions/ 2>/dev/null || echo "No functions directory found"

# Create necessary directories if they don't exist
mkdir -p functions/

# If pci_epf_nv_test directory doesn't exist, the module might not be loaded correctly
if [ ! -d "functions/pci_epf_nv_test" ]; then
  echo "ERROR: pci_epf_nv_test directory not found in functions/"
  echo "This indicates the module is not loaded properly or not available"
  echo "Checking kernel modules that might contain PCIe EP functionality:"
  find /lib/modules/$(uname -r) -name "*pci*ep*" -o -name "*ep*pci*"
  exit 1
fi

mkdir -p functions/pci_epf_nv_test/func1

# Set vendor ID (NVIDIA: 0x10de)
echo 0x10de > functions/pci_epf_nv_test/func1/vendorid

# Set device ID
echo 0x0001 > functions/pci_epf_nv_test/func1/deviceid

# Determine the controller path based on the device
CONTROLLER=""

# Check if we're on Orin AGX
if [ -d "controllers/141a0000.pcie_ep" ]; then
  CONTROLLER="controllers/141a0000.pcie_ep"
elif [ -d "controllers/14160000.pcie_ep" ]; then 
  CONTROLLER="controllers/14160000.pcie_ep"
# Check if we're on Xavier AGX
elif [ -d "controllers/14120000.pcie_ep" ]; then
  CONTROLLER="controllers/14120000.pcie_ep"
# Check if we're on Orin Nano
elif [ -d "controllers/14100000.pcie_ep" ]; then
  CONTROLLER="controllers/14100000.pcie_ep"
fi

if [ -z "$CONTROLLER" ]; then
  echo "ERROR: Could not find PCIe endpoint controller!"
  echo "Available controllers are:"
  ls -la controllers/
  exit 1
fi

echo "Using PCIe endpoint controller: $CONTROLLER"

# Link the function to the controller
ln -sf functions/pci_epf_nv_test/func1 "$CONTROLLER/"

# Start the endpoint
echo 1 > "$CONTROLLER/start"

echo "PCIe Endpoint configuration complete!"
echo "To verify on the host system, use: lspci -vv"