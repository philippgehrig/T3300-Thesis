#!/bin/bash

# configureProxy.sh
# Script to configure proxy settings, NTP server and trusted GPG keys on Jetson Orin Nano
# Can be executed via SSH on the target device

# Don't exit immediately on error
set +e

echo "===================================="
echo "Jetson Orin Nano Configuration Tool"
echo "===================================="

# Define default values
# NOTE: Default values for Mercedes environment 
PROXY_HOST="192.168.1.1"
PROXY_PORT="44000"
NTP_SERVER="53.60.5.254"
UBUNTU_HOST=""
COPY_GPG_FILES=false
COPY_PROXY_CONFIG=false
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
        --ubuntu-host)
            UBUNTU_HOST="$2"
            shift 2
            ;;
        --copy-gpg)
            COPY_GPG_FILES=true
            shift
            ;;
        --copy-proxy-conf)
            COPY_PROXY_CONFIG=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --proxy-host HOST     Set proxy hostname or IP (default: 127.0.0.1)"
            echo "  --proxy-port PORT     Set proxy port (default: 3128)"
            echo "  --no-proxy            Disable proxy configuration"
            echo "  --ntp-server HOST     Set NTP server hostname or IP (default: 53.60.5.254)"
            echo "  --ubuntu-host HOST    Set Ubuntu host hostname or IP for file copying"
            echo "  --copy-gpg            Copy trusted GPG files from Ubuntu host"
            echo "  --copy-proxy-conf     Copy 80proxy config from Ubuntu host"
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

echo "[1/5] Configuring proxy settings..."
if [ "$USE_PROXY" = true ]; then
    # Configure proxy settings in /etc/environment
    cat << EOF > /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
ftp_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
no_proxy="localhost,127.0.0.1,::1,.local,rd.corpintra.net,git.swf.daimler.com,swf.cloud.corpintra.net,swf.i.mercedes-benz.com,git.i.mercedes-benz.com,accessdtna.daimler-trucksnorthamerica.com"
EOF

    # Also set the environment variables for the current session
    export http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export ftp_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export no_proxy="localhost,127.0.0.1,::1,.local,rd.corpintra.net,git.swf.daimler.com,swf.cloud.corpintra.net,swf.i.mercedes-benz.com,git.i.mercedes-benz.com,accessdtna.daimler-trucksnorthamerica.com"
    
    echo "Proxy settings configured and applied to current session"
    
    # Create apt proxy configuration
    mkdir -p /etc/apt/apt.conf.d
    
    # Check if apt proxy configuration exists, if so remove it
    if [ -f /etc/apt/apt.conf.d/proxy ]; then
        echo "Removing existing apt proxy configuration..."
        rm -f /etc/apt/apt.conf.d/proxy
    fi

    # Create apt proxy configuration
    cat << EOF > /etc/apt/apt.conf.d/proxy
Acquire::http::Proxy "http://${PROXY_HOST}:${PROXY_PORT}";
Acquire::https::Proxy "http://${PROXY_HOST}:${PROXY_PORT}";
Acquire::ftp::Proxy "http://${PROXY_HOST}:${PROXY_PORT}";
EOF
    echo "Apt proxy configuration created"

    # Configure proxy for wget
    mkdir -p ~/.wget-hsts
    cat << EOF > ~/.wgetrc
use_proxy=yes
http_proxy=http://${PROXY_HOST}:${PROXY_PORT}
https_proxy=http://${PROXY_HOST}:${PROXY_PORT}
ftp_proxy=http://${PROXY_HOST}:${PROXY_PORT}
no_proxy=localhost,127.0.0.1,::1,.local,rd.corpintra.net,git.swf.daimler.com,swf.cloud.corpintra.net,swf.i.mercedes-benz.com,git.i.mercedes-benz.com,accessdtna.daimler-trucksnorthamerica.com
EOF
    echo "Wget proxy configuration created"
    
    # Configure proxy for git
    git config --global http.proxy http://${PROXY_HOST}:${PROXY_PORT}
    git config --global https.proxy http://${PROXY_HOST}:${PROXY_PORT}
    echo "Git proxy configuration created"
    
