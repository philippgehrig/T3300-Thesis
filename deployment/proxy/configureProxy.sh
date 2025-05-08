#!/bin/bash

# configureProxy.sh
# Script to configure proxy settings, NTP server and trusted GPG keys on Jetson Orin Nano
# Can be executed via SSH on the target device

# Enable debugging to see what's happening
set -x

# Don't exit immediately on error
set +e

echo "===================================="
echo "Jetson Orin Nano Configuration Tool"
echo "===================================="

# Define default values
# NOTE: Default values for Mercedes environment 
PROXY_HOST="192.168.1.1"
PROXY_PORT="3123"
NTP_SERVER="53.60.5.254"
USE_LOCAL_CONFIG=true
USE_PROXY=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --proxy-host)
            PROXY_HOST="$2"
            shift 2
            ;;
        --proxy-port)
            PROXY_PORT="$2"
            shift 2
            ;;
        --no-proxy)
            USE_PROXY=false
            shift
            ;;
        --ntp-server)
            NTP_SERVER="$2"
            shift 2
            ;;
        --no-local-config)
            USE_LOCAL_CONFIG=false
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --proxy-host HOST     Set proxy hostname or IP (default: 192.168.1.1)"
            echo "  --proxy-port PORT     Set proxy port (default: 44000)"
            echo "  --no-proxy            Disable proxy configuration"
            echo "  --ntp-server HOST     Set NTP server hostname or IP (default: 53.60.5.254)"
            echo "  --no-local-config     Don't use local proxy configuration files"
            echo "  --help                Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done

# Check if running with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "Script directory: ${SCRIPT_DIR}"

# The proxy config directory is now the same as the script directory
PROXY_CONFIG_DIR="${SCRIPT_DIR}"

# If we're running from /tmp, the files might have been copied there
if [[ "$SCRIPT_DIR" == "/tmp" && -d "/tmp" ]]; then
    PROXY_CONFIG_DIR="/tmp"
fi

echo "Proxy configuration directory: ${PROXY_CONFIG_DIR}"
echo "Listing proxy configuration directory contents:"
ls -la ${PROXY_CONFIG_DIR}

# Function to test proxy connectivity
test_proxy() {
    local proxy_host="$1"
    local proxy_port="$2"
    
    echo "Testing proxy connectivity to ${proxy_host}:${proxy_port}..."
    
    # First try ping (fast check)
    if ! ping -c 2 -W 3 "${proxy_host}" > /dev/null 2>&1; then
        echo "✗ Cannot ping proxy host (${proxy_host})"
        return 1
    fi
    
    # Try a simple HTTP request through the proxy to test connectivity
    local test_url="http://www.google.com"
    local timeout=5
    
    # Use curl with the proxy to test connectivity
    if ! curl --connect-timeout $timeout -x "http://${proxy_host}:${proxy_port}" -s -o /dev/null -w "%{http_code}" $test_url > /dev/null 2>&1; then
        echo "✗ Cannot connect through proxy ${proxy_host}:${proxy_port}"
        return 1
    fi
    
    echo "✓ Proxy connection successful"
    return 0
}

# Function to configure and apply proxy settings
configure_proxy() {
    echo "Starting proxy configuration..."
    
    # Configure proxy settings in /etc/environment
    cat << EOF > /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
ftp_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
no_proxy="localhost,127.0.0.1,::1"
EOF
    echo "Created /etc/environment with the following content:"
    cat /etc/environment

    # Also set the environment variables for the current session
    export http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export ftp_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export no_proxy="localhost,127.0.0.1,::1"
    echo "Exported environment variables:"
    env | grep -E 'http_proxy|https_proxy|ftp_proxy|no_proxy'
    
    # Ensure apt.conf.d directory exists
    mkdir -p /etc/apt/apt.conf.d
    echo "Current contents of /etc/apt/apt.conf.d:"
    ls -la /etc/apt/apt.conf.d/
    
    # Critical fix: Check if there's a file that appears as '~' in the directory listing
    # This can happen if there's a file with spaces or special characters
    if ls -la /etc/apt/apt.conf.d/ | grep -q "\\~"; then
        echo "Found problematic file in apt.conf.d directory, cleaning up..."
        cd /etc/apt/apt.conf.d/
        find . -name "*~*" -exec rm -f {} \;
        find . -name "* *" -exec rm -f {} \;
    fi
    
    # Remove old proxy configs if they exist to avoid conflicts
    echo "Removing any existing proxy configurations..."
    rm -f /etc/apt/apt.conf.d/proxy
    rm -f /etc/apt/apt.conf.d/80proxy
    
    # Simply copy the 80proxy file from the repository without modifications
    if [ "$USE_LOCAL_CONFIG" = true ] && [ -f "${PROXY_CONFIG_DIR}/80proxy" ]; then
        echo "Copying 80proxy configuration from repository..."
        
        # Copy with explicit permissions
        cp -f "${PROXY_CONFIG_DIR}/80proxy" /etc/apt/apt.conf.d/80proxy
        chmod 755 /etc/apt/apt.conf.d/80proxy
        
        # Verify the file was copied correctly
        if [ -f /etc/apt/apt.conf.d/80proxy ]; then
            echo "✓ 80proxy file copied to /etc/apt/apt.conf.d/ successfully"
            echo "Contents of 80proxy file:"
            cat /etc/apt/apt.conf.d/80proxy
            ls -la /etc/apt/apt.conf.d/80proxy
        else
            echo "✗ Failed to copy 80proxy file"
            echo "Please check if the 80proxy file exists in the repository"
        fi
    else
        echo "No 80proxy file found in the repository"
        echo "Please make sure the 80proxy file is available in the proxy directory"
    fi
    
    # Apply proxy environment variables
    echo "Applying proxy environment variables..."
    source /etc/environment
}

