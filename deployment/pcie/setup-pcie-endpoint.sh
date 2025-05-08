#!/bin/bash

# Interactive PCIe Endpoint Configuration Script
# This script helps set up PCIe endpoint mode on Jetson devices

echo "===== PCIe Endpoint Configuration Script ====="
echo "This script will help set up PCIe endpoint mode on your Jetson device"

# Function to check if we're running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script needs to run as root. Please enter your password when prompted."
        sudo "$0" "$@"
        exit $?
    fi
}

# Function to load required kernel modules
load_modules() {
    echo -e "\nLoading required kernel modules..."
    
    # Check if configfs is already mounted
    if ! grep -qs 'configfs' /proc/mounts; then
        echo "Mounting configfs..."
        modprobe configfs
        mount -t configfs none /sys/kernel/config
    fi
    
    # Load PCIe endpoint test module if available
    if find /lib/modules/$(uname -r) -name "pci-epf-test.ko" | grep -q .; then
        echo "Loading pci-epf-test module..."
        modprobe pci-epf-test || echo "Failed to load pci-epf-test module"
    else
        echo "pci-epf-test module not found. Trying alternative modules..."
        # Try to load other possible modules
        modprobe configfs
        modprobe pci_epf_core 2>/dev/null || echo "pci_epf_core not available"
        modprobe pci_endpoint 2>/dev/null || echo "pci_endpoint not available"
        modprobe pci_epf_nv_test 2>/dev/null || echo "pci_epf_nv_test not available"
    fi
}

# Function to find available controllers
find_controller() {
    echo -e "\nLooking for PCIe controllers..."
    
    if [ ! -d "/sys/kernel/config/pci_ep/controllers" ]; then
        echo "No PCIe endpoint controllers directory found. This suggests the kernel wasn't built with PCIe EP support."
        echo "Available directories in /sys/kernel/config:"
        ls -la /sys/kernel/config/
        return 1
    fi
    
    echo "Available PCIe controllers:"
    ls -la /sys/kernel/config/pci_ep/controllers/
    
    # Find the first available controller
    CONTROLLER=$(ls -1 /sys/kernel/config/pci_ep/controllers/ 2>/dev/null | head -1)
    if [ -z "$CONTROLLER" ]; then
        echo "No controllers found. Your device might not be flashed in endpoint mode."
        return 1
    else
        echo "Using controller: $CONTROLLER"
        return 0
    fi
}

# Function to create required directories
setup_endpoint() {
    echo -e "\nCreating PCIe endpoint function directories..."
    
    # Create parent directories first
    mkdir -p /sys/kernel/config/pci_ep/functions/ || { 
        echo "Failed to create functions directory. This might indicate a kernel configuration issue."; 
        return 1; 
    }
    
    # Try different module names
    if [ -d "/sys/kernel/config/pci_ep/functions/pci-epf-test" ] || mkdir -p /sys/kernel/config/pci_ep/functions/pci-epf-test 2>/dev/null; then
        FUNCTION_DIR="pci-epf-test"
    elif [ -d "/sys/kernel/config/pci_ep/functions/pci_epf_nv_test" ] || mkdir -p /sys/kernel/config/pci_ep/functions/pci_epf_nv_test 2>/dev/null; then
        FUNCTION_DIR="pci_epf_nv_test"
    else
        echo "Failed to create function directory. Trying to load available modules..."
        find /lib/modules/$(uname -r) -name "*epf*.ko" -o -name "*pci*ep*.ko" | while read module; do
            echo "Loading $module"
            insmod $module 2>/dev/null
        done
        
        # Try again after loading modules
        if mkdir -p /sys/kernel/config/pci_ep/functions/pci-epf-test 2>/dev/null; then
            FUNCTION_DIR="pci-epf-test"
        else
            echo "Failed to create function directory. Please check your kernel configuration."
            return 1
        fi
    fi
    
    echo "Using function directory: $FUNCTION_DIR"
    
    # Create func1 directory
    if ! mkdir -p /sys/kernel/config/pci_ep/functions/$FUNCTION_DIR/func1 2>/dev/null; then
        echo "Failed to create func1 directory. This may be due to insufficient permissions or incorrect module loading."
        return 1
    fi
    
    # Set vendor and device ID
    echo 0x10de > /sys/kernel/config/pci_ep/functions/$FUNCTION_DIR/func1/vendorid
    echo 0x0001 > /sys/kernel/config/pci_ep/functions/$FUNCTION_DIR/func1/deviceid
    
    return 0
}

# Function to link function to controller
link_and_start() {
    echo -e "\nLinking function to controller and starting endpoint..."
    
    # Link the function to the controller
    ln -sf /sys/kernel/config/pci_ep/functions/$FUNCTION_DIR/func1 /sys/kernel/config/pci_ep/controllers/$CONTROLLER/
    
    # Start the endpoint
    echo 1 > /sys/kernel/config/pci_ep/controllers/$CONTROLLER/start
    
    # Check if the endpoint started successfully
    if [ $? -eq 0 ]; then
        echo "PCIe endpoint started successfully!"
        echo "To verify on the host system, run: lspci -vv"
        echo "You should see a device with vendor ID 0x10de and device ID 0x0001"
        return 0
    else
        echo "Failed to start PCIe endpoint."
        return 1
    fi
}

# Main function
main() {
    check_root
    load_modules
    
    if find_controller; then
        if setup_endpoint; then
            link_and_start
        fi
    fi
    
    # Show diagnostic information
    echo -e "\n===== Diagnostic Information ====="
    echo "PCIe controllers:"
    ls -la /sys/kernel/config/pci_ep/controllers/ 2>/dev/null || echo "No controllers directory"
    
    echo -e "\nPCIe functions:"
    ls -la /sys/kernel/config/pci_ep/functions/ 2>/dev/null || echo "No functions directory"
    
    echo -e "\nLoaded modules:"
    lsmod | grep -E 'pci|ep|configfs'
    
    echo -e "\nPress Enter to exit..."
    read
}

# Run the script
main