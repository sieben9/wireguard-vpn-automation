#!/bin/sh

# Error handling
set -e

# Check if peer name is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <peer_name>"
  echo "Example: $0 phone"
  exit 1
fi

PEER_NAME="$1"
PEER_DIR="config/peer_$PEER_NAME"

# Check if peer directory already exists
if [ -d "$PEER_DIR" ]; then
  echo "Error: Peer '$PEER_NAME' already exists."
  exit 1
fi

# Create peer directory
echo "Creating peer directory for '$PEER_NAME'..."
mkdir -p "$PEER_DIR"

# Create template config file
echo "# Peer configuration template for $PEER_NAME - will be replaced by WireGuard" > "$PEER_DIR/$PEER_NAME.conf.bak"

echo "Peer '$PEER_NAME' added successfully."
echo "The configuration will be generated when the WireGuard container starts."
echo "After starting the container, you can view the peer configuration with:"
echo "cat config/peer_$PEER_NAME/$PEER_NAME.conf"
echo
echo "To generate a QR code for mobile devices:"
echo "cat config/peer_$PEER_NAME/$PEER_NAME.conf | qrencode -t ansiutf8" 