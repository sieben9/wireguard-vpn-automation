#!/bin/sh

# Error handling
set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root"
  echo "Please run with: sudo $0"
  exit 1
fi

# Alpine Linux init script for WireGuard VPN
# To be placed in /etc/init.d/wireguard

SCRIPT_DIR="/opt/wireguard-vpn-setup"
INIT_FILE="/etc/init.d/wireguard"

echo "Creating Alpine Linux init script for WireGuard VPN..."

# Create the init script
cat > "$INIT_FILE" << 'EOL'
#!/sbin/openrc-run

name="WireGuard VPN"
description="WireGuard VPN Docker Container"
command_user="root"
supervisor="supervise-daemon"
command="/opt/wireguard-vpn-setup/bin/start.sh"
pidfile="/run/wireguard.pid"
respawn_delay=5
respawn_max=0

depend() {
    need net
    after docker
}

stop() {
    ebegin "Stopping WireGuard VPN"
    /opt/wireguard-vpn-setup/bin/stop.sh
    eend $?
}

reload() {
    ebegin "Reloading WireGuard VPN"
    /opt/wireguard-vpn-setup/bin/restart.sh
    eend $?
}
EOL

# Make it executable
chmod +x "$INIT_FILE"

echo "Alpine Linux init script created at $INIT_FILE"
echo
echo "To install the service, run:"
echo "sudo rc-update add wireguard default"
echo
echo "To start the service:"
echo "sudo rc-service wireguard start"
echo
echo "To stop the service:"
echo "sudo rc-service wireguard stop"
echo
echo "To check status:"
echo "sudo rc-service wireguard status" 