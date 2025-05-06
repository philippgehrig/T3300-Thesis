#!/bin/bash

# setup-jetson-remote.sh
# Script to configure a Jetson Orin Nano remotely via SSH

# Default values
JETSON_HOST=""
JETSON_USER="nano"
PROXY_HOST="192.168.1.1"
PROXY_PORT="44000"
NTP_SERVER="53.60.5.254"
UBUNTU_HOST=""
COPY_GPG_FILES=false
COPY_PROXY_CONFIG=false
USE_TTY=true
USE_PROXY=true

# Show usage information
function show_usage {
  echo "Usage: $0 --jetson-host HOSTNAME [options]"
  echo "Options:"
  echo "  --jetson-host HOST    Hostname or IP address of the Jetson Orin Nano (required)"
  echo "  --jetson-user USER    Username for SSH login (default: nano)"
  echo "  --proxy-host HOST     Set proxy hostname or IP (default: 127.0.0.1)"
  echo "  --proxy-port PORT     Set proxy port (default: 3128)"
  echo "  --no-proxy            Disable proxy configuration"
  echo "  --ntp-server HOST     Set NTP server hostname or IP (default: 53.60.5.254)"
  echo "  --ubuntu-host HOST    Set Ubuntu host hostname or IP for copying config files"
  echo "  --copy-gpg            Copy trusted GPG files from Ubuntu host"
  echo "  --copy-proxy-conf     Copy 80proxy config from Ubuntu host"
  echo "  --no-tty              Use this if you're running the script non-interactively"
  echo "  --help                Show this help message"
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --jetson-host)
            JETSON_HOST="$2"
            shift 2
            ;;
        --jetson-user)
            JETSON_USER="$2"
            shift 2
            ;;
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
        --no-tty)
            USE_TTY=false
            shift
            ;;
        --help)
            show_usage
            ;;
        *)
            echo "Unknown option: $key"
            show_usage
            ;;
    esac
done

# Check if Jetson hostname is provided
if [ -z "$JETSON_HOST" ]; then
    echo "Error: Jetson hostname or IP address is required"
    show_usage
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "======================================================="
echo "Jetson Orin Nano Remote Configuration Tool"
echo "======================================================="
echo "Jetson Host:      $JETSON_HOST"
echo "Jetson User:      $JETSON_USER"
if [ "$USE_PROXY" = true ]; then
    echo "Proxy:            Enabled (${PROXY_HOST}:${PROXY_PORT})"
    echo "NOTE: Make sure this is the correct proxy for your network!"
else
    echo "Proxy:            Disabled"
fi
echo "NTP Server:       $NTP_SERVER"
if [ -n "$UBUNTU_HOST" ]; then
    echo "Ubuntu Host:     $UBUNTU_HOST"
    if [ "$COPY_GPG_FILES" = true ]; then
        echo "Copy GPG Files:   Yes"
    fi
    if [ "$COPY_PROXY_CONFIG" = true ]; then
        echo "Copy Proxy Conf:  Yes"
    fi
else
    echo "File Copying:    Disabled (no Ubuntu host specified)"
fi
echo "======================================================="
echo

# Build the command arguments
CMD_ARGS=""
if [ "$USE_PROXY" = true ]; then
    CMD_ARGS+=" --proxy-host $PROXY_HOST"
    CMD_ARGS+=" --proxy-port $PROXY_PORT"
else
    CMD_ARGS+=" --no-proxy"
fi

CMD_ARGS+=" --ntp-server $NTP_SERVER"

if [ -n "$UBUNTU_HOST" ]; then
    CMD_ARGS+=" --ubuntu-host $UBUNTU_HOST"
    if [ "$COPY_GPG_FILES" = true ]; then
        CMD_ARGS+=" --copy-gpg"
    fi
    if [ "$COPY_PROXY_CONFIG" = true ]; then
        CMD_ARGS+=" --copy-proxy-conf"
    fi
fi

# Execute remotely
echo "Copying configuration script to Jetson..."
scp "$SCRIPT_DIR/configureProxy.sh" "$JETSON_USER@$JETSON_HOST:/tmp/"

# Create a small wrapper script to handle sudo with password prompt
cat > "$SCRIPT_DIR/sudo_wrapper.sh" << 'EOF'
#!/bin/bash
chmod +x /tmp/configureProxy.sh
if command -v sudo > /dev/null 2>&1; then
  # First, check if the user can sudo without a password
  if sudo -n true 2>/dev/null; then
    sudo /tmp/configureProxy.sh "$@"
  else
    # Need a password, ask for it
    echo "Sudo requires a password. Please enter your password:"
    sudo -S /tmp/configureProxy.sh "$@"
  fi
else
  echo "Error: sudo is not available on this system."
  exit 1
fi
EOF

# Copy the wrapper script
scp "$SCRIPT_DIR/sudo_wrapper.sh" "$JETSON_USER@$JETSON_HOST:/tmp/"
chmod +x "$SCRIPT_DIR/sudo_wrapper.sh"
ssh "$JETSON_USER@$JETSON_HOST" "chmod +x /tmp/sudo_wrapper.sh"

echo "Running configuration script on Jetson..."
echo "This may take a while, especially when installing NVIDIA JetPack..."

if [ "$USE_TTY" = true ]; then
  # Interactive mode with TTY for password prompts
  ssh -t "$JETSON_USER@$JETSON_HOST" "/tmp/sudo_wrapper.sh$CMD_ARGS"
else
  # Non-interactive mode (will still fail if password is needed)
  ssh "$JETSON_USER@$JETSON_HOST" "/tmp/sudo_wrapper.sh$CMD_ARGS"
fi

# Clean up the wrapper script
rm -f "$SCRIPT_DIR/sudo_wrapper.sh"

echo "Configuration completed!"
echo "If a reboot is needed, you can run:"
echo "ssh -t $JETSON_USER@$JETSON_HOST 'sudo reboot'"