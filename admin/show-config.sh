#!/bin/sh

# Error handling
set -e

echo "WireGuard Configuration Viewer"
echo "----------------------------"
echo

# Check if container is running
if ! docker ps | grep -q wireguard; then
  echo "Error: WireGuard container is not running."
  echo "Please start the container first with:"
  echo "./bin/start.sh"
  exit 1
fi

# Get server info from docker-compose.yml
SERVER_IP=$(grep -E "SERVERURL" docker-compose.yml | cut -d= -f2 | head -1 | tr -d '[:space:]')
SERVER_PORT=$(grep -E "SERVERPORT" docker-compose.yml | cut -d= -f2 | head -1 | tr -d '[:space:]')
INTERNAL_SUBNET=$(grep -E "INTERNAL_SUBNET" docker-compose.yml | cut -d= -f2 | head -1 | tr -d '[:space:]')

echo "Server Information:"
echo "-------------------"
echo "Server IP:       $SERVER_IP"
echo "Server Port:     $SERVER_PORT"
echo "Internal Subnet: $INTERNAL_SUBNET"
echo

# Show all peers
echo "Available Peers:"
echo "---------------"
# List all peer directories
find config -maxdepth 1 -type d -name "peer_*" | sort | while read -r peer_dir; do
  peer_name=$(basename "$peer_dir")
  echo "- $peer_name"
done
echo

# Ask which peer config to show
echo "Enter peer name to view configuration (e.g. peer_1), or press Enter to list all:"
read -r selected_peer

if [ -z "$selected_peer" ]; then
  # List all peers
  find config -maxdepth 1 -type d -name "peer_*" | sort | while read -r peer_dir; do
    peer_name=$(basename "$peer_dir")
    echo
    echo "===== Configuration for $peer_name ====="
    
    # Find the actual config file (not .bak)
    conf_file=$(find "$peer_dir" -maxdepth 1 -name "*.conf" -not -name "*.bak" | head -1)
    
    if [ -f "$conf_file" ]; then
      cat "$conf_file"
      echo
      echo "To generate QR code for this peer:"
      echo "cat $conf_file | qrencode -t ansiutf8"
    else
      echo "No configuration file found. Has the container been started?"
    fi
  done
else
  # Show specific peer
  if [ -d "config/$selected_peer" ]; then
    echo
    echo "===== Configuration for $selected_peer ====="
    
    # Find the actual config file (not .bak)
    conf_file=$(find "config/$selected_peer" -maxdepth 1 -name "*.conf" -not -name "*.bak" | head -1)
    
    if [ -f "$conf_file" ]; then
      cat "$conf_file"
      echo
      echo "To generate QR code for this peer:"
      echo "cat $conf_file | qrencode -t ansiutf8"
      
      # Ask if user wants to see QR code
      echo
      echo "Generate QR code now? [y/N]"
      read -r gen_qr
      if [ "$gen_qr" = "y" ] || [ "$gen_qr" = "Y" ]; then
        if command -v qrencode >/dev/null 2>&1; then
          cat "$conf_file" | qrencode -t ansiutf8
        else
          echo "Error: qrencode not installed. Install with:"
          echo "  Debian/Ubuntu: apt-get install qrencode"
          echo "  Alpine: apk add qrencode"
          echo "  macOS: brew install qrencode"
        fi
      fi
    else
      echo "No configuration file found. Has the container been started?"
    fi
  else
    echo "Error: Peer $selected_peer not found."
    exit 1
  fi
fi 