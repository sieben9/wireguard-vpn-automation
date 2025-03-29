#!/bin/sh

# Error handling
set -e

# Check if backup file is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup_file>"
  echo "Example: $0 backups/wireguard-backup-20220101-120000.tar.gz"
  exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Confirm restoration
echo "Warning: This will overwrite your current configuration."
echo "Are you sure you want to restore from $BACKUP_FILE? [y/N]"
read -r confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Stop WireGuard container if running
if docker ps | grep -q wireguard; then
  echo "Stopping WireGuard container..."
  ./bin/stop.sh
  WIREGUARD_WAS_RUNNING=1
else
  WIREGUARD_WAS_RUNNING=0
fi

# Create a temporary directory for extraction
TEMP_DIR="$(mktemp -d)"

# Extract the backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Copy files back
echo "Restoring files..."

# Check if various components exist in the backup
if [ -f "$TEMP_DIR/docker-compose.yml" ]; then
  cp -f "$TEMP_DIR/docker-compose.yml" .
  echo "✓ Restored docker-compose.yml"
fi

if [ -d "$TEMP_DIR/config" ]; then
  cp -rf "$TEMP_DIR/config" .
  echo "✓ Restored peer configurations"
fi

if [ -d "$TEMP_DIR/.systemd" ]; then
  cp -rf "$TEMP_DIR/.systemd" .
  echo "✓ Restored systemd service files"
fi

if [ -d "$TEMP_DIR/bin" ]; then
  cp -rf "$TEMP_DIR/bin" .
  chmod +x bin/*.sh
  echo "✓ Restored bin scripts"
fi

if [ -d "$TEMP_DIR/admin" ]; then
  cp -rf "$TEMP_DIR/admin" .
  chmod +x admin/*.sh
  echo "✓ Restored admin scripts"
fi

if [ -f "$TEMP_DIR/setup.sh" ]; then
  cp -f "$TEMP_DIR/setup.sh" .
  chmod +x setup.sh
  echo "✓ Restored setup.sh"
fi

if [ -f "$TEMP_DIR/README.md" ]; then
  cp -f "$TEMP_DIR/README.md" .
  echo "✓ Restored README.md"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "Backup restored successfully."

# Restart WireGuard if it was running
if [ "$WIREGUARD_WAS_RUNNING" = "1" ]; then
  echo "Restarting WireGuard container..."
  ./bin/start.sh
  echo "WireGuard container restarted."
else
  echo "WireGuard container was not running. You can start it with:"
  echo "./bin/start.sh"
fi 