else
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
        echo "Removed apt proxy configuration"
    fi
    
    # Remove wget proxy configuration if it exists
    if [ -f ~/.wgetrc ]; then
        rm -f ~/.wgetrc
    fi
    
    # Remove git proxy configuration
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    
    echo "Proxy disabled"
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

# Copy configuration files if Ubuntu host is provided
if [ -n "$UBUNTU_HOST" ]; then
    echo "[3/5] Copying configuration files from Ubuntu host..."
    
    # Create temp directory for files
    TMP_DIR=$(mktemp -d)
    
    if [ "$COPY_PROXY_CONFIG" = true ]; then
        echo "Copying proxy configuration from Ubuntu host..."
        scp "ubuntu@${UBUNTU_HOST}:/etc/apt/apt.conf.d/80proxy" "${TMP_DIR}/80proxy"
        if [ -f "${TMP_DIR}/80proxy" ]; then
            cp "${TMP_DIR}/80proxy" /etc/apt/apt.conf.d/
            echo "Proxy configuration copied successfully"
        else
            echo "Failed to copy proxy configuration"
        fi
    fi
    
    if [ "$COPY_GPG_FILES" = true ]; then
        echo "Copying trusted GPG keys from Ubuntu host..."
        mkdir -p "${TMP_DIR}/trusted.gpg.d"
        scp -r "ubuntu@${UBUNTU_HOST}:/etc/apt/trusted.gpg.d/*" "${TMP_DIR}/trusted.gpg.d/"
        
        # Check if files were copied successfully
        if [ "$(ls -A ${TMP_DIR}/trusted.gpg.d)" ]; then
            cp -r "${TMP_DIR}"/trusted.gpg.d/* /etc/apt/trusted.gpg.d/
            echo "Trusted GPG keys copied successfully"
        else
            echo "Failed to copy trusted GPG keys"
        fi
    fi
    
    # Clean up
    rm -rf "$TMP_DIR"
else
    echo "[3/5] Skipping file copying (no Ubuntu host specified)"
fi

echo "[4/5] Checking network connectivity and installing required tools..."

# Check if network interface is up
echo "Available network interfaces:"
ip addr show | grep -E "^[0-9]+" | grep -v "lo:" | cut -d: -f2

# Check if required tools are installed
echo "Installing curl for network testing..."
apt-get update -qq && apt-get install -y curl iputils-ping

# Test basic network connectivity
echo "Testing basic network connectivity..."

# Check DNS resolution
echo "Testing DNS resolution..."
host_cmd=$(host nvidia.com 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✓ DNS resolution working"
else
    echo "✗ DNS resolution failed"
    
    # Try to add a Google DNS server temporarily to test
    echo "Adding Google DNS server temporarily..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf.temp
    cat /etc/resolv.conf >> /etc/resolv.conf.temp
    cp /etc/resolv.conf.temp /etc/resolv.conf
    rm /etc/resolv.conf.temp
    
    echo "Testing DNS resolution with Google DNS..."
    host_cmd=$(host nvidia.com 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✓ DNS resolution working with Google DNS"
    else
        echo "✗ DNS resolution still failing"
    fi
fi

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

echo "[5/5] Testing internet connectivity before installing NVIDIA JetPack..."

# Test servers to check connectivity - tried in order until one succeeds
TEST_SERVERS=("nvidia.com" "google.com" "cloudflare.com" "microsoft.com")
CONNECTIVITY_OK=false

# Function to test internet connectivity using curl
test_connectivity() {
    local test_url="$1"
    echo "Testing connectivity to $test_url..."
    
    # Set a timeout of 5 seconds for the curl request
    if curl -s --connect-timeout 5 --head "https://$test_url" > /dev/null; then
        return 0  # Success
    else
        return 1  # Failed
    fi
}

# Function to test internet connectivity using ping
test_ping() {
    local test_server="$1"
    echo "Trying to ping $test_server..."
    
    # Try 3 pings with a timeout of 2 seconds each
    if ping -c 3 -W 2 "$test_server" > /dev/null 2>&1; then
        return 0  # Success
    else
        return 1  # Failed
    fi
}

# Test Nvidia repositories specifically
test_nvidia_repos() {
    echo "Testing connection to NVIDIA repositories..."
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/nvidia-l4t-apt-source.list" \
                   -o Dir::Etc::sourceparts="-" \
                   -o APT::Get::List-Cleanup="0" \
                   -qq > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 0  # Success
    else
        return 1  # Failed
    fi
}

# Test proxy specific connectivity if using proxy
if [ "$USE_PROXY" = true ]; then
    echo "Testing proxy connectivity specifically..."
    if curl -s --connect-timeout 5 -x "http://${PROXY_HOST}:${PROXY_PORT}" https://www.google.com > /dev/null; then
        echo "✓ Proxy connection successful!"
        CONNECTIVITY_OK=true
    else
        echo "✗ Proxy connection test failed."
        echo "Checking if proxy is reachable..."
        if ping -c 3 -W 2 "${PROXY_HOST}" > /dev/null 2>&1; then
            echo "✓ Proxy host is reachable via ping, but connection through proxy failed."
            echo "This might be due to proxy configuration issues or restrictions."
        else
            echo "✗ Cannot reach proxy host (${PROXY_HOST})."
            echo "Please verify the proxy hostname and port are correct."
        fi
    fi
fi

# If proxy test failed but we're still using proxy, try general connectivity tests
if [ "$CONNECTIVITY_OK" = false ]; then
    # Try each test server
    for server in "${TEST_SERVERS[@]}"; do
        if test_connectivity "$server"; then
            echo "✓ Successfully connected to $server"
            CONNECTIVITY_OK=true
            break
        elif test_ping "$server"; then
            echo "✓ Successfully pinged $server"
            CONNECTIVITY_OK=true
            break
        else
            echo "✗ Failed to connect to $server"
        fi
    done
fi

# If basic connectivity tests failed, try specifically testing NVIDIA repositories
if [ "$CONNECTIVITY_OK" = false ]; then
    if test_nvidia_repos; then
        echo "✓ Successfully connected to NVIDIA repositories"
        CONNECTIVITY_OK=true
    else
        echo "✗ Failed to connect to NVIDIA repositories"
    fi
fi

# If connectivity tests failed
if [ "$CONNECTIVITY_OK" = false ]; then
    echo "Internet connectivity test failed. Please check your network settings and proxy configuration."
    echo "Current network configuration:"
    echo "--------------------------------"
    echo "IP Address Information:"
    ip addr show
    echo "--------------------------------"
    echo "Routing Table:"
    ip route list
    echo "--------------------------------"
    echo "DNS Configuration:"
    cat /etc/resolv.conf
    echo "--------------------------------"
    echo "Network diagnostic complete."
    
    echo "Troubleshooting recommendations:"
    echo "1. Check physical network connection (Ethernet cable)"
    echo "2. Verify proxy settings (current: ${PROXY_HOST}:${PROXY_PORT})"
    echo "   - For Mercedes environment, try using the correct corporate proxy"
    echo "   - Common proxy format might be: proxy.company-domain:port"
    echo "3. Test DNS resolution by running 'host nvidia.com'"
    echo "4. Check firewall rules that might block outgoing connections"
    
    read -p "Do you want to continue with JetPack installation anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation aborted. Please fix network connectivity issues and try again."
        exit 1
    fi
    echo "Continuing with installation despite connectivity issues..."
else
    echo "✓ Internet connectivity test passed. Proceeding with JetPack installation."
fi

# Update apt and install NVIDIA JetPack
apt update
apt install -y nvidia-jetpack

echo "===================================="
echo "Configuration completed successfully"
echo "===================================="
if [ "$USE_PROXY" = true ]; then
    echo "Proxy settings: http://${PROXY_HOST}:${PROXY_PORT}"
else
    echo "Proxy: Disabled"
fi
echo "NTP server: ${NTP_SERVER}"
echo "NVIDIA JetPack installed"
echo ""
echo "To apply all environment settings, you might need to reboot the system."
echo "Run: sudo reboot"

