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

# Check if peer directory exists
if [ ! -d "$PEER_DIR" ]; then
  echo "Error: Peer '$PEER_NAME' does not exist."
  exit 1
fi

# Confirm deletion
echo "Are you sure you want to remove peer '$PEER_NAME'? [y/N]"
read -r confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Remove peer directory
echo "Removing peer '$PEER_NAME'..."
rm -rf "$PEER_DIR"

echo "Peer '$PEER_NAME' removed successfully."
echo "The changes will take effect after restarting the WireGuard container."
echo
echo "To restart the container, run:"
echo "./bin/restart.sh" 