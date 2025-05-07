#!/bin/bash

#installing dependecies
sudo apt-get install libxml2-utils
sudo apt-get install qemu-user-static
sudo apt-get install dialog

# Set base directory
BASE_DIR=$(dirname "$0")

# Determine the root directory based on the device selection
XAVIER_ROOT_DIR="$BASE_DIR/NvidiaXavierRoot"
ORIN_ROOT_DIR="$BASE_DIR/NvidiaOrinRoot"
TMP_DIR="/tmp/NvidiaRoot_$(date +%s)"

# URLs for Jetson Orin files
ROOTFS_URL="https://developer.download.nvidia.com/embedded/L4T/r36_Release_v2.0/release/Tegra_Linux_Sample-Root-Filesystem_R36.2.0_aarch64.tbz2"
L4T_URL="https://developer.download.nvidia.com/embedded/L4T/r36_Release_v2.0/release/Jetson_Linux_R36.2.0_aarch64.tbz2"

# Check if Orin root directory exists
if [ ! -d "$ORIN_ROOT_DIR" ]; then
    echo "$ORIN_ROOT_DIR not found. Creating directory and downloading files..."
    mkdir -p "$ORIN_ROOT_DIR"
    cd "$ORIN_ROOT_DIR" || { echo "Failed to navigate to $ORIN_ROOT_DIR. Exiting."; exit 1; }
    
    echo "Downloading Linux For Tegra..."
    wget -O Jetson_Linux.tbz2 "$L4T_URL"
    echo "Extracting..."
    tar -xvf Jetson_Linux.tbz2
    rm Jetson_Linux.tbz2
    
    echo "Downloading root filesystem..."
    mkdir -p Linux_for_Tegra/rootfs
    wget -O rootfs.tbz2 "$ROOTFS_URL"
    echo "Extracting root filesystem..."
    sudo tar -xvf rootfs.tbz2 -C Linux_for_Tegra/rootfs
    rm rootfs.tbz2
fi

# Prompt for Jetson configuration selection
CHOICE=$(dialog --title "Jetson Flash Selection" --menu "Choose a configuration file:" 15 60 4 \
    "1" "Jetson AGX Orin" \
    "2" "Jetson Orin Nano" \
    "3" "Jetson AGX Xavier" \
    2>&1 >/dev/tty)

# Check if a valid choice was made
if [ -z "$CHOICE" ]; then
    echo "No configuration selected. Stopping program."
    exit 1
fi

# Map the selection to the corresponding configuration file and root directory
case $CHOICE in
    1)
        CONFIG="jetson-agx-orin-devkit"
        L4T_DIR="$ORIN_ROOT_DIR"
        ;;
    2)
        CONFIG="jetson-orin-nano-devkit"
        L4T_DIR="$ORIN_ROOT_DIR"
        ;;
    3)
        CONFIG="jetson-agx-xavier-devkit"
        L4T_DIR="$XAVIER_ROOT_DIR"
        ;;
    *)
        echo "Unknown choice. Stopping program."
        exit 1
        ;;
esac

# Check if root directory exists
if [ ! -d "$L4T_DIR" ]; then
    echo "$L4T_DIR directory not found. Exiting."
    exit 1
fi

# Show info box and wait for confirmation
dialog --msgbox "Copying root directory and applying binaries. This may take a while. Please confirm." 8 50
clear

# Copy selected root directory to a temporary location
sudo cp -a "$L4T_DIR" "$TMP_DIR"
cd "$TMP_DIR/Linux_for_Tegra" || { echo "Failed to navigate to Linux_for_Tegra in temporary directory. Exiting."; exit 1; }

# Display a dialog menu for selecting the PCIe mode
PCIe_CHOICE=$(dialog --title "PCIe Configuration" --menu "Choose PCIe mode:" 10 40 2 \
    "1" "Host" \
    "2" "Endpoint" \
    2>&1 >/dev/tty)

# Check if a valid choice was made
if [ -z "$PCIe_CHOICE" ]; then
    echo "No PCIe configuration selected. Stopping program."
    exit 1
fi

# Define actions based on the PCIe mode selection
case $PCIe_CHOICE in
    1) # Host mode
        PCIe_MODE="Host"
        echo "Configuring $CONFIG for PCIe Host mode..."
        sed -i '/^ODMDATA/d' $CONFIG.conf
        ;;
    2) # Endpoint mode
        PCIe_MODE="Endpoint"
        echo "Configuring $CONFIG for PCIe Endpoint mode..."
        case $CHOICE in
            1) # agx orin
                sed -i '/^ODMDATA/d' $CONFIG.conf
                # Add ODMDATA at the end of the file to ensure it takes precedence
                echo 'ODMDATA="gbe-uphy-config-22,nvhs-uphy-config-1,hsio-uphy-config-0,gbe0-enable-10g,hsstp-lane-map-3"' >> $CONFIG.conf
                ;;
            2) #orin nano
                sed -i '/^ODMDATA/d' $CONFIG.conf
                # Add ODMDATA at the end of the file to ensure it takes precedence
                echo 'ODMDATA="gbe-uphy-config-8,hsstp-lane-map-3,hsio-uphy-config-41"' >> $CONFIG.conf
                ;;
            3) #agx xavier
                sed -i '/^ODMDATA/d' $CONFIG.conf
                # Add ODMDATA at the end of the file to ensure it takes precedence
                echo 'ODMDATA="0x09191000"' >> $CONFIG.conf
                ;;
            *)
                echo "Unknown board for Endpoint mode. Stopping program."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown PCIe choice. Stopping program."
        exit 1
        ;;
esac

# Reapplying binaries
echo "Reapplying binaries"
sudo ./apply_binaries.sh

# Prompt for username, password, and hostname
USERNAME=$(dialog --inputbox "Set username:" 8 40 3>&1 1>&2 2>&3 3>-)
HOSTNAME=$(dialog --inputbox "Set hostname:" 8 40 3>&1 1>&2 2>&3 3>-)
PASSWORD=$(dialog --insecure --passwordbox "Set password:" 8 40 3>&1 1>&2 2>&3 3>-)

# Check if username, password, and hostname were provided
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$HOSTNAME" ]; then
    echo "Username, password, or hostname not provided. Exiting."
    exit 1
fi

# Create default user
sudo ./tools/l4t_create_default_user.sh -u "$USERNAME" -p "$PASSWORD" -n "$HOSTNAME" --accept-license

# Flash the Jetson device
sudo ./flash.sh "$CONFIG" mmcblk0p1

# Check if the flash process was successful
if [ $? -ne 0 ]; then
    echo "Flashing failed."
    exit 1
fi

# Display a success message
dialog --msgbox "Configuration updated for $CONFIG!" 6 50

# Clean up temporary directory
rm -rf "$TMP_DIR"

clear
echo "Configuration complete."