# Function to remove proxy settings
remove_proxy() {
    # Ensure proxy settings are removed from /etc/environment
    if grep -q "http_proxy" /etc/environment; then
        sed -i '/http_proxy/d; /https_proxy/d; /ftp_proxy/d; /no_proxy/d' /etc/environment
        echo "Removed proxy settings from /etc/environment"
    fi
    
    # Unset any proxy environment variables that may be set
    unset http_proxy https_proxy ftp_proxy no_proxy
    
    # Remove apt proxy configuration if it exists
    if [ -f /etc/apt/apt.conf.d/proxy ]; then
        rm -f /etc/apt/apt.conf.d/proxy
        echo "Removed proxy configuration"
    fi
    
    if [ -f /etc/apt/apt.conf.d/80proxy ]; then
        rm -f /etc/apt/apt.conf.d/80proxy
        echo "Removed 80proxy configuration"
    fi
    
    echo "Proxy disabled"
}

echo "[1/5] Configuring proxy settings..."
if [ "$USE_PROXY" = true ]; then
    echo "Configuring system to use proxy ${PROXY_HOST}:${PROXY_PORT}..."
    
    # Configure the proxy
    configure_proxy
    
    # Test if proxy works
    if ! test_proxy "$PROXY_HOST" "$PROXY_PORT"; then
        echo "WARNING: Proxy configuration failed, but continuing anyway as requested."
        echo "This might cause package installation to fail."
    else
        echo "Proxy settings configured and applied to current session"
    fi
else
    remove_proxy
    echo "Proxy disabled as requested"
fi

echo "[2/5] Configuring NTP time server..."
# Configure NTP time server
cat << EOF > /etc/systemd/timesyncd.conf
[Time]
NTP=${NTP_SERVER}
EOF

# Restart the time synchronization service
systemctl restart systemd-timesyncd
echo "Time server configured and service restarted"
echo "Current time status:"
timedatectl status

echo "[3/5] Configuring trusted GPG keys..."
if [ "$USE_LOCAL_CONFIG" = true ] && [ -d "${PROXY_CONFIG_DIR}/trusted.gpg.d" ] && [ "$(ls -A ${PROXY_CONFIG_DIR}/trusted.gpg.d 2>/dev/null)" ]; then
    echo "Copying trusted GPG keys from repository..."
    mkdir -p /etc/apt/trusted.gpg.d/
    cp -r "${PROXY_CONFIG_DIR}/trusted.gpg.d/"* /etc/apt/trusted.gpg.d/ 2>/dev/null
    echo "Trusted GPG keys configured"
else
    echo "No trusted GPG keys found in repository, skipping configuration"
fi

echo "[4/5] Checking network connectivity..."
# Test basic network connectivity
echo "Testing basic network connectivity..."

# Test if network adapter is connected
echo "Checking network connection status..."
if ip link | grep -q "state UP"; then
    echo "✓ Network interface is UP"
else
    echo "✗ No network interface is UP"
    echo "Trying to bring up ethernet interface..."
    # Try to bring up the main ethernet interface
    eth_interfaces=$(ip -o link show | grep -i ethernet | awk -F': ' '{print $2}')
    for eth in $eth_interfaces; do
        echo "Attempting to bring up $eth..."
        ip link set $eth up
        sleep 2
    done
    
    # Check again
    if ip link | grep -q "state UP"; then
        echo "✓ Successfully brought up network interface"
    else
        echo "✗ Failed to bring up network interface"
    fi
fi

# Test proxy connectivity if using proxy
if [ "$USE_PROXY" = true ]; then
    echo "Testing proxy connectivity..."
    if ping -c 3 -W 2 "${PROXY_HOST}" > /dev/null 2>&1; then
        echo "✓ Proxy host is reachable"
    else
        echo "✗ Cannot reach proxy host (${PROXY_HOST})"
        echo "Please verify the proxy hostname is correct"
    fi
fi

echo "[5/5] Installing NVIDIA JetPack..."
# Install JetPack without fallback mechanisms
echo "Updating package lists..."
if ! apt update; then
    echo "Warning: apt update failed. This might be due to network issues."
fi

echo "Checking if NVIDIA repositories are properly configured..."
if ! grep -q "nvidia" /etc/apt/sources.list.d/*.list 2>/dev/null; then
    echo "NVIDIA repositories might not be properly configured."
    echo "Adding NVIDIA repositories manually..."
    
    # Create NVIDIA repository configuration
    cat > /etc/apt/sources.list.d/nvidia-l4t-apt-source.list << EOF
deb https://repo.download.nvidia.com/jetson/common r36.2 main
deb https://repo.download.nvidia.com/jetson/t234 r36.2 main
EOF
    
    # Try to update again
    if ! apt update; then
        echo "Warning: apt update still failed after adding NVIDIA repositories."
    fi
fi

echo "Installing NVIDIA JetPack..."
if apt install -y nvidia-jetpack; then
    echo "✓ JetPack installation successful!"
else
    echo "✗ JetPack installation failed."
    echo "Please check your network connection, proxy settings, and NVIDIA repositories."
fi

echo "===================================="
echo "Configuration completed"
echo "===================================="
if [ "$USE_PROXY" = true ]; then
    echo "Proxy settings: http://${PROXY_HOST}:${PROXY_PORT}"
else
    echo "Proxy: Disabled"
fi
echo "NTP server: ${NTP_SERVER}"
echo ""
echo "To apply all environment settings, you might need to reboot the system."
echo "Run: sudo reboot"

