#!/bin/sh

# Error handling
set -e

# Default backup directory
BACKUP_DIR="backups"
BACKUP_FILE="$BACKUP_DIR/wireguard-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating WireGuard backup..."

# Check if the WireGuard container is running
if docker ps | grep -q wireguard; then
  echo "WireGuard container is running. Including live configurations."
else
  echo "Warning: WireGuard container is not running. Only backing up template files."
fi

# Create tar.gz archive of the configuration
echo "Backing up configuration files, scripts, and systemd service..."
tar -czf "$BACKUP_FILE" docker-compose.yml config/ .systemd/ bin/ admin/ setup.sh README.md

echo "Backup created successfully: $BACKUP_FILE"
echo
echo "To restore this backup, run:"
echo "./admin/restore.sh $BACKUP_FILE"
echo
echo "Note: This backup includes your entire WireGuard VPN setup, including:"
echo "- Container configuration (docker-compose.yml)"
echo "- Peer configurations (config/)"
echo "- Service files (.systemd/)"
echo "- Scripts (bin/, admin/)"
echo "- Setup files (setup.sh, README.md)"