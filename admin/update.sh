#!/bin/sh

# Error handling
set -e

echo "Checking for WireGuard VPN Setup updates..."

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed. Cannot check for updates."
  exit 1
fi

# Check if we're in a git repository
if [ ! -d .git ]; then
  echo "Error: This does not appear to be a git repository."
  echo "Updates can only be performed if you cloned the repository with git."
  exit 1
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $BRANCH"

# Fetch updates
echo "Fetching updates..."
git fetch origin "$BRANCH"

# Check if we're behind
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
  echo "You are already up to date."
  exit 0
fi

# Show changes
echo
echo "New changes available. Changes:"
git log --oneline HEAD..origin/"$BRANCH"
echo

# Offer to update
echo "Do you want to update to the latest version? [y/N]"
read -r confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Update aborted."
  exit 0
fi

# Check if container is running
CONTAINER_RUNNING=0
if docker ps | grep -q wireguard; then
  CONTAINER_RUNNING=1
  echo "WireGuard container is running. It will be stopped during the update."
  echo "Continue? [y/N]"
  read -r continue_confirm
  if [ "$continue_confirm" != "y" ] && [ "$continue_confirm" != "Y" ]; then
    echo "Update aborted."
    exit 0
  fi
  
  echo "Stopping WireGuard container..."
  ./bin/stop.sh
fi

# Backup before update
echo "Creating backup before update..."
./admin/backup.sh

# Pull updates
echo "Pulling updates..."
git pull origin "$BRANCH"

# Make scripts executable
chmod +x bin/*.sh
chmod +x admin/*.sh

# Restart if it was running
if [ "$CONTAINER_RUNNING" = "1" ]; then
  echo "Restarting WireGuard container..."
  ./bin/start.sh
  echo "WireGuard container restarted."
fi

echo
echo "Update completed successfully!" 