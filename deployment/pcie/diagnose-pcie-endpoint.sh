#!/bin/bash

# Script to diagnose PCIe Endpoint mode issues on Jetson platforms

echo "===== PCIe Endpoint Diagnostic Tool ====="
echo "Running as user: $(whoami)"

# Check kernel parameters for PCIe endpoint
echo -e "\n=== Kernel Parameters ==="
grep -i pci /proc/cmdline

# Check loaded PCIe-related modules
echo -e "\n=== Loaded PCIe Modules ==="
lsmod | grep -E 'pci|ep'

# Check available PCIe-related modules
echo -e "\n=== Available PCIe Modules ==="
find /lib/modules/$(uname -r) -name "*pci*ep*" -o -name "*ep*pci*"

# Check PCIe controller status
echo -e "\n=== PCIe Controller Status ==="
if [ -d "/sys/kernel/config/pci_ep/controllers" ]; then
  ls -la /sys/kernel/config/pci_ep/controllers/
else
  echo "No controllers directory found in /sys/kernel/config/pci_ep/"
fi

# Check ConfigFS mount status
echo -e "\n=== ConfigFS Mount Status ==="
mount | grep configfs

# Check device tree for PCIe endpoint
echo -e "\n=== Device Tree PCIe Info ==="
dtc -I fs /proc/device-tree | grep -A10 -B10 pcie 2>/dev/null || echo "dtc command not available"

# Check PCIe endpoint functions
echo -e "\n=== PCIe Endpoint Functions ==="
if [ -d "/sys/kernel/config/pci_ep/functions" ]; then
  ls -la /sys/kernel/config/pci_ep/functions/
else
  echo "No functions directory found in /sys/kernel/config/pci_ep/"
fi

# Check ODMDATA value
echo -e "\n=== Current ODMDATA Value ==="
if command -v tegra-fuse-tool >/dev/null 2>&1; then
  tegra-fuse-tool --odmdata
else
  echo "tegra-fuse-tool not available, trying alternative methods..."
  
  # Check in extlinux.conf
  if [ -f "/boot/extlinux/extlinux.conf" ]; then
    echo "Checking /boot/extlinux/extlinux.conf:"
    grep -i odmdata /boot/extlinux/extlinux.conf || echo "No ODMDATA in extlinux.conf"
  fi
  
  # Try to read from device tree
  if [ -f "/proc/device-tree/chosen/nvidia,odmdata" ]; then
    echo "ODMDATA from device tree:"
    hexdump -C /proc/device-tree/chosen/nvidia,odmdata
  fi
  
  # Try to use flash.sh to get info
  if [ -f "/opt/nvidia/l4t-packages/version" ]; then
    echo "L4T version information:"
    cat /opt/nvidia/l4t-packages/version
  fi
  
  # Check if this is specifically configured for PCIe endpoint mode
  echo "Checking device tree for PCIe endpoint mode configuration:"
  dtc -I fs /proc/device-tree | grep -i pcie-ep || echo "No PCIe endpoint entries found in device tree"
fi

# Check PCIe driver in dmesg
echo -e "\n=== PCIe Driver Messages ==="
dmesg | grep -i pcie | tail -20

echo -e "\n===== Diagnostic Complete ====="
echo "If you see 'Operation not permitted' when creating directories in configfs,"
echo "this typically indicates one of the following issues:"
echo "1. The kernel was not flashed with the correct ODMDATA value for endpoint mode"
echo "2. The required kernel modules are missing or not loaded"
echo "3. The device tree configuration doesn't enable PCIe endpoint mode"